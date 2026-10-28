%% conflict_state_interaction.m  --  STANDALONE
% =========================================================================
% STATE x TRIAL-TYPE INTERACTION ON ANCHOR-VALID CONTRASTS
%
% Replaces the four-contrast pattern behind Fig 4D/E/G/H with two direct
% interaction tests. A significant result in one state plus a null in the
% other is not evidence of a difference between states (Nieuwenhuis,
% Forstmann & Wagenmakers 2011, Nat Neurosci 14:1105).
%
% THE ANCHOR-VALIDITY RULE
% -------------------------------------------------------------------------
% A reference profile is only used when the behaviour defining that cell is
% the MODAL response to that cue by late Phase 3:
%
%     Rew_Resp   pressing on rewDS    modal      -> valid anchor
%     Pun_Omit   withholding on punDS modal      -> valid anchor
%     Rew_Omit   failing to collect food         -> NOT an anchor
%     Pun_Resp   pressing for shock              -> NOT an anchor
%
% The two excluded cells are off-policy events, not sparse samples of the
% same event. Two lines of evidence, both behavioural and both independent
% of the photometry:
%   (i)  Fig 1C -- rewDS responding at ceiling, punDS suppressed
%   (ii) the viability table -- Rew_Omit is the only cell where State 3
%        dominates (12 rats vs 7 and 5); State 3 is the cell where cue
%        discrimination is lost (rewDS vs punDS p = 0.18)
%
% The rule is applied symmetrically and costs a significant result as well
% as a null one: it removes the lambda projection analysis entirely, in
% both epochs, because a choice-matched rewDS->punDS axis needs one
% off-policy cell at every epoch. That is structural, not a sample-size
% problem. Report it in the variants table.
%
% WHAT THIS LEAVES
% -------------------------------------------------------------------------
%   OMITTED    d2(Conf_Omit, Pun_Omit)   S1 vs S2    -- Fig 4E / 4H
%   RESPONDED  d2(Conf_Resp, Rew_Resp)   S1 vs S2    -- Fig 4D / 4G
%
% THE TRIAL-COUNT TRAP
% -------------------------------------------------------------------------
% Distance between two noisy condition means is inflated by noise, and the
% inflation scales with 1/n. State 2 has fewer trials than State 1, so a
% naive distance reports LARGER State 2 distances for purely statistical
% reasons. Fixed by computing across independent trial halves:
%     d2 = < mean(A_a) - mean(B_a) , mean(A_b) - mean(B_b) > / T
% Unbiased at any trial count. NEGATIVE VALUES ARE VALID -- they mean the
% true distance is at or near zero. Do not clip them.
%
% A trial-count-matched estimator runs alongside as a sanity check.
% =========================================================================

clear; close all; clc;

%% --- Configuration ------------------------------------------------------
CFG = struct();
CFG.path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
CFG.path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
                  'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];
CFG.out_dir    = fullfile(pwd, 'interaction_output');

CFG.time_window = linspace(-10, 45, 876);   % must match your extraction
CFG.windows     = {[0 10], [5 10]};         % 0-10 primary, 5-10 secondary
CFG.min_trials        = 5;
CFG.min_anchor_trials = 10;
CFG.n_splits          = 200;
CFG.n_subsample       = 200;
CFG.seed              = 14;

% Anchor state pooling. [1 2] is PRIMARY: State 3 is excluded from every
% other analysis in the paper on the grounds that cue discrimination is
% lost there, and an anchor built from trials where the cue is not
% discriminated is not a cue reference. [1 2 3] is reported alongside so
% the choice is visible rather than buried. Both are run; neither is
% selected after the fact.
CFG.anchor_sets       = {[1 2], [1 2 3]};
CFG.primary_anchor_ix = 1;

CFG.cue_col     = 2;
CFG.latency_col = 3;
CFG.outcome_col = 4;
CFG.trace_col0  = 5;
CFG.check_latency     = true;
CFG.latency_tol       = 0.1;
CFG.min_latency_agree = 0.90;

