%% ITI_MAD_transients_v4.m
%  Spontaneous calcium event statistics during inter-trial intervals,
%  split by GLM-HMM latent state.
%
%  CHANGES FROM v3.1
%   - The threshold-free metrics (SD, skewness, kurtosis, band power,
%     autocorrelation tau) are now computed on BOTH the 490 signal and the
%     405 isosbestic control, per ITI. This is the decisive control for the
%     State 3 result: if 405 tau shortens in State 3 the same way 490 tau
%     does, the effect is optical/SNR, not calcium.
%   - New SNR_proxy column: SD(490) / SD(405) per epoch. A direct per-epoch
%     estimate of signal-to-noise, testable across states in its own right.
%   - Metric names carry an explicit _490 / _405 suffix (v3 columns
%     'SD_dFF', 'Skewness', etc. are now 'SD_490', 'Skew_490', ...).
%   - New section 5b prints 490 and 405 side by side with a verdict line per
%     metric, so the control does not have to be read out of a big table.
%
%  Requires: Signal Processing Toolbox (findpeaks) only.
%  ---------------------------------------------------------------------------

clear all; clc; rng(1);

%% --- 1. Configuration ---------------------------------------------------

path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';
path_out   = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\ITI_Analysis_v4';

NOMINAL_TRIAL_DUR    = 30;
POST_OUTCOME_EXCL    = 10;
MIN_ITI_DUR          = 3;
MAX_ITI_DUR          = 120;

MAD_K                = [2 2.5 3];
MIN_PEAK_DIST        = 0.5;
DETECT_MODES         = {'level','deriv'};
BASELINE_MODES       = {'session','rolling'};
ROLL_WIN             = 100;
COINCIDENCE_WIN      = 0.5;

DETREND_WIN          = 90;
LOWPASS_HZ           = 3;

BAND_LO              = 0.1;
BAND_HI              = 1.0;
BANDPOW_MIN_DUR      = 10;
MAX_TAU_LAG          = 5;

MIN_EPOCHS_PER_CELL  = 50;

STATE_FIELD          = 'Inferred_State';
STATES_OF_INTEREST   = [1 2 3];
STATE_PAIRS          = [1 2; 1 3; 2 3];
REQUIRE_SAME_FLANK   = true;
MIN_RUN_LENGTH       = 1;

PRIMARY_DET          = 'deriv';
PRIMARY_BASE         = 'session';
PRIMARY_K            = 2.5;
N_SHUFFLE            = 200;

EST_ROWS             = 300000;
N_COLS               = 35;

if ~exist(path_out,'dir'); mkdir(path_out); end
diary(fullfile(path_out,'ITI_analysis_v4_log.txt')); diary on;

%% --- 2. Load and pre-index state assignments ----------------------------

fprintf('Loading state assignments...\n');
T = readtable(path_excel);
if ~ismember(STATE_FIELD, T.Properties.VariableNames)
    error('Column "%s" not in CSV.', STATE_FIELD);
end

keys_all = strcat(string(T.Rat), '_', string(T.Session));
sv_all   = T.(STATE_FIELD);
if iscell(sv_all); sv_all = cell2mat(sv_all); end
tr_all   = T.Trial;

StateMap = containers.Map('KeyType','char','ValueType','any');
uk = unique(keys_all);
for u = 1:numel(uk)
    idx = keys_all == uk(u);
    StateMap(char(uk(u))) = [tr_all(idx), sv_all(idx)];
end
clear keys_all sv_all tr_all idx uk T
fprintf('Indexed %d rat/session combinations.\n', StateMap.Count);

%% --- 3. Session loop ----------------------------------------------------

files = dir(fullfile(path_data,'*.mat'));
nFiles = numel(files);
fprintf('Found %d session files.\n\n', nFiles);

rows  = cell(EST_ROWS, N_COLS);
row_i = 0;
qc    = cell(nFiles, 10);
qc_i  = 0;

t_all = tic;

