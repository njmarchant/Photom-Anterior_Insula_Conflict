%% conflict_similarity_index.m  --  STANDALONE
% =========================================================================
% CONFLICT SIMILARITY INDEX -- state-dependent categorisation of conflict
%
% Self-contained: loads the .mat session files, joins them to the state
% assignments in the collated CSV, and runs the interaction analysis.
% Nothing needs to be in the workspace beforehand.
%
% WHAT IT REPLACES
% -------------------------------------------------------------------------
% Your current argument rests on four separate contrasts:
%     sig_S1R  State 1 responded: Conf vs rewDS  -> n.s.
%     sig_S2R  State 2 responded: Conf vs rewDS  -> significant
%     sig_S1O  State 1 omitted:   Conf vs punDS  -> significant
%     sig_S2O  State 2 omitted:   Conf vs punDS  -> n.s.
%
% A significant result in one state plus a null in the other is not evidence
% of a difference between states (Nieuwenhuis, Forstmann & Wagenmakers 2011,
% Nat Neurosci 14:1105). This tests the interaction directly.
%
% THE TRIAL-COUNT TRAP
% -------------------------------------------------------------------------
% Distance between two noisy condition means is inflated by noise, and the
% inflation scales with 1/n. State 2 has fewer trials than State 1, so a
% naive distance reports LARGER State 2 distances for purely statistical
% reasons -- exactly the predicted result. You would manufacture your own
% finding.
%
% Fixed by computing distances across independent trial halves:
%     d2 = < mean(A_a) - mean(B_a) , mean(A_b) - mean(B_b) > / T
% Noise is independent across halves so its expectation is zero. Unbiased at
% any trial count. NEGATIVE VALUES ARE VALID -- they mean the true distance
% is at or near zero. Do not clip them.
%
% A trial-count-matched estimator runs alongside as a sanity check.
% =========================================================================

clear; close all; clc;

%% --- Configuration ------------------------------------------------------
CFG = struct();
CFG.path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
CFG.path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
                  'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];
CFG.out_dir    = fullfile(pwd, 'similarity_output');

CFG.time_window  = linspace(-10, 45, 876);   % must match your extraction
% Windows are ALL reported. 0-10 s is primary (the full cue period, matching
% the existing figures). 5-10 s is secondary, justified a priori: the lever is
% not inserted until 10 s, so the late cue period is when the decision is being
% formed, while the first seconds are dominated by the cue-onset transient.
% This rationale does not reference the observed effect -- keep it that way.
CFG.windows = {[0 10], [5 10]};
CFG.min_trials   = 5;                        % matches min_trials_threshold
CFG.n_splits     = 200;                      % half-splits for crossnobis
CFG.n_subsample  = 200;                      % iterations for n-matched check
CFG.seed         = 14;                       % matches np.random.seed(14) in 1_1

% --- Trial matching -------------------------------------------------------
% traces_z_10_45 is an EVENT table, not a trial table. Column 2 codes events
% 1-6; codes 1-3 are the cue-aligned trials (rewDS/punDS/conflict) and codes
% 4-6 are other events. Filtering to 1-3 leaves exactly one row per trial,
% and sorting by column 1 (timestamp) puts them in trial order. Row position
% is therefore the trial number -- as in the original script.
%
% This is verified per session two ways: the filtered row count must equal
% the number of CSV rows, and column 3 (latency) must agree with the CSV.
% Sessions failing the latency check are skipped, not silently included.
CFG.cue_col     = 2;   % event-code column
CFG.latency_col = 3;   % latency column, used for verification
CFG.outcome_col = 4;   % >=1 means responded
CFG.trace_col0  = 5;   % first sample of the trace
CFG.min_latency_agree = 0.90;   % fraction of trials that must match

% --- Anchor definition ----------------------------------------------------
% true  : rewDS / punDS reference profiles are built from ALL of a rat's
%         trials of that cue type (within the same choice condition),
%         pooling across states. The reference axis is then fixed, and the
%         question is purely where conflict sits on it in each state.
%         Requires far fewer cells, so many more rats qualify.
% false : anchors are computed within each state separately (original).
CFG.pooled_anchors    = true;
CFG.anchor_states     = [1 2];   % states pooled into the anchor
CFG.min_anchor_trials = 10;        % anchor needs more trials than a test cell

