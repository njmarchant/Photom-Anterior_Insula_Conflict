%% BTN_3_1_EventAligned_RAWchannels.m
% Generalised version of the raw-channel diagnostic.
% The alignment event is now configurable via condDefs, so you can align on
% anything coded in column 2 of traces_updated_* without editing the body.
%
% Column 2 codes (from BTN_2_1_changesRes_zScoretraces_Conflict.m):
%   1 = rewDS trial start        4 = lever press
%   2 = punDS trial start        5 = food outcome  (i.e. rewarded press)
%   3 = conflict trial start     6 = shock outcome
%
% For outcome rows (2 = 5 or 6) the other columns mean:
%   col 3 = latency from cue availability
%   col 4 = trial type the outcome belonged to (1 rewDS, 2 punDS, 3 conflict)
%
% For trial-start rows (2 = 1,2,3):
%   col 3 = latency, col 4 = 1 responded / 0 omitted
%
% DEFAULT here: aligned on food outcome (code 5), split by originating trial
% type, with a shuffled-timestamp control.
%
% Nothing is baselined and nothing is z-scored.

clear all
close all

%% 1. Configuration
tankfolder      = 'C:\Photometry\Conflict_06\Raw data\Pun';
filePath        = fullfile(tankfolder);

% Leave either EMPTY ({}) to accept everything on that criterion.
Rat             = {};    % e.g. {'R01','R02',...}
reward_sessions = {};    % e.g. {'R01','R02','R03','R04','R05'}

verbose_filter  = true;

trace_field     = 'traces_updated_25_15';
pre             = 25;
post            = 15;

do_shuffle      = true;
n_shuffle       = 50;
rng(1);

n_overview      = 0;     % whole-session overview figures (0 = skip)
do_heatmap      = true;  % single-trial heatmap for the first condition

% Colours
c_food   = [0.12, 0.80, 0.01];
c_press  = [0.00, 0.35, 0.80];
c_conf   = [0.01, 0.11, 0.86];
c_shuf   = [0.55, 0.55, 0.55];

% --- ALIGNMENT EVENTS -------------------------------------------------
% {name, selector function of the traces_updated matrix, colour, linestyle}
% The selector returns a logical index over rows. 'Shuffled' is special-cased.
condDefs = { ...
    'Food (all)',      @(tr) tr(:,2) == 5,                 c_food,  '-'; ...
    % 'Food on rewDS',   @(tr) tr(:,2) == 5 & tr(:,4) == 1,  c_conf,  '-'; ...
    % 'Lever press',     @(tr) tr(:,2) == 4,                 c_press, '-'; ...
    'Shuffled',        [],                                 c_shuf,  '--'};

align_label = 'food outcome (rewarded press)';
% ----------------------------------------------------------------------

nGrid    = 401;
t_common = linspace(-pre, post, nGrid);

sigNames  = {'raw490','raw405','pct490','pct405','dff'};
condNames = matlab.lang.makeValidName(condDefs(:,1));
nCond     = size(condDefs, 1);

%% 2. Containers
Data = struct();
Diag = table();
Heat = struct('pct490', [], 'dff', []);   % pooled single trials, condition 1
n_overview_drawn = 0;