for i = 1:nFiles

    t_file = tic;
    fname = files(i).name;

    try
        S = load(fullfile(path_data,fname),'sesdat'); sesdat = S.sesdat; clear S;
    catch
        fprintf('  [skip] load failed: %s\n', fname); continue;
    end

    rat = sesdat.rat; ses = sesdat.ses; fs = sesdat.conversion;
    sig490 = sesdat.lp_dFF(:);
    nsamp = numel(sig490); t_end = (nsamp-1)/fs;

    has405 = isfield(sesdat,'filt405') && numel(sesdat.filt405)==nsamp;
    if has405
        sig405 = local_pseudo_dff(sesdat.filt405(:), fs, DETREND_WIN, LOWPASS_HZ);
    else
        sig405 = nan(nsamp,1);
    end

    has_tonic = has405 && isfield(sesdat,'filt490') && numel(sesdat.filt490)==nsamp;
    if has_tonic
        ratio = sesdat.filt490(:) ./ sesdat.filt405(:);
        tonic = (ratio - mean(ratio,'omitnan')) ./ std(ratio,'omitnan');
        clear ratio;
    else
        tonic = nan(nsamp,1);
    end

    if isfield(sesdat,'traces_updated_25_15'); E = sesdat.traces_updated_25_15;
    elseif isfield(sesdat,'traces_updated_10_45'); E = sesdat.traces_updated_10_45;
    else; fprintf('  [skip] no events: %s\n', fname); continue; end

    Etr = E(ismember(E(:,2),[1 2 3]), 1:4);
    [~,ord] = sort(Etr(:,1)); Etr = Etr(ord,:);
    nTrials = size(Etr,1);
    t_start = Etr(:,1); cue = Etr(:,2);
    latency = Etr(:,3); responded = Etr(:,4) >= 1;

    t_outcome = t_start + NOMINAL_TRIAL_DUR;
    t_outcome(responded) = t_start(responded) + latency(responded);
    clear E Etr ord;

    mkey = [rat '_' ses];
    if ~isKey(StateMap, mkey)
        fprintf('  [skip] no CSV rows: %s %s\n', rat, ses); continue;
    end
    TS = StateMap(mkey);
    state_vec = nan(nTrials,1);
    valid = TS(:,1) >= 1 & TS(:,1) <= nTrials;
    state_vec(TS(valid,1)) = TS(valid,2);
    runlen = local_runlengths(state_vec);

    % ---- Signals and threshold parameters
    CH = struct();
    CH(1).sig = { sig490, local_deriv(sig490, fs) };
    CH(2).sig = { sig405, local_deriv(sig405, fs) };

    for c = 1:2
        for dm = 1:numel(DETECT_MODES)
            s = CH(c).sig{dm};
            med = median(s,'omitnan');
            CH(c).mad(dm) = 1.4826*median(abs(s-med),'omitnan');
            for bm = 1:numel(BASELINE_MODES)
                if strcmp(BASELINE_MODES{bm},'session')
                    CH(c).base{dm,bm}  = med;
                    CH(c).scale{dm,bm} = CH(c).mad(dm);
                else
                    w = round(ROLL_WIN*fs);
                    b = movmedian(s, w, 'omitnan','Endpoints','shrink');
                    CH(c).base{dm,bm}  = b;
                    CH(c).scale{dm,bm} = 1.4826*movmedian(abs(s-b), w, ...
                                                'omitnan','Endpoints','shrink');
                    clear b;
                end
            end
        end
    end

    % ---- ITI walk
    n_used = 0;
    mind = max(1, round(MIN_PEAK_DIST*fs));
    coinc = round(COINCIDENCE_WIN*fs);

    for k = 1:(nTrials-1)

        sA = state_vec(k); sB = state_vec(k+1);
        if isnan(sA); continue; end
        if REQUIRE_SAME_FLANK && (isnan(sB) || sB ~= sA); continue; end
        if ~ismember(sA, STATES_OF_INTEREST); continue; end
        if runlen(k) < MIN_RUN_LENGTH; continue; end

        w0 = t_outcome(k) + POST_OUTCOME_EXCL;
        w1 = t_start(k+1);
        dur = w1 - w0;
        if dur < MIN_ITI_DUR || dur > MAX_ITI_DUR; continue; end
        if w0 < 0 || w1 > t_end; continue; end

        i0 = max(1, round(w0*fs)+1); i1 = min(nsamp, round(w1*fs)+1);
        seglen = i1 - i0 + 1;
        if seglen < round(MIN_ITI_DUR*fs); continue; end
        n_used = n_used + 1;

        % ---- Threshold-free metrics on BOTH channels
        M490 = local_free_metrics(sig490(i0:i1), fs, BAND_LO, BAND_HI, ...
                                  BANDPOW_MIN_DUR, MAX_TAU_LAG, dur);
        if has405
            M405 = local_free_metrics(sig405(i0:i1), fs, BAND_LO, BAND_HI, ...
                                      BANDPOW_MIN_DUR, MAX_TAU_LAG, dur);
        else
            M405 = struct('sd',NaN,'skew',NaN,'kurt',NaN,'bandpow',NaN,'tau',NaN);
        end

        if ~isnan(M405.sd) && M405.sd > 0
            snr_proxy = M490.sd / M405.sd;
        else
            snr_proxy = NaN;
        end

        tonic_med = median(tonic(i0:i1),'omitnan');
        frac_sess = t_start(k)/t_end;

        % Segments and local baselines, once per (channel, detect mode)
        segs = cell(2, numel(DETECT_MODES));
        lbase = cell(2, numel(DETECT_MODES));
        mw = min(seglen, mind*4);
        for c = 1:2
            for dm = 1:numel(DETECT_MODES)
                segs{c,dm}  = CH(c).sig{dm}(i0:i1);
                lbase{c,dm} = movmedian(segs{c,dm}, mw, 'Endpoints','shrink');
            end
        end

        for dm = 1:numel(DETECT_MODES)
            for bm = 1:numel(BASELINE_MODES)

                b1 = local_slice(CH(1).base{dm,bm},  i0, i1);
                c1 = local_slice(CH(1).scale{dm,bm}, i0, i1);
                b2 = local_slice(CH(2).base{dm,bm},  i0, i1);
                c2 = local_slice(CH(2).scale{dm,bm}, i0, i1);

                for kk = 1:numel(MAD_K)

                    thr1 = b1 + MAD_K(kk)*c1;
                    [a490, l490] = local_detect(segs{1,dm}, thr1, lbase{1,dm}, mind);

                    if has405
                        thr2 = b2 + MAD_K(kk)*c2;
                        [~, l405] = local_detect(segs{2,dm}, thr2, lbase{2,dm}, mind);
                    else
                        l405 = [];
                    end

                    if ~isempty(l490) && ~isempty(l405)
                        bad = false(size(l490));
                        for e = 1:numel(l490)
                            bad(e) = any(abs(l405 - l490(e)) <= coinc);
                        end
                        l_clean = l490(~bad); a_clean = a490(~bad);
                    else
                        l_clean = l490; a_clean = a490;
                    end

                    n490 = numel(l490); n405 = numel(l405); nCl = numel(l_clean);
                    permin = dur/60;

                    if nCl > 0
                        ampCl = mean(a_clean);
                        ampClMAD = ampCl / CH(1).mad(dm);
                    else
                        ampCl = NaN; ampClMAD = NaN;
                    end
                    if nCl > 1
                        iei = diff(l_clean)/fs;
                        medIEI = median(iei); cvIEI = std(iei)/mean(iei);
                    else
                        medIEI = NaN; cvIEI = NaN;
                    end

                    row_i = row_i + 1;
                    if row_i > size(rows,1)
                        rows = [rows; cell(100000, N_COLS)]; %#ok<AGROW>
                        fprintf('    (grew output buffer to %d rows)\n', size(rows,1));
                    end

                    rows(row_i,:) = { rat, ses, sesdat.phase, k, sA, ...
                        DETECT_MODES{dm}, BASELINE_MODES{bm}, MAD_K(kk), ...
                        dur, n490, n405, nCl, ...
                        n490/permin, n405/permin, nCl/permin, ...
                        (n490-nCl)/max(n490,1), ...
                        ampCl, ampClMAD, medIEI, cvIEI, ...
                        M490.sd, M490.skew, M490.kurt, M490.bandpow, M490.tau, ...
                        M405.sd, M405.skew, M405.kurt, M405.bandpow, M405.tau, ...
                        snr_proxy, tonic_med, cue(k), double(responded(k)), frac_sess };
                end
            end
        end
    end

    qc_i = qc_i + 1;
    qc(qc_i,:) = { rat, ses, nTrials, sum(~isnan(state_vec)), n_used, ...
        sum(state_vec==1), sum(state_vec==2), sum(state_vec==3), ...
        double(has405), double(has_tonic) };

    el = toc(t_file);
    eta = (toc(t_all)/i) * (nFiles - i) / 60;
    fprintf('  [%3d/%3d] %s %s: %3d trials, %3d assigned, %3d ITIs  (%.2fs, ETA %.1f min)\n', ...
        i, nFiles, rat, ses, nTrials, sum(~isnan(state_vec)), n_used, el, eta);

    clear CH sig490 sig405 tonic segs lbase sesdat TS state_vec runlen ...
          t_start t_outcome cue latency responded;
