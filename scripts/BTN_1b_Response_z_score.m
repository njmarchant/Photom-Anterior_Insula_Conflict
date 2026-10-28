%% BTN_1b: Re-z-score every lever-press response against its OWN trial's baseline
% ------------------------------------------------------------------------
% Problem: press-aligned traces (traces_z_25_15) are z-scored on -25 to -20 s
% relative to the PRESS. Relative to the trial, that window moves with press
% latency L (it sits at L-15 to L-10 s relative to cue onset), so it lands in
% the ITI, on the cue-onset transient, or inside the cue period.
%
% Fix: sesdat.lp_dFF holds the whole session, so no re-extraction is needed.
% For each response (code 5 = pellet press, code 6 = shock press):
%   1. find the trial (cue onset) it came from: cue_ts = press_ts - cue_dur - latency
%   2. take the baseline at -10 to -5 s relative to THAT cue onset (the same
%      window and the same ceil()/std(N-1) arithmetic used for the cue-aligned
%      traces_z_10_45)
%   3. z-score a press-aligned window (default -50 to +15 s) with that baseline
%
% Validated in Python on Conflict_02_20240328_Ses_C01_Rat_R09.mat:
%   - the cue-baseline arithmetic reproduces traces_z_10_45 to ~1e-15
%   - the press-aligned slices reproduce traces_updated_25_15 to ~1e-16
%   - all 25 responses match exactly one trial via press_ts - 10 - latency
%
% OUTPUT (added to sesdat; nothing existing is modified):
%   sesdat.traces_z_resp       n x (4+N). Same layout as traces_z_25_15:
%                              [press_ts, code(5/6), latency, trial_type, z-trace]
%   sesdat.traces_resp_time    1 x N time axis in s relative to the press
%   sesdat.traces_resp_meta    n x 8 diagnostics, rows aligned with traces_z_resp
%   sesdat.traces_resp_meta_cols  column names for traces_resp_meta
%% 1. Configuration
clear all
filePath = 'C:\Photometry\Conflict_04\Raw data\Pun_(10-45)';

save_in_place = false;   % true: add fields to the existing .mat files (back them up first)
                        % false: write copies to out_folder
out_folder    = fullfile(filePath, 'with_resp_traces');

pre_win   = 50;         % s before press to keep (30 max latency + 10 cue + 10 to baseline start)
post_win  = 15;         % s after press
cue_dur   = 10;         % cue period length (s)
max_lat   = 30;         % maximum response latency (s); only used to estimate the previous trial's end
base_pre  = 10;         % baseline starts this many s before cue onset
base_len  = 5;          % baseline length (s)  -> -10 to -5 s
resp_codes = [5 6];     % 5 = pellet press, 6 = shock press
match_tol = 0.05;       % s; tolerance when matching a press to its trial's cue onset

if ~save_in_place && ~isfolder(out_folder); mkdir(out_folder); end

%% 2. Loop over sessions
files = dir(fullfile(filePath, '*.mat'));
files = files(~contains({files.name}, 'TIMING'));