% Latency cross-check between Excel and MAT column 3. Leave on -- it is the
% only thing that verifies traces are matched to the right trials.
CFG.check_latency = true;
CFG.latency_tol   = 0.1;

if ~exist(CFG.out_dir, 'dir'), mkdir(CFG.out_dir); end
rng(CFG.seed);

if CFG.min_trials < 5
    warning(['CFG.min_trials = %d. Below 5, a condition mean is essentially a ' ...
        'single noisy observation, and crossnobisD2 splits it into halves of ' ...
        '%d trial(s). Rats with the fewest trials produce the most extreme ' ...
        'values and dominate mean-based tests. Report >=5 as primary.'], ...
        CFG.min_trials, max(1,floor(CFG.min_trials/2)));
end

fprintf('\n%s\nCONFLICT SIMILARITY INDEX\n%s\n', repmat('=',1,74), repmat('=',1,74));

%% --- 1. Load and build RawData ------------------------------------------
if CFG.pooled_anchors
    fprintf('\n    Anchors: POOLED across states %s (fixed reference axis)\n', ...
        mat2str(CFG.anchor_states));
else
    fprintf('\n    Anchors: per-state (original definition)\n');
end
fprintf('\n[1] Loading data\n');
[RawData, LoadQC] = buildRawData(CFG);

fprintf('    %d rats, %d of %d sessions used, %d trials assigned\n', ...
    numel(fieldnames(RawData)), LoadQC.n_sessions, LoadQC.n_files, LoadQC.n_assigned);
fprintf('    No confident state (posterior < 0.65): %d trials\n', LoadQC.n_no_state);

if LoadQC.n_latency_checked > 0
    pct = 100 * LoadQC.n_latency_mismatch / LoadQC.n_latency_checked;
    if LoadQC.n_latency_mismatch == 0
        fprintf('    Latency QC PASSED: %d trials verified, 0 mismatches\n', ...
            LoadQC.n_latency_checked);
    else
        fprintf(2, '    Latency QC: %d / %d mismatches (%.2f%%)\n', ...
            LoadQC.n_latency_mismatch, LoadQC.n_latency_checked, pct);
    end
end

if LoadQC.n_skipped_count > 0 || LoadQC.n_skipped_latency > 0
    fprintf(2, '    Skipped %d sessions (row-count) and %d (latency):\n', ...
        LoadQC.n_skipped_count, LoadQC.n_skipped_latency);
    for b = 1:min(10, numel(LoadQC.bad_sessions))
        fprintf(2, '        %s\n', LoadQC.bad_sessions{b});
    end
    if numel(LoadQC.bad_sessions) > 10
        fprintf(2, '        ... and %d more\n', numel(LoadQC.bad_sessions)-10);
    end
end

if LoadQC.n_assigned == 0
    error('No trials assigned. Re-run inspect_trace_structure.m.');
end

rats  = fieldnames(RawData);
conds = {'Rew_Resp','Rew_Omit','Pun_Resp','Pun_Omit','Conf_Resp','Conf_Omit'};
states = {'S1','S2'};   % State 3 excluded: the disengaged state

% Accumulators persist across windows so everything lands in one CSV.
perRat = {}; tests = {}; lamPerRat = {};

%% ===================== LOOP OVER ANALYSIS WINDOWS =======================
for wi = 1:numel(CFG.windows)

CFG.analysis_win = CFG.windows{wi};
CFG.win_label = sprintf('%g-%gs', CFG.analysis_win(1), CFG.analysis_win(2));
win_idx = CFG.time_window >= CFG.analysis_win(1) & ...
          CFG.time_window <= CFG.analysis_win(2);

fprintf('\n%s\n  WINDOW %s  (%d samples)%s\n%s\n', repmat('-',1,74), ...
    CFG.win_label, sum(win_idx), ...
    repmat(' ', 1, 0), repmat('-',1,74));