end

rows = rows(1:row_i,:);
qc   = qc(1:qc_i,:);
fprintf('\nExtraction finished in %.1f min.\n', toc(t_all)/60);

%% --- 4. Tables ----------------------------------------------------------

varnames = {'Rat','Session','Phase','Trial','State','DetectMode','BaselineMode', ...
    'K','ITI_dur','N_490','N_405','N_clean','Rate_490','Rate_405','Rate_clean', ...
    'Frac_rejected','Amp_clean','Amp_clean_MAD','Median_IEI','CV_IEI', ...
    'SD_490','Skew_490','Kurt_490','BandPower_490','Tau_490', ...
    'SD_405','Skew_405','Kurt_405','BandPower_405','Tau_405', ...
    'SNR_proxy','Tonic_ratio','Cue','Responded','Frac_session'};

ITI = cell2table(rows,'VariableNames',varnames);
clear rows;
writetable(ITI, fullfile(path_out,'ITI_transients_v4_long.csv'));

QC = cell2table(qc,'VariableNames',{'Rat','Session','N_trials','N_assigned', ...
    'N_ITIs','N_S1','N_S2','N_S3','Has405','HasTonic'});
writetable(QC, fullfile(path_out,'ITI_QC_v4.csv'));

fprintf('\n=== TOTALS ===\nRows: %d | Rats: %d | Sessions: %d\n', ...
    height(ITI), numel(unique(ITI.Rat)), height(QC));

