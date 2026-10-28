%% conflict_state_interaction_weighted.m  --  STANDALONE
% =========================================================================
% STATE x TRIAL-TYPE INTERACTION, POSTERIOR-WEIGHTED
%
% Same two anchor-valid contrasts as conflict_state_interaction.m, but state
% membership enters as a continuous weight rather than a hard assignment.
%
% RATIONALE (pre-specified, does not reference the result)
% -------------------------------------------------------------------------
% The thresholded analysis discards every trial with max posterior < 0.65
% -- 2,126 of 16,751, about 11% -- and then treats a trial at P(S1) = 0.66
% as equivalent to one at P(S1) = 0.99. The GLM-HMM's own output is a
% probability, so the threshold throws away information the model provides.
%
% Here the State 1 conflict profile is the weighted mean of ALL that rat's
% conflict trials with weights P(S1), and the State 2 profile the same with
% weights P(S2). No trial is discarded and no rat is excluded for failing a
% count threshold in a thin cell.
%
% This is a different ESTIMATOR of the same quantity, not a different
% question. Report it alongside the thresholded version. Which one is
% designated primary must be decided BEFORE looking at the output and
% recorded in the variants table either way.
%
% WHAT WEIGHTING DOES AND DOES NOT FIX
% -------------------------------------------------------------------------
% Fixes: the 11% discarded trials, the loss of graded confidence, and the
%   n = 7 ceiling on the responded contrast (which was set by Conf_Resp S2
%   having only 8 rats above threshold -- pressed conflict trials are
%   off-policy for the risk-averse state and will always be sparse).
%
% Does NOT fix: State 1 and State 2 profiles are now built from overlapping
%   trial sets, since a trial with P(S1) = 0.5 contributes to both. This
%   induces a positive correlation between the two profiles and therefore
%   SHRINKS the difference between them relative to the thresholded
%   analysis. Expect smaller d2 differences. That is not a weaker result --
%   it is the same effect measured on a scale that includes ambiguous
%   trials. Do not compare effect sizes across the two analyses.
%
% ANCHOR-VALIDITY RULE (unchanged)
% -------------------------------------------------------------------------
%   Rew_Resp   pressing on rewDS      modal  -> valid anchor
%   Pun_Omit   withholding on punDS   modal  -> valid anchor
%   Rew_Omit / Pun_Resp                      -> off-policy, not anchors
% Anchors pool across all trials of that cue x choice cell regardless of
% state, so they are unweighted. The reference stays fixed within animal and
% only conflict moves.
%
% EFFECTIVE N
% -------------------------------------------------------------------------
% With weights, trial count is replaced by Kish effective sample size:
%     N_eff = (sum w)^2 / sum(w^2)
% A rat contributing 200 trials that all sit at P(S1) = 0.5 has N_eff = 200
% for the weighted mean but the profile is heavily contaminated by the other
% state. N_eff is therefore necessary but not sufficient -- the per-rat CSV
% also reports mean weight and weight concentration so thin or ambiguous
% cells are visible rather than hidden.
% =========================================================================

clear; close all; clc;

%% --- Configuration ------------------------------------------------------
CFG = struct();
CFG.path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
CFG.path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
                  'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];
CFG.out_dir    = fullfile(pwd, 'interaction_weighted_output');

CFG.time_window = linspace(-10, 45, 876);
CFG.windows     = {[0 10], [5 10]};      % 0-10 primary, 5-10 secondary

CFG.min_neff          = 5;    % effective N for a conflict cell
% Weight sharpening. w = P(state)^k. k = 1 is the plain weighted analysis;
% as k grows the weighting concentrates on high-confidence trials and
% converges on hard assignment. This is a DIAGNOSTIC traversing the space
% between the weighted and thresholded analyses -- no value of k is
% selected as primary.
CFG.weight_powers = [1 2 4 8];
CFG.min_anchor_trials = 10;   % anchors are unweighted, so a plain count
CFG.n_splits          = 1000; % raised from 200: the previous n-matched
                              % estimator moved p from 0.048 to 0.164
                              % between runs at 200 iterations