if wi == 1
    fprintf('  PRIMARY window (full cue period)\n');
else
    fprintf(['  SECONDARY window. Rationale is a priori: the lever is not\n' ...
             '  inserted until 10 s, so the late cue period is when the choice\n' ...
             '  is being formed. Report alongside the primary, not instead.\n']);
end

%% --- 2. Viability report ------------------------------------------------
vr = {};
for k = 1:numel(rats)
    for c = 1:numel(conds)
        for s = 1:3
            sf = sprintf('S%d', s);
            n = size(RawData.(rats{k}).(conds{c}).(sf), 1);
            vr(end+1,:) = {RawData.(rats{k}).name, conds{c}, sf, n}; %#ok<SAGROW>
        end
    end
end
T_viab = cell2table(vr, 'VariableNames', {'Rat','Condition','State','N_Trials'});
writetable(T_viab, fullfile(CFG.out_dir, 'similarity_viability.csv'));

fprintf('\n[2] Viability (rats with >=%d trials)\n', CFG.min_trials);
fprintf('    %-10s  %8s %8s %8s\n', 'Condition', 'State 1', 'State 2', 'State 3');
for c = 1:numel(conds)
    n = zeros(1,3);
    for s = 1:3
        n(s) = sum(strcmp(T_viab.Condition, conds{c}) & ...
                   strcmp(T_viab.State, sprintf('S%d',s)) & ...
                   T_viab.N_Trials >= CFG.min_trials);
    end
    fprintf('    %-10s  %8d %8d %8d\n', conds{c}, n(1), n(2), n(3));
end

%% --- 3. Paired distance contrasts ---------------------------------------
% direction = expected sign of  d2(State 1) - d2(State 2)
contrasts = {
    'Responded: Conf vs rewDS', 'Conf_Resp', 'Rew_Resp', 'rewDS', 'less'
    'Omitted: Conf vs punDS',   'Conf_Omit', 'Pun_Omit', 'punDS', 'greater'
    'Responded: Conf vs punDS', 'Conf_Resp', 'Pun_Resp', 'punDS', 'greater'
    'Omitted: Conf vs rewDS',   'Conf_Omit', 'Rew_Omit', 'rewDS', 'less'
};
% Rows 1-2 mirror your Fig 4 panels and are the primary tests.
% Rows 3-4 are complementary; they report "no rats" if those cells are thin.

fprintf('\n[3] Paired distance interaction (crossnobis primary)\n');

SIMRESULTS = struct();