prim = strcmp(ITI.DetectMode,PRIMARY_DET) & strcmp(ITI.BaselineMode,PRIMARY_BASE) & ITI.K==PRIMARY_K;
P = ITI(prim,:);
for s = STATES_OF_INTEREST
    m = P.State==s;
    fprintf('State %d: %5d ITIs, %6.1f min, mean ITI %.1f s, rejected by 405: %.1f%%\n', ...
        s, sum(m), sum(P.ITI_dur(m))/60, mean(P.ITI_dur(m)), ...
        100*mean(P.Frac_rejected(m),'omitnan'));
end

%% --- 5. Statistics ------------------------------------------------------

metrics = {'Rate_clean','Rate_490','Amp_clean','Amp_clean_MAD','CV_IEI', ...
           'SD_490','Skew_490','Kurt_490','BandPower_490','Tau_490', ...
           'SD_405','Skew_405','Kurt_405','BandPower_405','Tau_405', ...
           'SNR_proxy','Tonic_ratio'};

results = cell(numel(DETECT_MODES)*numel(BASELINE_MODES)*numel(MAD_K)* ...
               size(STATE_PAIRS,1)*numel(metrics), 15);
res_i = 0;

for dm = DETECT_MODES
    for bm = BASELINE_MODES
        for kk = MAD_K
            sel = strcmp(ITI.DetectMode,dm{1}) & strcmp(ITI.BaselineMode,bm{1}) & ITI.K==kk;
            sub = ITI(sel,:);
            if isempty(sub); continue; end

            G = local_cellmeans(sub, metrics, STATES_OF_INTEREST, MIN_EPOCHS_PER_CELL);

            for pr = 1:size(STATE_PAIRS,1)
                iA = find(STATES_OF_INTEREST==STATE_PAIRS(pr,1));
                iB = find(STATES_OF_INTEREST==STATE_PAIRS(pr,2));
                for m = 1:numel(metrics)
                    a = G(:,m,iA); b = G(:,m,iB);
                    ok = ~isnan(a) & ~isnan(b);
                    if sum(ok) < 3; continue; end
                    d = a(ok)-b(ok);
                    [t,p_t] = local_ttest_paired(a(ok), b(ok));
                    p_perm  = local_signflip(d, 10000);
                    res_i = res_i + 1;
                    results(res_i,:) = { dm{1}, bm{1}, kk, ...
                        sprintf('S%d_vs_S%d',STATE_PAIRS(pr,1),STATE_PAIRS(pr,2)), ...
                        metrics{m}, sum(ok), mean(a(ok)), mean(b(ok)), mean(d), ...
                        t, p_t, p_perm, mean(d)/std(d), local_mde(sum(ok),0.05,0.80), ...
                        sum(d>0) };
                end
            end
        end
    end