%% 3. Loop over session files
fprintf('Loading raw channels, aligned on %s...\n', align_label);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]);
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:numel(files)

    [~, ~, ext] = fileparts(files(i).name);
    if ~strcmpi(ext, '.mat'), continue; end

    S = load(fullfile(filePath, files(i).name), 'sesdat');
    if ~isfield(S, 'sesdat'), continue; end
    sesdat = S.sesdat;
    clear S

    % --- identify rat and session from the fields BTN_1 writes ---
    if isfield(sesdat, 'rat'), rat = char(string(sesdat.rat)); else, rat = ''; end
    if isfield(sesdat, 'ses'), session = char(string(sesdat.ses)); else, session = ''; end

    ok_rat = isempty(Rat)             || ismember(rat, Rat);
    ok_ses = isempty(reward_sessions) || any(strcmp(session, reward_sessions));

    if verbose_filter
        if ok_rat && ok_ses, verdict = 'INCLUDED'; else, verdict = 'excluded'; end
        fprintf('  %-45s rat=%-6s ses=%-6s %s\n', files(i).name, rat, session, verdict);
    end
    if ~(ok_rat && ok_ses), clear sesdat; continue; end

    needed = {'filt490','filt405','conversion', trace_field};
    missing = needed(~isfield(sesdat, needed));
    if ~isempty(missing)
        fprintf('    SKIP - missing: %s\n', strjoin(missing, ', '));
        clear sesdat; continue
    end

    ratField = matlab.lang.makeValidName(rat);
    if ~isfield(Data, ratField)
        for c = 1:nCond
            for s = 1:numel(sigNames)
                Data.(ratField).(condNames{c}).(sigNames{s}) = [];
            end
        end
    end

    % --- signals ---
    conv = sesdat.conversion;
    s490 = double(sesdat.filt490(:));
    s405 = double(sesdat.filt405(:));
    if isfield(sesdat, 'lp_dFF')
        sdff = double(sesdat.lp_dFF(:));
    else
        sdff = nan(size(s490));
    end

    L = min([numel(s490), numel(s405), numel(sdff)]);
    s490 = s490(1:L); s405 = s405(1:L); sdff = sdff(1:L);

    m490 = median(s490, 'omitnan');
    m405 = median(s405, 'omitnan');
    p490 = 100 * (s490 - m490) / m490;
    p405 = 100 * (s405 - m405) / m405;

    % NB: {} wrapping, otherwise struct() builds a struct ARRAY
    sigs = struct('raw490', {s490}, 'raw405', {s405}, ...
                  'pct490', {p490}, 'pct405', {p405}, 'dff', {sdff});

    % --- event timestamps per condition ---
    tr = sesdat.(trace_field);
    nHere = zeros(1, nCond);

    for c = 1:nCond
        if isempty(condDefs{c,2})          % shuffled control
            if ~do_shuffle, continue; end
            t_lo = pre + 1;
            t_hi = (L / conv) - post - 1;
            ts = t_lo + (t_hi - t_lo) * rand(n_shuffle, 1);
        else
            sel = condDefs{c,2}(tr);
            ts  = tr(sel, 1);
        end
        nHere(c) = numel(ts);

        for s = 1:numel(sigNames)
            [m, n, E] = epoch_mean(sigs.(sigNames{s}), ts, conv, pre, post, t_common);
            if n > 0
                Data.(ratField).(condNames{c}).(sigNames{s}) = ...
                    [Data.(ratField).(condNames{c}).(sigNames{s}); m];
            end
            if do_heatmap && c == 1 && n > 0
                if strcmp(sigNames{s}, 'pct490'), Heat.pct490 = [Heat.pct490; E]; end
                if strcmp(sigNames{s}, 'dff'),    Heat.dff    = [Heat.dff;    E]; end
            end
        end
    end

    % --- diagnostics ---
    t_sec    = (0:L-1)' / conv;
    p_bleach = polyfit(t_sec, s490, 1);
    bleach_pct_min = 100 * p_bleach(1) * 60 / m490;
    p_iso    = polyfit(s405, s490, 1);
    r_iso    = nan_corr(s405, s490);

    row = table(string(files(i).name), string(rat), string(session), conv, ...
                L/conv/60, bleach_pct_min, p_iso(1), r_iso, p_iso(1) < 0, ...
                'VariableNames', {'File','Rat','Session','Fs_Hz','Dur_min', ...
                'Bleach_pctPerMin','IsoSlope','IsoCorr','ControlfitFallback'});
    for c = 1:nCond
        row.(['n_' condNames{c}]) = nHere(c);
    end
    Diag = [Diag; row];  %#ok<AGROW>

    % --- optional session overview ---
    if n_overview_drawn < n_overview
        n_overview_drawn = n_overview_drawn + 1;
        ts_main = tr(condDefs{1,2}(tr), 1);
        figure('Name', sprintf('Session overview: %s %s', rat, session), ...
               'Color','w','Position',[80 80 1100 620]);
        ax1 = subplot(3,1,1);
        plot(t_sec, s490, 'Color', [0 0.5 0]); hold on; ylabel('490 (V)');
        title(sprintf('%s  %s', rat, session), 'Interpreter','none');
        mark_events(ts_main, c_food);
        ax2 = subplot(3,1,2);
        plot(t_sec, s405, 'Color', [0.5 0 0.5]); hold on; ylabel('405 (V)');
        mark_events(ts_main, c_food);
        ax3 = subplot(3,1,3);
        plot(t_sec, sdff, 'Color', [0.2 0.2 0.2]); hold on;
        ylabel('lp\_dFF (%)'); xlabel('Time in session (s)');
        mark_events(ts_main, c_food);
        linkaxes([ax1 ax2 ax3], 'x'); xlim([0 t_sec(end)]);
    end

    clear sesdat