for ci = 1:size(contrasts,1)
    label = contrasts{ci,1}; f_conf = contrasts{ci,2};
    f_anch = contrasts{ci,3}; anchNm = contrasts{ci,4}; direc = contrasts{ci,5};

    d2cv = []; d2mt = []; keptRats = {};

    for k = 1:numel(rats)
        r = rats{k};
        C1 = RawData.(r).(f_conf).S1;  C2 = RawData.(r).(f_conf).S2;
        if size(C1,1) < CFG.min_trials || size(C2,1) < CFG.min_trials, continue; end
        C1 = C1(:,win_idx); C2 = C2(:,win_idx);

        if CFG.pooled_anchors
            A1 = getAnchor(RawData, r, f_anch, CFG, win_idx);
            if size(A1,1) < CFG.min_anchor_trials, continue; end
            A2 = A1;                                   % shared reference
            ns = [size(C1,1) size(C2,1) size(A1,1) size(A2,1)];
        else
            A1 = RawData.(r).(f_anch).S1;  A2 = RawData.(r).(f_anch).S2;
            ns = [size(C1,1) size(C2,1) size(A1,1) size(A2,1)];
            if any(ns(3:4) < CFG.min_trials), continue; end
            A1 = A1(:,win_idx); A2 = A2(:,win_idx);
        end
        nMatch = min(ns);

        cv1 = crossnobisD2(C1, A1, CFG.n_splits);
        cv2 = crossnobisD2(C2, A2, CFG.n_splits);
        mt1 = matchedD2(C1, A1, nMatch, CFG.n_subsample);
        mt2 = matchedD2(C2, A2, nMatch, CFG.n_subsample);

        d2cv(end+1,:) = [cv1 cv2]; %#ok<SAGROW>
        d2mt(end+1,:) = [mt1 mt2]; %#ok<SAGROW>
        keptRats{end+1} = RawData.(r).name; %#ok<SAGROW>
        perRat(end+1,:) = {RawData.(r).name, label, anchNm, ns(1), ns(2), ...
                           ns(3), ns(4), nMatch, cv1, cv2, mt1, mt2, ...
                           CFG.win_label}; %#ok<SAGROW>
    end

    if isempty(d2cv)
        fprintf('    %-26s  NO RATS MEET CRITERIA\n', label);
        continue;
    end

    for e = 1:2
        if e==1, X = d2cv; tag = 'crossnobis'; else, X = d2mt; tag = 'n-matched '; end
        st = signFlipTest(X(:,1), X(:,2), direc);
        if st.n < 3
            fprintf('    %-26s [%s] n=%2d  -- too few rats to test\n', ...
                label, tag, st.n);
            continue;
        end
        fprintf(['    %-26s [%s] n=%2d  S1=%7.3f  S2=%7.3f  diff=%7.3f  ' ...
                 'med=%7.3f  %2d/%2d+  p=%.3f%s  p_med=%.3f  p_sign=%.3f\n'], ...
                 label, tag, st.n, mean(X(:,1)), mean(X(:,2)), st.mean_diff, ...
                 st.median_diff, st.n_pos, st.n, st.p, pStars(st.p), ...
                 st.p_median, st.p_sign);
        tests(end+1,:) = {label, anchNm, strtrim(tag), direc, st.n, ...
            mean(X(:,1)), mean(X(:,2)), st.mean_diff, st.median_diff, ...
            st.n_pos, st.dz, st.ci_lo, st.ci_hi, st.p, st.p_median, ...
            st.p_sign, CFG.win_label}; %#ok<SAGROW>
    end

    SIMRESULTS.(matlab.lang.makeValidName(label)) = struct( ...
        'label', label, 'rats', {keptRats}, 'd2cv', d2cv, 'd2matched', d2mt);
end

%% --- 4. Projection coefficient ------------------------------------------
% lambda places conflict on the punDS -> rewDS axis:
%    lambda = 1    conflict sits on rewDS
%    lambda = 0    conflict sits on punDS
%    lambda ~ 0.5 in BOTH states  -> compromise / value integration
%    lambda tracking state        -> state-dependent categorisation
%
% This single number separates your account from the integration account
% directly, rather than through a pattern of pairwise contrasts.

fprintf('\n[4] Projection coefficient (lambda)\n');

lamSets = {
    'Responded', 'Conf_Resp', 'Rew_Resp', 'Pun_Resp'
    'Omitted',   'Conf_Omit', 'Rew_Omit', 'Pun_Omit'
};
lamStore = struct();