end
results = results(1:res_i,:);

R = cell2table(results,'VariableNames',{'DetectMode','BaselineMode','K','Pair', ...
    'Metric','N_rats','Mean_A','Mean_B','Diff','t','p_ttest','p_perm','dz', ...
    'MDE_dz_80pct','N_A_higher'});
writetable(R, fullfile(path_out,'ITI_statistics_v4.csv'));

fprintf('\n=== PRIMARY: %s detection, %s threshold, k=%.1f ===\n', ...
    PRIMARY_DET, PRIMARY_BASE, PRIMARY_K);
sel = strcmp(R.DetectMode,PRIMARY_DET) & strcmp(R.BaselineMode,PRIMARY_BASE) & R.K==PRIMARY_K;
disp(R(sel, {'Pair','Metric','N_rats','Diff','p_perm','dz','MDE_dz_80pct','N_A_higher'}));

%% --- 5b. THE CONTROL: 490 vs 405 side by side ---------------------------

fprintf('\n');
fprintf('==========================================================\n');
fprintf('  CONTROL: threshold-free metrics, 490 signal vs 405 ctrl\n');
fprintf('  If the 405 column shows the same effect as 490, the\n');
fprintf('  result is optical/SNR, not calcium.\n');
fprintf('==========================================================\n');

pairs_lbl = {'S1_vs_S2','S1_vs_S3','S2_vs_S3'};
base_metrics = {'SD','Skew','Kurt','BandPower','Tau'};

selR = strcmp(R.DetectMode,PRIMARY_DET) & strcmp(R.BaselineMode,PRIMARY_BASE) & R.K==PRIMARY_K;
Rp = R(selR,:);