if ~exist(CFG.out_dir, 'dir'), mkdir(CFG.out_dir); end
rng(CFG.seed);

% --- The two contrasts ---------------------------------------------------
% direction = expected sign of d2(State 1) - d2(State 2)
%   OMITTED   : conflict resembles punDS in State 2, so State 2 distance is
%               SMALLER -> difference is 'greater'
%   RESPONDED : conflict resembles rewDS in State 1, so State 1 distance is
%               SMALLER -> difference is 'less'
CONTRASTS = {
    'Omitted: Conf vs punDS',   'Conf_Omit', 'Pun_Omit', 'punDS', 'greater'
    'Responded: Conf vs rewDS', 'Conf_Resp', 'Rew_Resp', 'rewDS', 'less'
};

fprintf('\n%s\nSTATE x TRIAL-TYPE INTERACTION\n%s\n', ...
    repmat('=',1,74), repmat('=',1,74));
fprintf(['\nAnchor-validity rule: reference profiles built only from\n' ...
         'Rew_Resp and Pun_Omit (the modal response to each cue).\n' ...
         'Rew_Omit and Pun_Resp are off-policy and are not used as anchors.\n']);

%% --- 1. Load ------------------------------------------------------------
fprintf('\n[1] Loading data\n');
[RawData, LoadQC] = buildRawData(CFG);
rats = fieldnames(RawData);

fprintf('    %d rats, %d of %d sessions used, %d trials assigned\n', ...
    numel(rats), LoadQC.n_sessions, LoadQC.n_files, LoadQC.n_assigned);
fprintf('    No confident state (posterior < 0.65): %d trials\n', LoadQC.n_no_state);
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
if LoadQC.n_assigned == 0, error('No trials assigned.'); end

%% --- 2. Viability -------------------------------------------------------
% Printed in full because the anchor-validity rule is justified from it.
conds = {'Rew_Resp','Rew_Omit','Pun_Resp','Pun_Omit','Conf_Resp','Conf_Omit'};
vr = {};
for k = 1:numel(rats)
    for c = 1:numel(conds)
        for s = 1:3
            n = size(RawData.(rats{k}).(conds{c}).(sprintf('S%d',s)), 1);
            vr(end+1,:) = {RawData.(rats{k}).name, conds{c}, ...
                           sprintf('S%d',s), n}; %#ok<SAGROW>
        end
    end
end
T_viab = cell2table(vr, 'VariableNames', {'Rat','Condition','State','N_Trials'});
writetable(T_viab, fullfile(CFG.out_dir, 'viability.csv'));

fprintf('\n[2] Viability (rats with >=%d trials)\n', CFG.min_trials);
fprintf('    %-10s  %8s %8s %8s   %s\n', 'Condition','State 1','State 2','State 3','anchor?');
for c = 1:numel(conds)
    n = zeros(1,3);
    for s = 1:3
        n(s) = sum(strcmp(T_viab.Condition, conds{c}) & ...
                   strcmp(T_viab.State, sprintf('S%d',s)) & ...
                   T_viab.N_Trials >= CFG.min_trials);
    end
    if ismember(conds{c}, {'Rew_Resp','Pun_Omit'}), amark = 'VALID';
    elseif ismember(conds{c}, {'Rew_Omit','Pun_Resp'}), amark = 'off-policy';
    else, amark = '-'; end
    fprintf('    %-10s  %8d %8d %8d   %s\n', conds{c}, n(1), n(2), n(3), amark);
end

%% --- 3. Interaction tests ----------------------------------------------
perRat = {}; tests = {}; loo = {};

for ai = 1:numel(CFG.anchor_sets)
CFG.anchor_states = CFG.anchor_sets{ai};
aLab = sprintf('S%s', strrep(num2str(CFG.anchor_states), '  ', ''));
isPrimaryAnchor = (ai == CFG.primary_anchor_ix);