CFG.seed              = 14;

% Posterior column names in the collated CSV
CFG.prob_cols = {'Prob_State_1','Prob_State_2','Prob_State_3'};

CFG.cue_col     = 2;
CFG.latency_col = 3;
CFG.outcome_col = 4;
CFG.trace_col0  = 5;
CFG.check_latency     = true;
CFG.latency_tol       = 0.1;
CFG.min_latency_agree = 0.90;

if ~exist(CFG.out_dir, 'dir'), mkdir(CFG.out_dir); end
rng(CFG.seed);

% direction = expected sign of d2(State 1) - d2(State 2)
CONTRASTS = {
    'Omitted: Conf vs punDS',   'Conf_Omit', 'Pun_Omit', 'punDS', 'greater'
    'Responded: Conf vs rewDS', 'Conf_Resp', 'Rew_Resp', 'rewDS', 'less'
};

fprintf('\n%s\nPOSTERIOR-WEIGHTED STATE x TRIAL-TYPE INTERACTION\n%s\n', ...
    repmat('=',1,74), repmat('=',1,74));
fprintf(['\nState membership is a continuous weight. No posterior threshold,\n' ...
         'no trials discarded, no rats excluded on cell counts.\n' ...
         'Anchors: Rew_Resp and Pun_Omit only (modal response to each cue).\n']);

%% --- 1. Load ------------------------------------------------------------
fprintf('\n[1] Loading data\n');
[RawData, LoadQC] = buildRawDataWeighted(CFG);
rats = fieldnames(RawData);

fprintf('    %d rats, %d of %d sessions used, %d trials retained\n', ...
    numel(rats), LoadQC.n_sessions, LoadQC.n_files, LoadQC.n_assigned);
fprintf('    Trials recovered that the 0.65 threshold would have dropped: %d\n', ...
    LoadQC.n_below_threshold);
fprintf('    Trials dropped for missing/invalid posteriors: %d\n', LoadQC.n_bad_prob);
if LoadQC.n_latency_checked > 0
    if LoadQC.n_latency_mismatch == 0
        fprintf('    Latency QC PASSED: %d trials verified, 0 mismatches\n', ...
            LoadQC.n_latency_checked);
    else
        fprintf(2, '    Latency QC: %d / %d mismatches\n', ...
            LoadQC.n_latency_mismatch, LoadQC.n_latency_checked);
    end
end
if LoadQC.n_skipped_count > 0 || LoadQC.n_skipped_latency > 0
    fprintf(2, '    Skipped %d sessions (row-count) and %d (latency)\n', ...
        LoadQC.n_skipped_count, LoadQC.n_skipped_latency);
    for b = 1:min(10, numel(LoadQC.bad_sessions))
        fprintf(2, '        %s\n', LoadQC.bad_sessions{b});
    end
end
if LoadQC.n_assigned == 0, error('No trials retained.'); end

%% --- 2. Effective-N report ---------------------------------------------
% Printed over the full cue period; N_eff does not depend on the window.
fprintf('\n[2] Effective N per conflict cell (N_eff = (sum w)^2 / sum w^2)\n');
fprintf('    %-6s  %10s %10s   %10s %10s\n', 'Rat', ...
    'Omit N_S1','Omit N_S2','Resp N_S1','Resp N_S2');
for k = 1:numel(rats)
    r = rats{k};
    eo1 = effN(RawData.(r).Conf_Omit.w(:,1));
    eo2 = effN(RawData.(r).Conf_Omit.w(:,2));
    er1 = effN(RawData.(r).Conf_Resp.w(:,1));
    er2 = effN(RawData.(r).Conf_Resp.w(:,2));
    fprintf('    %-6s  %10.1f %10.1f   %10.1f %10.1f\n', ...
        RawData.(r).name, eo1, eo2, er1, er2);
end