for pr = 1:numel(pairs_lbl)
    fprintf('\n--- %s ---\n', pairs_lbl{pr});
    fprintf('  %-12s | %-28s | %-28s | verdict\n', 'metric', '490 (signal)', '405 (control)');
    for m = 1:numel(base_metrics)
        r9 = Rp(strcmp(Rp.Pair,pairs_lbl{pr}) & strcmp(Rp.Metric,[base_metrics{m} '_490']),:);
        r4 = Rp(strcmp(Rp.Pair,pairs_lbl{pr}) & strcmp(Rp.Metric,[base_metrics{m} '_405']),:);
        if isempty(r9) || isempty(r4); continue; end

        s9 = sprintf('d=%+7.4f p=%.4f dz=%+5.2f', r9.Diff, r9.p_perm, r9.dz);
        s4 = sprintf('d=%+7.4f p=%.4f dz=%+5.2f', r4.Diff, r4.p_perm, r4.dz);

        if r9.p_perm < 0.05 && r4.p_perm >= 0.05
            verdict = 'SPECIFIC to 490';
        elseif r9.p_perm < 0.05 && r4.p_perm < 0.05 && sign(r9.dz)==sign(r4.dz)
            verdict = '** MIRRORED in 405 - artefact **';
        elseif r9.p_perm < 0.05 && r4.p_perm < 0.05
            verdict = 'both sig, opposite sign';
        else
            verdict = 'ns in 490';
        end
        fprintf('  %-12s | %-28s | %-28s | %s\n', base_metrics{m}, s9, s4, verdict);
    end
    r = Rp(strcmp(Rp.Pair,pairs_lbl{pr}) & strcmp(Rp.Metric,'SNR_proxy'),:);
    if ~isempty(r)
        fprintf('  %-12s | d=%+7.4f p=%.4f dz=%+5.2f (SD490/SD405)\n', ...
            'SNR_proxy', r.Diff, r.p_perm, r.dz);
    end
end

%% --- 6. Bleaching control -----------------------------------------------

fprintf('\n=== BLEACHING CONTROL (epoch level, %s/%s/k=%.1f) ===\n', ...
    PRIMARY_DET, PRIMARY_BASE, PRIMARY_K);

rats_u = unique(P.Rat);
for m = 1:numel(metrics)
    b2 = nan(numel(rats_u),1); b3 = b2;
    for r = 1:numel(rats_u)
        rr = P(strcmp(P.Rat,rats_u{r}),:);
        y = rr.(metrics{m}); keep = ~isnan(y);
        if sum(keep) < 30 || numel(unique(rr.State(keep))) < 2; continue; end
        X = [ones(sum(keep),1), double(rr.State(keep)==2), ...
             double(rr.State(keep)==3), rr.Frac_session(keep)];
        if rank(X) < size(X,2); continue; end
        bb = X \ y(keep);
        b2(r) = bb(2); b3(r) = bb(3);
    end
    ok2 = ~isnan(b2); ok3 = ~isnan(b3);
    s2 = ''; s3 = '';
    if sum(ok2) >= 3
        [~,p2] = local_ttest_paired(b2(ok2), zeros(sum(ok2),1));
        s2 = sprintf('S2-S1 %+8.4f (n=%2d, p=%.3f)', mean(b2(ok2)), sum(ok2), p2);
    end
    if sum(ok3) >= 3
        [~,p3] = local_ttest_paired(b3(ok3), zeros(sum(ok3),1));
        s3 = sprintf('  S3-S1 %+8.4f (n=%2d, p=%.3f)', mean(b3(ok3)), sum(ok3), p3);
    end
    fprintf('  %-14s %s%s\n', metrics{m}, s2, s3);
end

%% --- 7. Figure: 490 on top, 405 control beneath -------------------------

fig_metrics_490 = {'Rate_clean','SD_490','Skew_490','Kurt_490','BandPower_490','Tau_490'};
fig_metrics_405 = {'Rate_405','SD_405','Skew_405','Kurt_405','BandPower_405','Tau_405'};
fig_lbl = {'Rate (ev/min)','SD','Skewness','Excess kurtosis', ...
           'Rel. power 0.1-1 Hz','Tau (s)'};
cols = [0.69 0.70 0.00; 0.71 0.00 0.70; 0.00 0.69 0.70];

G9 = local_cellmeans(P, fig_metrics_490, STATES_OF_INTEREST, MIN_EPOCHS_PER_CELL);
G4 = local_cellmeans(P, fig_metrics_405, STATES_OF_INTEREST, MIN_EPOCHS_PER_CELL);