for wi = 1:numel(CFG.windows)
CFG.analysis_win = CFG.windows{wi};
CFG.win_label = sprintf('%g-%gs', CFG.analysis_win(1), CFG.analysis_win(2));
win_idx = CFG.time_window >= CFG.analysis_win(1) & ...
          CFG.time_window <= CFG.analysis_win(2);

fprintf('\n%s\n  ANCHOR STATES %s   WINDOW %s  (%d samples)%s\n%s\n', ...
    repmat('-',1,74), mat2str(CFG.anchor_states), CFG.win_label, ...
    sum(win_idx), primaryTag(isPrimaryAnchor, wi), repmat('-',1,74));

for ci = 1:size(CONTRASTS,1)
    label  = CONTRASTS{ci,1}; f_conf = CONTRASTS{ci,2};
    f_anch = CONTRASTS{ci,3}; anchNm = CONTRASTS{ci,4};
    direc  = CONTRASTS{ci,5};

    d2cv = []; d2mt = []; keptRats = {};

    for k = 1:numel(rats)
        r = rats{k};
        C1 = RawData.(r).(f_conf).S1;
        C2 = RawData.(r).(f_conf).S2;
        if size(C1,1) < CFG.min_trials || size(C2,1) < CFG.min_trials, continue; end
        C1 = C1(:,win_idx); C2 = C2(:,win_idx);

        A = getAnchor(RawData, r, f_anch, CFG, win_idx);
        if size(A,1) < CFG.min_anchor_trials, continue; end

        ns = [size(C1,1) size(C2,1) size(A,1)];
        nMatch = min(ns);

        cv1 = crossnobisD2(C1, A, CFG.n_splits);
        cv2 = crossnobisD2(C2, A, CFG.n_splits);
        mt1 = matchedD2(C1, A, nMatch, CFG.n_subsample);
        mt2 = matchedD2(C2, A, nMatch, CFG.n_subsample);

        d2cv(end+1,:) = [cv1 cv2];   %#ok<SAGROW>
        d2mt(end+1,:) = [mt1 mt2];   %#ok<SAGROW>
        keptRats{end+1} = RawData.(r).name; %#ok<SAGROW>
        perRat(end+1,:) = {RawData.(r).name, label, anchNm, aLab, ...
            ns(1), ns(2), ns(3), nMatch, cv1, cv2, cv1-cv2, ...
            mt1, mt2, mt1-mt2, CFG.win_label}; %#ok<SAGROW>
    end

    if isempty(d2cv)
        fprintf('    %-26s  NO RATS MEET CRITERIA\n', label);
        continue;
    end

    for e = 1:2
        if e == 1, X = d2cv; tag = 'crossnobis'; else, X = d2mt; tag = 'n-matched '; end
        st = signFlipTest(X(:,1), X(:,2), direc);
        if st.n < 3
            fprintf('    %-26s [%s] n=%2d -- too few rats\n', label, tag, st.n);
            continue;
        end
        fprintf(['    %-26s [%s] n=%2d  S1=%7.3f  S2=%7.3f  diff=%7.3f  ' ...
                 'med=%7.3f  %2d/%2d+  dz=%5.2f  p=%.3f%s  p_med=%.3f  p_sign=%.3f\n'], ...
                 label, tag, st.n, mean(X(:,1)), mean(X(:,2)), st.mean_diff, ...
                 st.median_diff, st.n_pos, st.n, st.dz, st.p, pStars(st.p), ...
                 st.p_median, st.p_sign);
        tests(end+1,:) = {label, anchNm, aLab, strtrim(tag), direc, st.n, ...
            mean(X(:,1)), mean(X(:,2)), st.mean_diff, st.median_diff, ...
            st.n_pos, st.dz, st.ci_lo, st.ci_hi, st.p, st.p_median, ...
            st.p_sign, CFG.win_label, isPrimaryAnchor && wi==1}; %#ok<SAGROW>
    end

    % --- leave-one-out on the crossnobis estimator ----------------------
    % A single animal should not carry the result. Reported as the range of
    % the mean difference and of p across all n leave-one-out refits.
    if size(d2cv,1) >= 4
        dLOO = nan(size(d2cv,1),1); pLOO = nan(size(d2cv,1),1);
        for j = 1:size(d2cv,1)
            keep = true(size(d2cv,1),1); keep(j) = false;
            s2 = signFlipTest(d2cv(keep,1), d2cv(keep,2), direc);
            dLOO(j) = s2.mean_diff; pLOO(j) = s2.p;
        end
        [pw, iw] = max(pLOO);
        fprintf(['        LOO: diff %.3f to %.3f, p %.3f to %.3f ' ...
                 '(worst without %s)\n'], min(dLOO), max(dLOO), ...
                 min(pLOO), pw, keptRats{iw});
        loo(end+1,:) = {label, anchNm, aLab, CFG.win_label, size(d2cv,1), ...
            min(dLOO), max(dLOO), min(pLOO), pw, keptRats{iw}}; %#ok<SAGROW>
    end