%% --- 3. Interaction tests ----------------------------------------------
perRat = {}; tests = {}; loo = {};
for ki = 1:numel(CFG.weight_powers)
kpow = CFG.weight_powers(ki);
fprintf('\n%s\n  WEIGHT POWER k = %d%s\n%s\n', repmat('=',1,74), kpow, ...
    ternary(kpow==1, '   (plain weighted)', ''), repmat('=',1,74));
    for wi = 1:numel(CFG.windows)
    CFG.analysis_win = CFG.windows{wi};
    CFG.win_label = sprintf('%g-%gs', CFG.analysis_win(1), CFG.analysis_win(2));
    win_idx = CFG.time_window >= CFG.analysis_win(1) & ...
              CFG.time_window <= CFG.analysis_win(2);
    
    if wi == 1, wtag = '   [PRIMARY]'; else, wtag = '   [secondary window]'; end
    fprintf('\n%s\n  WINDOW %s  (%d samples)%s\n%s\n', repmat('-',1,74), ...
        CFG.win_label, sum(win_idx), wtag, repmat('-',1,74));
    
    for ci = 1:size(CONTRASTS,1)
        label  = CONTRASTS{ci,1}; f_conf = CONTRASTS{ci,2};
        f_anch = CONTRASTS{ci,3}; anchNm = CONTRASTS{ci,4};
        direc  = CONTRASTS{ci,5};
    
        D = []; keptRats = {};
    
        for k = 1:numel(rats)
            r = rats{k};
            C = RawData.(r).(f_conf).X;
                    W = RawData.(r).(f_conf).w .^ kpow;
            if isempty(C), continue; end
    
            n1 = effN(W(:,1)); n2 = effN(W(:,2));
            if n1 < CFG.min_neff || n2 < CFG.min_neff, continue; end
    
            A = RawData.(r).(f_anch).X;
            if size(A,1) < CFG.min_anchor_trials, continue; end
    
            Cw = C(:,win_idx); Aw = A(:,win_idx);
    
            d1 = crossnobisD2w(Cw, W(:,1), Aw, CFG.n_splits);
            d2 = crossnobisD2w(Cw, W(:,2), Aw, CFG.n_splits);
            if ~isfinite(d1) || ~isfinite(d2), continue; end
    
            D(end+1,:) = [d1 d2]; %#ok<SAGROW>
            keptRats{end+1} = RawData.(r).name; %#ok<SAGROW>
            perRat(end+1,:) = {RawData.(r).name, label, anchNm, ...
                size(C,1), n1, n2, mean(W(:,1)), mean(W(:,2)), ...
                size(A,1), d1, d2, d1-d2, CFG.win_label}; %#ok<SAGROW>
        end
    
        if size(D,1) < 3
            fprintf('    %-26s  only %d rats -- not tested\n', label, size(D,1));
            continue;
        end
    
        st = signFlipTest(D(:,1), D(:,2), direc);
        fprintf(['    %-26s n=%2d  S1=%7.3f  S2=%7.3f  diff=%7.3f  med=%7.3f  ' ...
                 '%2d/%2d+  dz=%5.2f  p=%.3f%s  p_med=%.3f  p_sign=%.3f\n'], ...
                 label, st.n, mean(D(:,1)), mean(D(:,2)), st.mean_diff, ...
                 st.median_diff, st.n_pos, st.n, st.dz, st.p, pStars(st.p), ...
                 st.p_median, st.p_sign);
        fprintf('        bootstrap 95%% CI on mean difference: [%.3f, %.3f]\n', ...
                 st.ci_lo, st.ci_hi);
        tests(end+1,:) = {label, anchNm, 'crossnobis-weighted', direc, st.n, ...
            mean(D(:,1)), mean(D(:,2)), st.mean_diff, st.median_diff, ...
            st.n_pos, st.dz, st.ci_lo, st.ci_hi, st.p, st.p_median, ...
            st.p_sign, CFG.win_label, wi==1}; %#ok<SAGROW>
    
        if size(D,1) >= 4
            dL = nan(size(D,1),1); pL = nan(size(D,1),1);
            for j = 1:size(D,1)
                keep = true(size(D,1),1); keep(j) = false;
                s2 = signFlipTest(D(keep,1), D(keep,2), direc);
                dL(j) = s2.mean_diff; pL(j) = s2.p;
            end
            [pw, iw] = max(pL);
            fprintf('        LOO: diff %.3f to %.3f, p %.3f to %.3f (worst without %s)\n', ...
                     min(dL), max(dL), min(pL), pw, keptRats{iw});
            loo(end+1,:) = {label, anchNm, CFG.win_label, size(D,1), ...
                min(dL), max(dL), min(pL), pw, keptRats{iw}}; %#ok<SAGROW>
        end
    end
    end