summary_rows = {};
for f = 1:length(files)
    fname = files(f).name;
    S = load(fullfile(filePath, fname), 'sesdat');
    sesdat = S.sesdat;

    % --- required fields ---
    if ~isfield(sesdat, 'lp_dFF') || ~isfield(sesdat, 'conversion')
        fprintf('SKIP %s: no lp_dFF/conversion\n', fname); continue;
    end
    % if isfield(sesdat, 'traces_z_25_15')
    if isfield(sesdat, 'traces_z')
        % T = sesdat.traces_z_25_15;          % [ts, code, latency, trial_type/outcome, trace...]
        T = sesdat.traces_z;          % [ts, code, latency, trial_type/outcome, trace...]
    elseif isfield(sesdat, 'traces_updated_25_15')
        T = sesdat.traces_updated_25_15;
    else
        fprintf('SKIP %s: no traces_z_25_15 / traces_updated_25_15 table\n', fname); continue;
    end

    fs = sesdat.conversion;
    x  = sesdat.lp_dFF(:)';
    nx = length(x);

    % Sample counts, using the same ceil() convention as the extraction script
    n_pre   = ceil(pre_win  * fs);
    n_post  = ceil(post_win * fs);
    n_bpre  = ceil(base_pre * fs);
    n_blen  = ceil(base_len * fs);
    N       = n_pre + n_post + 1;

    % Trial (cue) rows: codes 1-3, sorted by time. Col 3 = latency (0 = omission).
    trials = T(ismember(T(:,2), [1 2 3]), 1:4);
    trials = sortrows(trials, 1);
    trial_end = trials(:,1) + cue_dur + ...
        (trials(:,3) .* (trials(:,3) > 0) + max_lat .* (trials(:,3) <= 0));

    % Response rows
    resp = T(ismember(T(:,2), resp_codes), 1:4);
    nr = size(resp, 1);

    Z    = NaN(nr, 4 + N);
    Z(:, 1:4) = resp;
    meta = NaN(nr, 8);
    n_ok = 0;

    for k = 1:nr
        press_ts = resp(k,1);
        code     = resp(k,2);
        lat      = resp(k,3);
        ttype    = resp(k,4);

        % 1) find the trial this press came from
        expected_cue = press_ts - cue_dur - lat;
        [dmin, ti] = min(abs(trials(:,1) - expected_cue));
        if isempty(dmin) || dmin > match_tol
            fprintf('  %s: press @ %.2f s has no matching cue onset (nearest %.3f s away), skipped\n', ...
                fname, press_ts, dmin);
            continue;
        end
        cue_ts = trials(ti, 1);          % use the actual cue timestamp, as the extraction did

        % 2) baseline: -base_pre to -(base_pre-base_len) s relative to this cue onset
        adj_cue = ceil(fs * cue_ts);
        b_start = adj_cue - n_bpre;
        b_end   = b_start + n_blen - 1;
        if b_start < 1 || b_end > nx
            continue;                    % baseline falls outside the recording
        end
        base = x(b_start:b_end);
        mu = mean(base, 'omitnan');
        sd = std(base, 0, 'omitnan');    % N-1, same as the cue-aligned z-score
        if ~isfinite(sd) || sd == 0
            continue;
        end

        % 3) press-aligned window, NaN-padded if it runs past the recording
        adj_press = ceil(fs * press_ts);
        i0 = adj_press - n_pre;
        i1 = adj_press + n_post;
        seg = NaN(1, N);
        s0 = max(i0, 1);  s1 = min(i1, nx);
        seg((s0 - i0 + 1):(s1 - i0 + 1)) = x(s0:s1);

        Z(k, 5:end) = (seg - mu) / sd;
        n_ok = n_ok + 1;

        % diagnostics
        if ti > 1
            prev_iti = cue_ts - trial_end(ti-1);   % ITI preceding this trial (est.)
        else
            prev_iti = NaN;
        end
        meta(k,:) = [cue_ts, press_ts, lat, ttype, code, mu, sd, prev_iti];
    end

    % --- write results ---
    sesdat.traces_z_resp      = Z;
    sesdat.traces_resp_time   = (-n_pre:n_post) / fs;
    sesdat.traces_resp_meta   = meta;
    sesdat.traces_resp_meta_cols = {'cue_ts','press_ts','latency','trial_type','code', ...
                                    'base_mean_dFF','base_sd_dFF','prev_ITI_est'};

    if save_in_place
        save(fullfile(filePath, fname), 'sesdat');
    else
        save(fullfile(out_folder, fname), 'sesdat');
    end

    fprintf('%s: %d/%d responses re-z-scored\n', fname, n_ok, nr);
    summary_rows(end+1,:) = {fname, nr, n_ok}; %#ok<SAGROW>
end

fprintf('\nDone. %d files processed.\n', size(summary_rows,1));