for li = 1:size(lamSets,1)
    setNm = lamSets{li,1};
    lam = []; lamL = []; lamRats = {}; dgFrac = []; dgIQR = [];

    for k = 1:numel(rats)
        r = rats{k}; cells = cell(2,3); ok = true;
        if CFG.pooled_anchors
            Rm = getAnchor(RawData, r, lamSets{li,3}, CFG, win_idx);
            Pm = getAnchor(RawData, r, lamSets{li,4}, CFG, win_idx);
            if size(Rm,1) < CFG.min_anchor_trials || ...
               size(Pm,1) < CFG.min_anchor_trials, continue; end
            for si = 1:2
                Cm = RawData.(r).(lamSets{li,2}).(states{si});
                if size(Cm,1) < CFG.min_trials, ok = false; break; end
                cells{si,1} = Cm(:,win_idx);
                cells{si,2} = Rm;
                cells{si,3} = Pm;
            end
        else
            for si = 1:2
                for ii = 2:4
                    M = RawData.(r).(lamSets{li,ii}).(states{si});
                    if size(M,1) < CFG.min_trials, ok = false; break; end
                    cells{si,ii-1} = M(:,win_idx);
                end
                if ~ok, break; end
            end
        end
        if ~ok, continue; end

        [l1, l1L, dg1] = projLambda(cells{1,1}, cells{1,2}, cells{1,3}, CFG.n_splits);
        [l2, l2L, dg2] = projLambda(cells{2,1}, cells{2,2}, cells{2,3}, CFG.n_splits);
        if ~isfinite(l1) || ~isfinite(l2)
            fprintf(['    %-5s excluded from lambda: degenerate axis ' ...
                     '(rewDS and punDS profiles indistinguishable)\n'], ...
                     RawData.(r).name);
            continue;
        end
        lam(end+1,:)  = [l1  l2 ];  %#ok<SAGROW>
        lamL(end+1,:) = [l1L l2L];  %#ok<SAGROW>
        dgFrac(end+1,:) = [dg1.frac_den_nonpos dg2.frac_den_nonpos]; %#ok<SAGROW>
        dgIQR(end+1,:)  = [dg1.iqr dg2.iqr dg1.iqr_legacy dg2.iqr_legacy]; %#ok<SAGROW>
        lamRats{end+1} = RawData.(r).name; %#ok<SAGROW>
        lamPerRat(end+1,:) = {RawData.(r).name, setNm, ...
            size(cells{1,1},1), size(cells{2,1},1), ...
            l1, l2, l1-l2, l1L, l2L, l1L-l2L, ...
            dg1.frac_den_nonpos, dg2.frac_den_nonpos, ...
            CFG.win_label}; %#ok<SAGROW>
    end

    lamStore.(setNm) = struct('lam', lam, 'rats', {lamRats});

    if isempty(lam)
        fprintf('    %-10s  insufficient rats (needs all 3 cues, both states)\n', setNm);
        continue;
    end

    st = signFlipTest(lam(:,1), lam(:,2), 'greater');
    fprintf(['    %-10s  n=%2d  lambda_S1=%6.3f  lambda_S2=%6.3f  diff=%6.3f  ' ...
             '%2d/%2d+  p=%.3f%s  p_med=%.3f  p_sign=%.3f\n'], setNm, st.n, ...
             mean(lam(:,1),'omitnan'), mean(lam(:,2),'omitnan'), ...
             st.mean_diff, st.n_pos, st.n, ...
             st.p, pStars(st.p), st.p_median, st.p_sign);
    tests(end+1,:) = {['lambda ' setNm], 'punDS->rewDS axis', 'lambda', ...
        'greater', st.n, mean(lam(:,1),'omitnan'), mean(lam(:,2),'omitnan'), st.mean_diff, ...
        st.median_diff, st.n_pos, st.dz, st.ci_lo, st.ci_hi, st.p, ...
        st.p_median, st.p_sign, CFG.win_label}; %#ok<SAGROW>
        stL = signFlipTest(lamL(:,1), lamL(:,2), 'greater');
    fprintf(['    %-10s  [legacy: C also split]  lambda_S1=%6.3f  ' ...
             'lambda_S2=%6.3f  diff=%6.3f  %2d/%2d+  p=%.3f%s\n'], ...
             setNm, mean(lamL(:,1),'omitnan'), mean(lamL(:,2),'omitnan'), ...
             stL.mean_diff, stL.n_pos, stL.n, stL.p, pStars(stL.p));
    fprintf(['        split-to-split IQR of lambda: %.3f (full C) vs ' ...
             '%.3f (legacy)  -- lower is better\n'], ...
             mean(dgIQR(:,1:2),'all','omitnan'), mean(dgIQR(:,3:4),'all','omitnan'));
    fprintf('        splits with non-positive denominator: %.1f%% (max rat %.1f%%)\n', ...
             100*mean(dgFrac(:),'omitnan'), 100*max(dgFrac(:)));

    for si = 1:2
        sc = signFlipTest(lam(:,si), 0.5*ones(size(lam,1),1), 'two-sided');
        fprintf('        State %d vs compromise (0.5): diff=%+6.3f  p=%.4f %s\n', ...
            si, sc.mean_diff, sc.p, pStars(sc.p));
        tests(end+1,:) = {['lambda ' setNm], sprintf('State %d vs 0.5',si), ...
            'lambda', 'two-sided', sc.n, NaN, NaN, sc.mean_diff, ...
            sc.median_diff, sc.n_pos, sc.dz, sc.ci_lo, sc.ci_hi, sc.p, ...
            sc.p_median, sc.p_sign, CFG.win_label}; %#ok<SAGROW>
    end