end

%% --- 4. Write out -------------------------------------------------------
if ~isempty(perRat)
    writetable(cell2table(perRat, 'VariableNames', {'Rat','Contrast','Anchor', ...
        'N_Conf_Trials','Neff_S1','Neff_S2','MeanW_S1','MeanW_S2', ...
        'N_Anchor','d2_S1','d2_S2','d2_diff','Window'}), ...
        fullfile(CFG.out_dir,'weighted_per_rat.csv'));
end
if ~isempty(tests)
    writetable(cell2table(tests, 'VariableNames', {'Contrast','Anchor', ...
        'Estimator','Alternative','N_Rats','Mean_S1','Mean_S2','Mean_Diff', ...
        'Median_Diff','N_Positive','Cohens_dz','CI_lo','CI_hi','p_mean', ...
        'p_median','p_sign','Window','Is_Primary'}), ...
        fullfile(CFG.out_dir,'weighted_tests.csv'));
end
if ~isempty(loo)
    writetable(cell2table(loo, 'VariableNames', {'Contrast','Anchor','Window', ...
        'N_Rats','Diff_min','Diff_max','p_min','p_max','Worst_Excluded_Rat'}), ...
        fullfile(CFG.out_dir,'weighted_loo.csv'));
end
fprintf('\n[4] CSVs written to %s\n', CFG.out_dir);

fprintf('\n%s\n', repmat('=',1,74));
fprintf(['State 1 and State 2 profiles share trials, so the difference is\n' ...
         'shrunk relative to the thresholded analysis. Compare DIRECTION and\n' ...
         'p, not effect size, across the two.\n' ...
         'Negative d2 means indistinguishable given noise -- do not clip.\n' ...
         'All p-values one-tailed; state this explicitly in the manuscript.\n']);
fprintf('%s\n\n', repmat('=',1,74));


%% =========================================================================
%  LOCAL FUNCTIONS
%  =========================================================================

function n = effN(w)
% Kish effective sample size for a weighted mean.
    w = w(isfinite(w) & w > 0);
    if isempty(w), n = 0; return; end
    n = sum(w)^2 / sum(w.^2);
end