end

%% 4. Subject means
if isempty(Diag)
    error(['No sessions loaded. Check the rat/session values printed above ' ...
           'against the Rat and reward_sessions lists.']);
end

fprintf('\nAveraging within subjects (%d sessions, %d rats)...\n', ...
        height(Diag), numel(unique(Diag.Rat)));

Group = struct();
for c = 1:nCond
    for s = 1:numel(sigNames)
        Group.(condNames{c}).(sigNames{s}) = [];
    end
end

foundRats = fieldnames(Data);
for r = 1:numel(foundRats)
    for c = 1:nCond
        for s = 1:numel(sigNames)
            M = Data.(foundRats{r}).(condNames{c}).(sigNames{s});
            if ~isempty(M)
                Group.(condNames{c}).(sigNames{s}) = ...
                    [Group.(condNames{c}).(sigNames{s}); mean(M, 1, 'omitnan')];
            end
        end
    end
end

%% 5. Group PETHs
figure('Name', ['Aligned on ' align_label], 'Color','w', ...
       'Position',[100 100 1250 780]);

panel_defs = { ...
    'dff',    'lp\_dFF, no per-trial baseline', 1; ...
    'pct490', '490 nm (% of session median)',   2; ...
    'pct405', '405 nm isosbestic (% of median)', 3; ...
    'raw490', '490 nm raw (V)',                  4};

for p = 1:size(panel_defs,1)
    sig = panel_defs{p,1};
    subplot(2,2,panel_defs{p,3}); hold on
    for c = nCond:-1:1              % shuffled drawn first, sits behind
        plot_mean_sem(t_common, Group.(condNames{c}).(sig), ...
                      condDefs{c,3}, condDefs{c,1}, condDefs{c,4});
    end
    xline(0, 'k--', 'HandleVisibility','off');
    xlabel(sprintf('Time from %s (s)', align_label));
    ylabel(panel_defs{p,2});
    title(panel_defs{p,2});
    xlim([-pre post]); box off
    if p == 1, legend('Location','best','Box','off'); end
end
sgtitle(sprintf('Aligned on %s - no dF/F baseline, no z-score', align_label));

%% 6. Single-trial heatmap (condition 1)
if do_heatmap && ~isempty(Heat.dff)
    figure('Name','Single-trial heatmaps','Color','w','Position',[120 120 1000 520]);

    subplot(1,2,1);
    imagesc(t_common, 1:size(Heat.dff,1), Heat.dff);
    set(gca,'YDir','normal'); colorbar
    clim_sym(Heat.dff);
    hold on; xline(0,'k--','LineWidth',1);
    xlabel('Time (s)'); ylabel('Trial (pooled across sessions)');
    title(sprintf('lp\\_dFF, all %s trials (n=%d)', condDefs{1,1}, size(Heat.dff,1)));

    subplot(1,2,2);
    imagesc(t_common, 1:size(Heat.pct490,1), Heat.pct490);
    set(gca,'YDir','normal'); colorbar
    clim_sym(Heat.pct490);
    hold on; xline(0,'k--','LineWidth',1);
    xlabel('Time (s)'); ylabel('Trial');
    title('490 nm (% of session median)');
    sgtitle('Single trials - look for whether the group mean reflects most trials or a few');