end
end
end

%% --- 4. Write out -------------------------------------------------------
if ~isempty(perRat)
    writetable(cell2table(perRat, 'VariableNames', {'Rat','Contrast','Anchor', ...
        'AnchorStates','N_Conf_S1','N_Conf_S2','N_Anchor','N_Matched', ...
        'd2cv_S1','d2cv_S2','d2cv_diff','d2matched_S1','d2matched_S2', ...
        'd2matched_diff','Window'}), ...
        fullfile(CFG.out_dir,'interaction_per_rat.csv'));
end
if ~isempty(tests)
    writetable(cell2table(tests, 'VariableNames', {'Contrast','Anchor', ...
        'AnchorStates','Estimator','Alternative','N_Rats','Mean_S1','Mean_S2', ...
        'Mean_Diff','Median_Diff','N_Positive','Cohens_dz','CI_lo','CI_hi', ...
        'p_mean','p_median','p_sign','Window','Is_Primary'}), ...
        fullfile(CFG.out_dir,'interaction_tests.csv'));
end
if ~isempty(loo)
    writetable(cell2table(loo, 'VariableNames', {'Contrast','Anchor', ...
        'AnchorStates','Window','N_Rats','Diff_min','Diff_max','p_min', ...
        'p_max','Worst_Excluded_Rat'}), ...
        fullfile(CFG.out_dir,'interaction_loo.csv'));
end
fprintf('\n[4] CSVs written to %s\n', CFG.out_dir);

fprintf('\n%s\n', repmat('=',1,74));
fprintf(['Crossnobis is primary, n-matched confirms. Negative d2 means\n' ...
         'indistinguishable given noise -- do not clip.\n' ...
         'The sign test discards magnitude and is the least powerful of the\n' ...
         'three here; report it, but do not treat disagreement with the\n' ...
         'other two as evidence of an outlier-driven result without\n' ...
         'checking the per-rat values first.\n']);
fprintf('%s\n\n', repmat('=',1,74));


%% =========================================================================
%  LOCAL FUNCTIONS
%  =========================================================================

function s = primaryTag(isPrimAnchor, wi)
    if isPrimAnchor && wi == 1
        s = '   [PRIMARY]';
    elseif isPrimAnchor
        s = '   [secondary window]';
    else
        s = '   [sensitivity: anchor states]';
    end
end