function [RawData, QC] = buildRawDataWeighted(CFG)
% As buildRawData, but carries the full posterior vector per trial instead
% of a hard state label. Trials below the 0.65 threshold are RETAINED --
% they simply carry low weight in both states.
    T = readtable(CFG.path_excel);
    for c = 1:numel(CFG.prob_cols)
        if ~ismember(CFG.prob_cols{c}, T.Properties.VariableNames)
            error(['Column %s not found in the collated CSV. Check ' ...
                   'CFG.prob_cols against the actual header.'], CFG.prob_cols{c});
        end
    end

    files = dir(fullfile(CFG.path_data, '*.mat'));
    if isempty(files), error('No .mat files found in %s', CFG.path_data); end

    conds = {'Rew_Resp','Rew_Omit','Pun_Resp','Pun_Omit','Conf_Resp','Conf_Omit'};
    RawData = struct();
    QC = struct('n_files',numel(files),'n_sessions',0,'n_skipped_count',0, ...
                'n_skipped_latency',0,'n_assigned',0,'n_below_threshold',0, ...
                'n_bad_prob',0,'n_unmatched',0,'n_latency_checked',0, ...
                'n_latency_mismatch',0,'bad_sessions',{{}});

    for i = 1:numel(files)
        S = load(fullfile(CFG.path_data, files(i).name));
        if ~isfield(S,'sesdat'), continue; end
        sesdat = S.sesdat;
        if ~isfield(sesdat,'traces_z_10_45'), continue; end

        rat = sesdat.rat; session = sesdat.ses;
        tr = sesdat.traces_z_10_45;
        tr = tr(ismember(tr(:,CFG.cue_col), [1 2 3]), :);
        [~, ord] = sort(tr(:,1));
        tr = tr(ord,:);

        mask = strcmp(string(T.Rat), string(rat)) & ...
               strcmp(string(T.Session), string(session));
        sdat = T(mask,:);
        if isempty(sdat), continue; end
        tag = sprintf('%s/%s', string(rat), string(session));

        if size(tr,1) ~= height(sdat)
            QC.n_skipped_count = QC.n_skipped_count + 1;
            QC.bad_sessions{end+1} = sprintf('%s (%d traces vs %d CSV rows)', ...
                tag, size(tr,1), height(sdat));
            continue;
        end

        csvLat = sdat.Latency;
        if iscell(csvLat), csvLat = cell2mat(csvLat); end
        cmp = isfinite(csvLat) & isfinite(tr(:,CFG.latency_col));
        nAgree = sum(abs(csvLat(cmp) - tr(cmp,CFG.latency_col)) <= CFG.latency_tol);
        QC.n_latency_checked  = QC.n_latency_checked + sum(cmp);
        QC.n_latency_mismatch = QC.n_latency_mismatch + (sum(cmp) - nAgree);
        if CFG.check_latency && sum(cmp) > 0 && ...
                nAgree / sum(cmp) < CFG.min_latency_agree
            QC.n_skipped_latency = QC.n_skipped_latency + 1;
            QC.bad_sessions{end+1} = sprintf('%s (latency agreement %.0f%%)', ...
                tag, 100*nAgree/sum(cmp));
            continue;
        end

        QC.n_sessions = QC.n_sessions + 1;
        fld = matlab.lang.makeValidName(char(string(rat)));
        if ~isfield(RawData, fld)
            RawData.(fld).name = char(string(rat));
            for c = 1:numel(conds)
                RawData.(fld).(conds{c}).X = [];
                RawData.(fld).(conds{c}).w = [];
            end
        end

        csvTrials = sdat.Trial;
        if iscell(csvTrials), csvTrials = cell2mat(csvTrials); end
        P = [sdat.(CFG.prob_cols{1}) sdat.(CFG.prob_cols{2}) sdat.(CFG.prob_cols{3})];

        for ti = 1:size(tr,1)
            row = find(csvTrials == ti, 1);
            if isempty(row), QC.n_unmatched = QC.n_unmatched + 1; continue; end

            p = P(row,:);
            if any(~isfinite(p)) || sum(p) <= 0
                QC.n_bad_prob = QC.n_bad_prob + 1; continue;
            end
            p = p / sum(p);
            if max(p) < 0.65, QC.n_below_threshold = QC.n_below_threshold + 1; end

            resp = tr(ti, CFG.outcome_col) >= 1;
            switch tr(ti, CFG.cue_col)
                case 1, cf = 'Rew_Resp';  if ~resp, cf = 'Rew_Omit';  end
                case 2, cf = 'Pun_Resp';  if ~resp, cf = 'Pun_Omit';  end
                case 3, cf = 'Conf_Resp'; if ~resp, cf = 'Conf_Omit'; end
                otherwise, continue;
            end

            RawData.(fld).(cf).X = [RawData.(fld).(cf).X; tr(ti, CFG.trace_col0:end)];
            RawData.(fld).(cf).w = [RawData.(fld).(cf).w; p(1:2)];
            QC.n_assigned = QC.n_assigned + 1;
        end
    end
end