figure('Color','w','Position',[40 40 1500 700]);
for m = 1:6
    for ch = 1:2
        subplot(2,6,(ch-1)*6+m); hold on;
        if ch==1; G = G9; else; G = G4; end
        for r = 1:size(G,1)
            y = squeeze(G(r,m,:));
            if sum(~isnan(y)) >= 2
                plot(1:3, y, '-', 'Color',[.75 .75 .75], 'LineWidth',0.5);
            end
        end
        for s = 1:3
            y = G(:,m,s); y = y(~isnan(y));
            if isempty(y); continue; end
            plot(s, mean(y), 'o','MarkerSize',7,'MarkerFaceColor',cols(s,:), ...
                'MarkerEdgeColor','k','LineWidth',1);
            plot([s s], mean(y)+[-1 1]*std(y)/sqrt(numel(y)), '-k','LineWidth',1.2);
        end
        xlim([0.6 3.4]); set(gca,'XTick',1:3,'XTickLabel',{'S1','S2','S3'});
        box off;
        if m==1
            if ch==1; ylabel({'490 signal', fig_lbl{m}}); else; ylabel({'405 control', fig_lbl{m}}); end
        else
            ylabel(fig_lbl{m});
        end
        if ch==1; title(fig_lbl{m},'FontWeight','normal','FontSize',9); end
    end
end
sgtitle(sprintf('ITI statistics by state: 490 signal (top) vs 405 control (bottom) [%s/%s/k=%.1f]', ...
    PRIMARY_DET, PRIMARY_BASE, PRIMARY_K));
saveas(gcf, fullfile(path_out,'ITI_state_490_vs_405_v4.png'));
saveas(gcf, fullfile(path_out,'ITI_state_490_vs_405_v4.svg'));

fprintf('\nDone. Outputs in %s\n', path_out);
diary off;


%% =========================================================================
%  Helpers  (unchanged from v3.1)
%  =========================================================================

function d = local_deriv(sig, fs)
    d = [0; diff(sig)] * fs;
end

function v = local_slice(x, i0, i1)
    if isscalar(x); v = x; else; v = x(i0:i1); end
end

function [amp, loc] = local_detect(seg, thr_seg, local_base, mind)
    amp = []; loc = [];
    if all(isnan(seg)) || ~any(seg > thr_seg); return; end
    prom_floor = max(median(thr_seg - local_base,'omitnan'), eps);
    [pks, loc] = findpeaks(seg, 'MinPeakDistance', mind, ...
                                'MinPeakProminence', prom_floor);
    if isempty(loc); return; end
    if isscalar(thr_seg); keep = pks > thr_seg; else; keep = pks > thr_seg(loc); end
    loc = loc(keep);
    amp = pks(keep) - local_base(loc);
end

function pdff = local_pseudo_dff(raw, fs, detrend_win_s, lowpass_hz)
    w  = round(detrend_win_s*fs);
    f0 = movmean(raw, w, 'omitnan','Endpoints','shrink');
    pdff = (raw - f0) ./ f0;
    if ~isempty(lowpass_hz) && lowpass_hz > 0 && lowpass_hz < fs/2
        wl = max(1, round(fs/lowpass_hz));
        pdff = movmean(pdff, wl, 'Endpoints','shrink');
    end
end

function M = local_free_metrics(seg, fs, blo, bhi, min_dur, max_lag_s, dur)
    seg = seg(~isnan(seg));
    n = numel(seg);
    M = struct('sd',NaN,'skew',NaN,'kurt',NaN,'bandpow',NaN,'tau',NaN);
    if n < 10; return; end

    mu = mean(seg); sd = std(seg);
    M.sd = sd;
    if sd > 0
        M.skew = mean((seg-mu).^3) / sd^3;
        M.kurt = mean((seg-mu).^4) / sd^4 - 3;
    end

    x = seg - mu;

    if dur >= min_dur
        xd = detrend(seg);
        X = abs(fft(xd)).^2;
        f = (0:n-1)' * (fs/n);
        half = 2:floor(n/2);
        band = f(half) >= blo & f(half) <= bhi;
        tot = sum(X(half));
        if tot > 0; M.bandpow = sum(X(half(band))) / tot; end
    end

    maxlag = min(round(max_lag_s*fs), n-2);
    if maxlag > 2
        nfft = 2^nextpow2(2*n);
        F = fft(x, nfft);
        ac = real(ifft(F .* conj(F)));
        if ac(1) > 0
            ac = ac(1:maxlag+1) / ac(1);
            below = find(ac < exp(-1), 1);
            if ~isempty(below) && below > 1
                y1 = ac(below-1); y2 = ac(below);
                frac = (y1 - exp(-1)) / max(y1-y2, eps);
                M.tau = ((below-2) + frac) / fs;
            end
        end
    end