end

plotSimilarity(SIMRESULTS, lamStore, CFG);

end   % ===================== END WINDOW LOOP ==============================

%% --- 5. Write out -------------------------------------------------------
if ~isempty(perRat)
    writetable(cell2table(perRat, 'VariableNames', {'Rat','Contrast','Anchor', ...
        'N_Conf_S1','N_Conf_S2','N_Anch_S1','N_Anch_S2','N_Matched', ...
        'd2cv_S1','d2cv_S2','d2matched_S1','d2matched_S2','Window'}), ...
        fullfile(CFG.out_dir,'similarity_per_rat.csv'));
end
if ~isempty(tests)
    writetable(cell2table(tests, 'VariableNames', {'Contrast','Anchor', ...
        'Estimator','Alternative','N_Rats','Mean_S1','Mean_S2','Mean_Diff', ...
        'Median_Diff','N_Positive','Cohens_dz','CI_lo','CI_hi','p_mean', ...
        'p_median','p_sign','Window'}), ...
        fullfile(CFG.out_dir,'similarity_tests.csv'));
end
if ~isempty(lamPerRat)
    writetable(cell2table(lamPerRat, 'VariableNames', {'Rat','Epoch', ...
        'N_Conf_S1','N_Conf_S2','lambda_S1','lambda_S2','lambda_diff', ...
        'lambda_S1_legacy','lambda_S2_legacy','lambda_diff_legacy', ...
        'frac_den_nonpos_S1','frac_den_nonpos_S2','Window'}), ...
        fullfile(CFG.out_dir,'similarity_lambda_per_rat.csv'));
end
fprintf('\n[5] CSVs written to %s\n', CFG.out_dir);

%% =========================================================================
%  LOCAL FUNCTIONS
%  =========================================================================

function [RawData, QC] = buildRawData(CFG)
% Faithful port of Section 3, with the trial mapping verified per session.
%   1. keep event codes 1-3 (the cue-aligned trials)
%   2. sort by timestamp -> row position = trial number
%   3. verify against CSV row count and CSV latency before using the session
    T = readtable(CFG.path_excel);
    files = dir(fullfile(CFG.path_data, '*.mat'));
    if isempty(files)
        error('No .mat files found in %s', CFG.path_data);
    end

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

        % --- 1. keep trial events only, then order by timestamp -------------
        tr = tr(ismember(tr(:,CFG.cue_col), [1 2 3]), :);
        [~, ord] = sort(tr(:,1));
        tr = tr(ord,:);

        mask = strcmp(string(T.Rat), string(rat)) & ...
               strcmp(string(T.Session), string(session));
        sdat = T(mask,:);
        if isempty(sdat), continue; end

        tag = sprintf('%s/%s', string(rat), string(session));

        % --- 2. row count must match the CSV --------------------------------
        if size(tr,1) ~= height(sdat)
            QC.n_skipped_count = QC.n_skipped_count + 1;
            QC.bad_sessions{end+1} = sprintf('%s (%d traces vs %d CSV rows)', ...
                tag, size(tr,1), height(sdat));
            continue;
        end

        % --- 3. latency must agree, trial by trial --------------------------
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

        % --- 4. assign traces to Cue x Choice x State -----------------------
        csvTrials = sdat.Trial;
        if iscell(csvTrials), csvTrials = cell2mat(csvTrials); end

        for ti = 1:size(tr,1)
            row = find(csvTrials == ti, 1);
            if isempty(row), QC.n_unmatched = QC.n_unmatched + 1; continue; end

            st = sdat.Inferred_State(row);
            if iscell(st), st = st{1}; end
            if ischar(st) || isstring(st), st = str2double(st); end
            if isempty(st) || ~isscalar(st) || isnan(st) || ~ismember(st,[1 2 3])
                QC.n_no_state = QC.n_no_state + 1; continue;   % below 0.65 confidence
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
% Anchor traces for one rat and one cue x choice condition.
% Pools across CFG.anchor_states when CFG.pooled_anchors is true.
    M = [];
    for s = CFG.anchor_states
        M = [M; RawData.(r).(fieldName).(sprintf('S%d', s))]; %#ok<AGROW>
    end
    if isempty(M), return; end
    M = M(:, win_idx);