function d2 = crossnobisD2w(C, w, A, nSplits)
% Cross-validated squared distance between a WEIGHTED mean of C and the
% unweighted mean of anchor A. Independent trial halves on both sides, so
% noise does not inflate the estimate. Negative values are legitimate.
%
% Weights are renormalised within each half. A half whose weights sum to
% near zero yields no usable estimate and is skipped.
    nC = size(C,1); nA = size(A,1);
    if nC < 4 || nA < 4, d2 = NaN; return; end
    T = size(C,2);
    vals = nan(nSplits,1);
    for s = 1:nSplits
        ic = randperm(nC); ia = randperm(nA);
        hc = floor(nC/2);  ha = floor(nA/2);
        c1 = ic(1:hc);     c2 = ic(hc+1:end);
        a1 = ia(1:ha);     a2 = ia(ha+1:end);

        m1 = wmean(C(c1,:), w(c1));
        m2 = wmean(C(c2,:), w(c2));
        if isempty(m1) || isempty(m2), continue; end

        dA = m1 - mean(A(a1,:),1);
        dB = m2 - mean(A(a2,:),1);
        vals(s) = (dA * dB') / T;
    end
    d2 = mean(vals, 'omitnan');
end

function m = wmean(X, w)
    w = w(:);
    sw = sum(w);
    if ~isfinite(sw) || sw < 1e-9, m = []; return; end
    m = (w' * X) / sw;
end

function st = signFlipTest(x1, x2, alternative)
% Paired sign-flip permutation test on d = x1 - x2. Exhaustive for n <= 16,
% Monte Carlo above. Median permutation and exact sign test as companions.
    d = x1(:) - x2(:); d = d(isfinite(d)); n = numel(d);
    st = struct('n',n,'mean_diff',NaN,'median_diff',NaN,'p',NaN, ...
                'p_median',NaN,'p_sign',NaN,'n_pos',NaN,'dz',NaN, ...
                'ci_lo',NaN,'ci_hi',NaN,'exhaustive',false);
    if n < 3, return; end
    obs = mean(d);
    if n <= 16
        signs = 1 - 2*(dec2bin(0:2^n-1) - '0'); st.exhaustive = true;
    else
        signs = 1 - 2*(rand(20000,n) < 0.5);
    end
    null_d = signs * d / n;
    switch alternative
        case 'greater', p = (sum(null_d >= obs)+1)/(numel(null_d)+1);
        case 'less',    p = (sum(null_d <= obs)+1)/(numel(null_d)+1);
        otherwise,      p = (sum(abs(null_d) >= abs(obs))+1)/(numel(null_d)+1);
    end
    obs_med  = median(d);
    null_med = median(signs .* repmat(d', size(signs,1), 1), 2);
    switch alternative
        case 'greater', p_med = (sum(null_med >= obs_med)+1)/(numel(null_med)+1);
        case 'less',    p_med = (sum(null_med <= obs_med)+1)/(numel(null_med)+1);
        otherwise,      p_med = (sum(abs(null_med) >= abs(obs_med))+1)/(numel(null_med)+1);
    end
    nPos = sum(d > 0); nNZ = sum(d ~= 0);
    kk = nPos; if strcmp(alternative,'less'), kk = nNZ - nPos; end
    p_sign = binomTail(kk, nNZ);
    if strcmp(alternative,'two-sided'), p_sign = min(1, 2*p_sign); end

    boot = mean(d(randi(n,10000,n)),2);
    st.mean_diff = obs; st.median_diff = obs_med;
    st.p = p; st.p_median = p_med; st.p_sign = p_sign;
    st.n_pos = nPos; st.dz = obs/std(d);
    st.ci_lo = pctl(boot,2.5); st.ci_hi = pctl(boot,97.5);
end

function p = binomTail(k, n)
    if n == 0, p = NaN; return; end
    p = 0;
    for j = k:n, p = p + nchoosek(n,j); end
    p = p / 2^n;
end

function q = pctl(x, p)
    x = sort(x(:)); n = numel(x);
    if n == 0, q = NaN; return; end
    idx = max(1, min(n, (p/100)*n + 0.5));
    lo = floor(idx); hi = ceil(idx);
    if lo == hi, q = x(lo); else, q = x(lo) + (idx-lo)*(x(hi)-x(lo)); end
end

function s = pStars(p)
    if isnan(p),      s = '';
    elseif p < 0.001, s = '***';
    elseif p < 0.01,  s = '**';
    elseif p < 0.05,  s = '*';
    else,             s = 'ns';
    end
end
function out = ternary(c, a, b)
    if c, out = a; else, out = b; end
end