end

function rl = local_runlengths(v)
    n = numel(v); rl = zeros(n,1); i = 1;
    while i <= n
        if isnan(v(i)); rl(i)=0; i=i+1; continue; end
        j = i;
        while j < n && ~isnan(v(j+1)) && v(j+1)==v(i); j = j+1; end
        rl(i:j) = j-i+1; i = j+1;
    end
end

function [t,p] = local_ttest_paired(x,y)
    d = x(:)-y(:); d = d(~isnan(d));
    n = numel(d); df = n-1;
    t = mean(d)/(std(d)/sqrt(n));
    p = betainc(df/(df+t^2), df/2, 0.5);
end

function p = local_signflip(d, nperm)
    d = d(~isnan(d)); n = numel(d);
    obs = abs(mean(d));
    S = (rand(nperm,n) > 0.5)*2 - 1;
    p = (sum(abs(S*d/n) >= obs) + 1) / (nperm + 1);
end

function dz = local_mde(n, alpha, power)
    za = local_norminv(1-alpha/2);
    zb = local_norminv(power);
    dz = (za+zb)/sqrt(n) * (1 + 1/(4*(n-1)));
end

function z = local_norminv(p)
    a = [-3.969683028665376e+01  2.209460984245205e+02 -2.759285104469687e+02 ...
          1.383577518672690e+02 -3.066479806614716e+01  2.506628277459239e+00];
    b = [-5.447609879822406e+01  1.615858368580409e+02 -1.556989798598866e+02 ...
          6.680131188771972e+01 -1.328068155288572e+01];
    c = [-7.784894002430293e-03 -3.223964580411365e-01 -2.400758277161838e+00 ...
         -2.549732539343734e+00  4.374664141464968e+00  2.938163982698783e+00];
    d = [ 7.784695709041462e-03  3.224671290700398e-01  2.445134137142996e+00 ...
          3.754408661907416e+00];
    pl = 0.02425;
    if p < pl
        q = sqrt(-2*log(p));
        z = (((((c(1)*q+c(2))*q+c(3))*q+c(4))*q+c(5))*q+c(6)) / ...
            ((((d(1)*q+d(2))*q+d(3))*q+d(4))*q+1);
    elseif p <= 1-pl
        q = p-0.5; r = q*q;
        z = (((((a(1)*r+a(2))*r+a(3))*r+a(4))*r+a(5))*r+a(6))*q / ...
            (((((b(1)*r+b(2))*r+b(3))*r+b(4))*r+b(5))*r+1);
    else
        q = sqrt(-2*log(1-p));
        z = -(((((c(1)*q+c(2))*q+c(3))*q+c(4))*q+c(5))*q+c(6)) / ...
             ((((d(1)*q+d(2))*q+d(3))*q+d(4))*q+1);
    end
end

function G = local_cellmeans(sub, metrics, states, min_epochs)
    rats_u = unique(sub.Rat);
    G = nan(numel(rats_u), numel(metrics), numel(states));
    for r = 1:numel(rats_u)
        rmask = strcmp(sub.Rat, rats_u{r});
        for s = 1:numel(states)
            idx = rmask & sub.State == states(s);
            if sum(idx) < min_epochs; continue; end
            for m = 1:numel(metrics)
                G(r,m,s) = mean(sub.(metrics{m})(idx),'omitnan');
            end
        end
    end
end