end

%% 7. Console diagnostics
fprintf('\n===== Per-session diagnostics =====\n');
disp(Diag);

for c = 1:nCond
    fprintf('%-16s total events: %d\n', condDefs{c,1}, sum(Diag.(['n_' condNames{c}])));
end

if any(Diag.ControlfitFallback)
    fprintf(['\nWARNING: %d session(s) had a NEGATIVE 405->490 regression slope, so\n' ...
             'controlfit.m fell back to a = 1. Isosbestic correction is a constant\n' ...
             'offset in those sessions and 405 drift passes into dF/F.\n'], ...
             sum(Diag.ControlfitFallback));
end

fprintf('\nMedian bleaching: %.3f %% of session median per minute\n', ...
        median(Diag.Bleach_pctPerMin, 'omitnan'));
fprintf('Median 405-490 correlation: %.3f\n', median(Diag.IsoCorr, 'omitnan'));
fprintf('\nDone.\n');

%% ---------------- local functions ----------------

function [m, n, E] = epoch_mean(sig, ts, conv, pre, post, t_common)
% Peri-event epochs using the same index arithmetic as BTN_1, averaged and
% resampled onto t_common. E returns the individual trials, also on t_common.
    m = nan(size(t_common));
    n = 0;
    E = [];
    if isempty(ts), return; end

    nPre  = ceil(pre  * conv);
    nPost = ceil(post * conv);
    t_local = (-nPre:nPost) / conv;

    raw  = nan(numel(ts), nPre + nPost + 1);
    keep = false(numel(ts), 1);
    for k = 1:numel(ts)
        c = ceil(conv * ts(k));
        a = c - nPre;
        b = c + nPost;
        if a >= 1 && b <= numel(sig)
            raw(k,:) = sig(a:b)';
            keep(k)  = true;
        end
    end
    raw = raw(keep,:);
    n = size(raw,1);
    if n == 0, return; end

    E = nan(n, numel(t_common));
    for k = 1:n
        E(k,:) = interp1(t_local, raw(k,:), t_common, 'linear', NaN);
    end
    m = mean(E, 1, 'omitnan');
end

function plot_mean_sem(t, M, colour, name, style)
    if isempty(M), return; end
    mu = mean(M, 1, 'omitnan');
    n  = sum(~isnan(M), 1);
    se = std(M, 0, 1, 'omitnan') ./ sqrt(max(n,1));
    ok = ~isnan(mu);
    fill([t(ok), fliplr(t(ok))], [mu(ok)+se(ok), fliplr(mu(ok)-se(ok))], ...
         colour, 'FaceAlpha', 0.15, 'EdgeColor','none', 'HandleVisibility','off');
    plot(t, mu, style, 'Color', colour, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('%s (n=%d)', name, size(M,1)));
end

function clim_sym(M)
% Symmetric colour limits at the 1st/99th percentile, base MATLAB only.
    v = sort(M(~isnan(M)));
    if isempty(v), return; end
    lim = max(abs(v([max(1,round(0.01*numel(v))), round(0.99*numel(v))])));
    if lim > 0, caxis([-lim lim]); end
end

function r = nan_corr(x, y)
    ok = ~isnan(x) & ~isnan(y);
    if nnz(ok) < 3, r = NaN; return; end
    C = corrcoef(x(ok), y(ok));
    r = C(1,2);
end

function mark_events(ts, colour)
    for k = 1:numel(ts)
        xline(ts(k), 'Color', colour, 'Alpha', 0.35, 'HandleVisibility','off');
    end
end