end

function d2 = crossnobisD2(A, B, nSplits)
% Cross-validated (unbiased) squared Euclidean distance between the mean
% traces of A and B. Independent trial halves, so noise does not inflate the
% estimate. Valid at any trial count. Negative values are legitimate.
    nA = size(A,1); nB = size(B,1);
    if nA < 2 || nB < 2, d2 = NaN; return; end
    T = size(A,2); vals = zeros(nSplits,1);
    for s = 1:nSplits
        ia = randperm(nA); ib = randperm(nB);
        ha = floor(nA/2);  hb = floor(nB/2);
        d1 = mean(A(ia(1:ha),:),1)     - mean(B(ib(1:hb),:),1);
        d2h= mean(A(ia(ha+1:end),:),1) - mean(B(ib(hb+1:end),:),1);
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

function [lam, lam_legacy, dg] = projLambda(C, R, P, nSplits)
% Position of conflict on the punDS -> rewDS axis.
%    lambda = <C - P, u> / <R - P, u>,   u = Rb - Pb
%
% u is an estimate of the reference axis and is deliberately SHARED between
% numerator and denominator -- that is what makes this a projection
% coefficient rather than a ratio of two unrelated quantities. What the
% half-splitting buys is that within each inner product the two factors come
% from disjoint trials, so neither is inflated by its own noise.
%
% PRIMARY (lam): conflict enters as the mean of ALL its trials. C shares no
%   trials with R or P, so every cross-term in the numerator is still between
%   independent samples and the estimator remains unbiased. Splitting C added
%   variance and bought nothing.
%       E[<Cfull - Pa, Rb - Pb>] = <Cbar - Pbar, Rbar - Pbar>
%   because Pa _||_ Pb, Pa _||_ Rb, and C _||_ everything.
%
% LEGACY (lam_legacy): conflict also split in half. Reported alongside so the
%   change reads as a variance reduction, not as post-hoc tuning. Both use
%   IDENTICAL splits of R and P, so any difference is attributable solely to
%   the treatment of C.
%
% dg carries axis-reliability diagnostics. den <= 0 means the two independent
% estimates of the R - P axis pointed in opposite directions on that split,
% i.e. the axis was noise. A high fraction is a warning about that rat.

    lam = NaN; lam_legacy = NaN;
    dg = struct('n_valid',0,'frac_den_nonpos',NaN,'iqr',NaN,'iqr_legacy',NaN);
    if min([size(C,1) size(R,1) size(P,1)]) < 4, return; end

    Cfull  = mean(C,1);
    vals   = nan(nSplits,1);
    valsL  = nan(nSplits,1);
    den_np = false(nSplits,1);

    for s = 1:nSplits
        [Ra, Rb] = halves(R);
        [Pa, Pb] = halves(P);
        Ch       = halves(C);          % legacy arm only
        u   = Rb - Pb;
        den = (Ra - Pa) * u';
        den_np(s) = den <= 0;
        if abs(den) > 1e-12
            vals(s)  = ((Cfull - Pa) * u') / den;
            valsL(s) = ((Ch    - Pa) * u') / den;
        end
    end

    lam        = median(vals,  'omitnan');
    lam_legacy = median(valsL, 'omitnan');

    v  = vals(isfinite(vals));
    vL = valsL(isfinite(valsL));
    dg.n_valid         = numel(v);
    dg.frac_den_nonpos = mean(den_np);
    dg.iqr             = pctl(v, 75)  - pctl(v, 25);
    dg.iqr_legacy      = pctl(vL, 75) - pctl(vL, 25);
end

function [m1, m2] = halves(X)
    idx = randperm(size(X,1)); h = floor(size(X,1)/2);
    m1 = mean(X(idx(1:h),:),1);
    m2 = mean(X(idx(h+1:end),:),1);
end

function st = signFlipTest(x1, x2, alternative)
% Paired sign-flip permutation test on d = x1 - x2. Exhaustive for n <= 16,
% Monte Carlo above. Returns p, Cohen's dz and a bootstrap CI.
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
    % --- robust companions ------------------------------------------------
    % Crossnobis is unbiased but its VARIANCE grows sharply at low trial
    % counts, so a single low-trial rat can dominate a mean-based test.
    % The median permutation and the exact sign test are insensitive to that.
    obs_med = median(d);
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
% P(X >= k) for X ~ Binomial(n, 0.5). Exact, no toolbox.
    if n == 0, p = NaN; return; end
    p = 0;
    for j = k:n
        p = p + nchoosek(n,j);
    end
    p = p / 2^n;
end

function q = pctl(x, p)
% Percentile without the Statistics Toolbox.
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

function plotSimilarity(SIMRESULTS, lamStore, CFG)
    c_s1 = [0.69 0.70 0.00]; c_s2 = [0.71 0.00 0.70];
    names = fieldnames(SIMRESULTS);
    lamNames = fieldnames(lamStore);
    if ~isempty(lamNames)
        lamNames = lamNames(cellfun(@(x) ~isempty(lamStore.(x).lam), lamNames));
    end
    nPan = numel(names) + numel(lamNames);
    if nPan == 0, return; end

    figure('Position',[100 100 300*nPan 380],'Color','w');
    for i = 1:numel(names)
        subplot(1,nPan,i); hold on;
        drawPaired(SIMRESULTS.(names{i}).d2cv, c_s1, c_s2);
        yline(0, ':', 'Color', [.4 .4 .4]);
        title(SIMRESULTS.(names{i}).label,'FontSize',9,'Interpreter','none');
        ylabel('cross-validated d^2');
        set(gca,'XTick',[1 2],'XTickLabel',{'State 1','State 2'}, ...
            'XLim',[0.6 2.4],'Box','off','TickDir','out');
    end
    for j = 1:numel(lamNames)
        subplot(1,nPan,numel(names)+j); hold on;
        drawPaired(lamStore.(lamNames{j}).lam, c_s1, c_s2);
        yline(1,'--','rewDS','Color',[0 .6 0]);
        yline(0,'--','punDS','Color',[.8 0 0]);
        yline(0.5,':','compromise','Color',[.4 .4 .4]);
        title(['\lambda -- ' lamNames{j}],'FontSize',9);
        ylabel('\lambda  (punDS \rightarrow rewDS)');
        set(gca,'XTick',[1 2],'XTickLabel',{'State 1','State 2'}, ...
            'XLim',[0.6 2.4],'Box','off','TickDir','out');
    end
    saveas(gcf, fullfile(CFG.out_dir, sprintf('similarity_index_%s.png', CFG.win_label)));
    fprintf('    figure -> similarity_index_%s.png\n', CFG.win_label);
end

function drawPaired(Y, c1, c2)
    for r = 1:size(Y,1)
        plot([1 2], Y(r,:), '-', 'Color', [.65 .65 .65], 'LineWidth', 0.8);
    end
    scatter(ones(size(Y,1),1),   Y(:,1), 45, c1, 'filled', 'MarkerEdgeColor','k');
    scatter(2*ones(size(Y,1),1), Y(:,2), 45, c2, 'filled', 'MarkerEdgeColor','k');
    m = mean(Y,1,'omitnan');
    e = std(Y,0,1,'omitnan') ./ sqrt(sum(isfinite(Y),1));
    errorbar([1 2], m, e, 'LineStyle','none','Color','k','LineWidth',2,'CapSize',12);
    plot([0.82 1.18],[m(1) m(1)],'k-','LineWidth',2.5);
    plot([1.82 2.18],[m(2) m(2)],'k-','LineWidth',2.5);
end