function [RawData, QC] = buildRawData(CFG)
% traces_z_10_45 is an EVENT table. Codes 1-3 are the cue-aligned trials;
% filtering to those and sorting by timestamp makes row position the trial
% number. Verified per session two ways: filtered row count must equal the
% CSV row count, and column 3 (latency) must agree with the CSV. Sessions
% failing either check are skipped, not silently included.
    T = readtable(CFG.path_excel);
    files = dir(fullfile(CFG.path_data, '*.mat'));
    if isempty(files), error('No .mat files found in %s', CFG.path_data); end

    conds = {'Rew_Resp','Rew_Omit','Pun_Resp','Pun_Omit','Conf_Resp','Conf_Omit'};
    RawData = struct();
    QC = struct('n_files',numel(files),'n_sessions',0,'n_skipped_count',0, ...
                'n_skipped_latency',0,'n_assigned',0,'n_no_state',0, ...
                'n_unmatched',0,'n_latency_checked',0,'n_latency_mismatch',0, ...
                'bad_sessions',{{}});

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
                RawData.(fld).(conds{c}).S1 = [];
                RawData.(fld).(conds{c}).S2 = [];
                RawData.(fld).(conds{c}).S3 = [];
            end
        end

        csvTrials = sdat.Trial;
        if iscell(csvTrials), csvTrials = cell2mat(csvTrials); end

        for ti = 1:size(tr,1)
            row = find(csvTrials == ti, 1);
            if isempty(row), QC.n_unmatched = QC.n_unmatched + 1; continue; end
            st = sdat.Inferred_State(row);
            if iscell(st), st = st{1}; end
            if ischar(st) || isstring(st), st = str2double(st); end
            if isempty(st) || ~isscalar(st) || isnan(st) || ~ismember(st,[1 2 3])
                QC.n_no_state = QC.n_no_state + 1; continue;
            end
            resp = tr(ti, CFG.outcome_col) >= 1;
            switch tr(ti, CFG.cue_col)
                case 1, cf = 'Rew_Resp';  if ~resp, cf = 'Rew_Omit';  end
                case 2, cf = 'Pun_Resp';  if ~resp, cf = 'Pun_Omit';  end
                case 3, cf = 'Conf_Resp'; if ~resp, cf = 'Conf_Omit'; end
                otherwise, continue;
            end
            sf = sprintf('S%d', st);
            RawData.(fld).(cf).(sf) = [RawData.(fld).(cf).(sf); ...
                                       tr(ti, CFG.trace_col0:end)];
            QC.n_assigned = QC.n_assigned + 1;
        end
    end
end

function M = getAnchor(RawData, r, fieldName, CFG, win_idx)
% Anchor traces for one rat, pooled across CFG.anchor_states. Pooling keeps
% the reference fixed within animal so that only conflict moves between
% states -- a state difference cannot come from the reference shifting.
    M = [];
    for s = CFG.anchor_states
        M = [M; RawData.(r).(fieldName).(sprintf('S%d', s))]; %#ok<AGROW>
    end
    if isempty(M), return; end
    M = M(:, win_idx);
end

function d2 = crossnobisD2(A, B, nSplits)
% Cross-validated squared Euclidean distance between mean traces.
% Independent trial halves, so noise does not inflate the estimate.
% Unbiased at any trial count. Negative values are legitimate.
    nA = size(A,1); nB = size(B,1);
    if nA < 2 || nB < 2, d2 = NaN; return; end
    T = size(A,2); vals = zeros(nSplits,1);
    for s = 1:nSplits
        ia = randperm(nA); ib = randperm(nB);
        ha = floor(nA/2);  hb = floor(nB/2);
        d1  = mean(A(ia(1:ha),:),1)     - mean(B(ib(1:hb),:),1);
        d2h = mean(A(ia(ha+1:end),:),1) - mean(B(ib(hb+1:end),:),1);
        vals(s) = (d1 * d2h') / T;
    end
    d2 = mean(vals);
end

function d2 = matchedD2(A, B, nTrials, nIter)
% Naive squared distance with trial counts forced equal by subsampling.
% Biased upward by noise, but identically across states, so the State 1 vs
% State 2 comparison stays fair. Sanity check only.
    if size(A,1) < nTrials || size(B,1) < nTrials, d2 = NaN; return; end
    T = size(A,2); vals = zeros(nIter,1);
    for i = 1:nIter
        d = mean(A(randperm(size(A,1),nTrials),:),1) - ...
            mean(B(randperm(size(B,1),nTrials),:),1);
        vals(i) = (d * d') / T;
    end
    d2 = mean(vals);
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