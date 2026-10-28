%% conflict_lambda_press_aligned.m
% =========================================================================
% PRESS-ALIGNED PROJECTION ANALYSIS
%
% Tests the Fig 4C/4F/4I claim directly: in the seconds before the lever
% press, does conflict-trial aIC activity sit nearer the rewDS profile in
% State 1 and nearer punDS in State 2?
%
% EXTRACTION (this is the part the previous version got wrong)
% -------------------------------------------------------------------------
% In sesdat.traces_z_25_15, column 2 is the OUTCOME code of a response event,
% not the cue type:
%       5 = pellet delivered      6 = shock delivered
% Rows coded 1-3 in the same matrix are CUE events. Selecting those gives
% cue-aligned traces in a -25/+15 window, which is what produced the earlier
% nonsense figure.
%
%   valid rows      : ismember(traces(:,2), [5 6])
%   col 1           : response timestamp
%   col 2           : outcome (5 pellet / 6 shock)
%   col 3           : latency
%   col 5:end       : trace
%
% The cue type is NOT in the trace row for a response event, so it has to
% come from the CSV. Rows are matched by reverse-alignment arithmetic:
%
%       expected_trial_ts = resp_ts - CUE_TO_LEVER - latency
%
% then matched to the nearest CSV Timestamp within CFG.ts_tol seconds.
%
% CONFLICT PRESSES ARE POOLED ACROSS OUTCOME by default. Pre-press the
% outcome has not happened yet, so pooling is legitimate and preserves n.
% Set CFG.split_conflict_outcome = true to separate them (post-press windows
% only, where the outcome genuinely differs).
%
% RUNS BOTH ESTIMATORS, DELIBERATELY
% -------------------------------------------------------------------------
%   (A) THRESHOLDED   lambda from each rat's mean conflict trace in State 1
%                     vs State 2, using Inferred_State. Paired across rats.
%   (B) SINGLE-TRIAL  lambda per trial regressed on P(S1)-P(S2). No threshold.
%
% In the cue-aligned data these disagreed: (A) significant, (B) not. Report
% both however they come out.
%
% BEFORE READING ANY p-VALUE
% -------------------------------------------------------------------------
% aIC ramps to the press on every cue type, so pre-press the rewDS and punDS
% references may barely separate. lambda divides by that separation.
%   Axis_cvd2 near zero -> lambda is dividing by noise, uninterpretable
%   Lambda_sd >> 1      -> single-trial lambda is noise-dominated, so a null
%                          in (B) is uninformative rather than evidence
%                          against the effect (the anchors are 1.0 apart by
%                          definition)
% Post-press windows are confounded by outcome delivery. Contrast only.
% =========================================================================

clear; close all; clc;

%% --- Configuration ------------------------------------------------------
CFG = struct();
CFG.path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
CFG.path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
                  'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];
CFG.out_dir    = fullfile(pwd, 'lambda_press_output');

CFG.trace_field = 'traces_z_25_15';
CFG.time_bounds = [-25 15];      % span of that field; sample count read from data
CFG.resp_codes  = [5 6];         % 5 pellet, 6 shock
CFG.cue_to_lever = 10;           % s from trial timestamp to lever insertion
CFG.ts_tol       = 0.15;         % timestamp match tolerance, seconds

CFG.windows = { [-5 0], [-10 0], [0 5] };
CFG.primary_window = 1;

CFG.split_conflict_outcome = false;   % pool pellet+shock conflict presses

CFG.min_trials          = 5;     % conflict trials per state, analysis (A)
CFG.min_anchor_trials   = 10;    % per anchor
CFG.min_conflict_trials = 20;    % conflict trials for a slope, analysis (B)
CFG.require_axis        = true;

CFG.control_session  = false;    % session dummies absorbed the predictor before
CFG.control_trialnum = true;

CFG.seed = 14;
if ~exist(CFG.out_dir,'dir'), mkdir(CFG.out_dir); end
rng(CFG.seed);

fprintf('\n%s\nPRESS-ALIGNED PROJECTION ANALYSIS\n%s\n', ...
    repmat('=',1,74), repmat('=',1,74));

%% --- 1. Load ------------------------------------------------------------
fprintf('\n[1] Loading (%s, response events only)\n', CFG.trace_field);
[TD, QC] = buildPressData(CFG);

if QC.nSamp == 0
    error(['No response-event traces found. Check that column 2 of %s ' ...
           'uses codes %s.'], CFG.trace_field, mat2str(CFG.resp_codes));
end
tvec = linspace(CFG.time_bounds(1), CFG.time_bounds(2), QC.nSamp);
fs   = (QC.nSamp - 1) / diff(CFG.time_bounds);

fprintf('    %d rats, %d of %d sessions used\n', ...
    numel(fieldnames(TD)), QC.n_sessions, QC.n_files);
fprintf('    %d samples over %g to %g s  -> %.2f Hz\n', ...
    QC.nSamp, CFG.time_bounds(1), CFG.time_bounds(2), fs);
fprintf('    Timestamp alignment: %d matched, %d failed (tol %.2f s)\n', ...
    QC.matched, QC.failed, CFG.ts_tol);
fprintf('    Response traces kept: %d rewDS, %d punDS, %d conflict\n', ...
    QC.n_rew, QC.n_pun, QC.n_conf);
fprintf('      of which conflict: %d pellet, %d shock\n', ...
    QC.n_conf_pellet, QC.n_conf_shock);
fprintf('    Conflict trials with no confident state: %d\n', QC.n_inconclusive);
if QC.failed > 0.1*(QC.matched+QC.failed)
    warning('%.0f%% of response events failed timestamp alignment.', ...
        100*QC.failed/(QC.matched+QC.failed));
end
if ~isempty(QC.notes)
    fprintf('    Notes: %s\n', strjoin(unique(QC.notes), '; '));
end

%% --- Alignment sanity check ---------------------------------------------
% If these are press-aligned, the rewDS group mean must peak at or just after
% t = 0. If it does not, the extraction or CFG.time_bounds is wrong.
flds = fieldnames(TD);
allRew = [];
for k = 1:numel(flds)
    if ~isempty(TD.(flds{k}).rew)
        allRew = [allRew; mean(TD.(flds{k}).rew,1,'omitnan')]; %#ok<AGROW>
    end
end
fprintf('\n    ---- ALIGNMENT CHECK ----\n');
if isempty(allRew)
    fprintf(2,'    No rewDS response traces at all.\n');
else
    gm = mean(allRew,1,'omitnan');
    [pk, pkI] = max(gm);
    fprintf('    rewDS group mean peaks at %+.2f s (%.2f z)\n', tvec(pkI), pk);
    fprintf('    NaN samples in anchor matrix: %.1f%%\n', ...
        100*mean(~isfinite(allRew(:))));
    if abs(tvec(pkI)) > 2.5
        fprintf(2,['    WARNING: peak is not near the press. Extraction or\n' ...
                   '    CFG.time_bounds is still wrong. Do not read on.\n']);
    else
        fprintf('    Looks correctly press-aligned.\n');
    end
end
fprintf('    -------------------------\n');

rats = fieldnames(TD);
binRows = {}; stRows = {};

%% ===================== LOOP OVER WINDOWS ================================
for wi = 1:numel(CFG.windows)

win  = CFG.windows{wi};
wlab = sprintf('%gto%gs', win(1), win(2));
widx = tvec >= win(1) & tvec <= win(2);

fprintf('\n%s\n  WINDOW %g to %g s  (%d samples)%s\n%s\n', repmat('-',1,74), ...
    win(1), win(2), sum(widx), ...
    tern(wi==CFG.primary_window,'   [PRIMARY]',''), repmat('-',1,74));
if win(1) >= 0
    fprintf(['  Post-press: confounded by outcome delivery (conflict presses\n' ...
             '  give pellet on some trials, shock on others). Contrast only.\n']);
end

% ---------- (A) thresholded ---------------------------------------------
lamA = []; axA = [];
for k = 1:numel(rats)
    r = rats{k}; D = TD.(r);
    C1 = D.conf(D.state==1, widx);
    C2 = D.conf(D.state==2, widx);
    Rw = D.rew(:,widx); Pn = D.pun(:,widx);

    if size(C1,1) < CFG.min_trials || size(C2,1) < CFG.min_trials
        fprintf('    %-5s (A) dropped: conflict S1=%d S2=%d\n', ...
            D.name, size(C1,1), size(C2,1)); continue;
    end
    if size(Rw,1) < CFG.min_anchor_trials || size(Pn,1) < CFG.min_anchor_trials
        fprintf('    %-5s (A) dropped: anchors rew=%d pun=%d\n', ...
            D.name, size(Rw,1), size(Pn,1)); continue;
    end
    a = crossnobisD2(Rw, Pn, 200);
    if CFG.require_axis && ~(a > 0)
        fprintf('    %-5s (A) dropped: axis cv d2 = %s\n', D.name, ...
            tern(isnan(a),'NaN', num2str(a,'%.3f'))); continue;
    end

    l1 = projLambda(C1, Rw, Pn, 200);
    l2 = projLambda(C2, Rw, Pn, 200);
    lamA(end+1,:) = [l1 l2]; %#ok<SAGROW>
    axA(end+1,1)  = a; %#ok<SAGROW>
    binRows(end+1,:) = {D.name, wlab, size(C1,1), size(C2,1), size(Rw,1), ...
        size(Pn,1), a, l1, l2, l1-l2}; %#ok<SAGROW>
end

fprintf('\n  (A) THRESHOLDED, per-state mean traces\n');
if size(lamA,1) < 3
    fprintf('      only %d rats -- not testable\n', size(lamA,1));
else
    st = signFlipTest(lamA(:,1), lamA(:,2), 'greater');
    fprintf('      n=%2d  lambda_S1=%+.3f  lambda_S2=%+.3f  diff=%+.3f  %d/%d+\n', ...
        st.n, mean(lamA(:,1)), mean(lamA(:,2)), st.mean_diff, st.n_pos, st.n);
    fprintf('      p_mean=%.4f%s  p_median=%.4f  p_sign=%.4f  dz=%.2f\n', ...
        st.p, pStars(st.p), st.p_median, st.p_sign, st.dz);
    fprintf('      axis cv d2: median %.3f  range %.3f to %.3f\n', ...
        median(axA), min(axA), max(axA));
    for si = 1:2
        sc = signFlipTest(lamA(:,si), 0.5*ones(size(lamA,1),1), 'two-sided');
        fprintf('        State %d vs compromise (0.5): diff=%+.3f  p=%.4f%s\n', ...
            si, sc.mean_diff, sc.p, pStars(sc.p));
    end
end

% ---------- (B) single-trial --------------------------------------------
slopes = []; sdB = [];
for k = 1:numel(rats)
    r = rats{k}; D = TD.(r);
    nC = size(D.conf,1);
    Rw = D.rew(:,widx); Pn = D.pun(:,widx);
    if nC < CFG.min_conflict_trials, continue; end
    if size(Rw,1) < CFG.min_anchor_trials || size(Pn,1) < CFG.min_anchor_trials
        continue;
    end
    a = crossnobisD2(Rw, Pn, 200);
    if CFG.require_axis && ~(a > 0), continue; end

    Pbar = mean(Pn,1,'omitnan'); Rbar = mean(Rw,1,'omitnan');
    dv = Rbar - Pbar;
    Cw = D.conf(:,widx);
    g  = isfinite(dv) & isfinite(Pbar) & all(isfinite(Cw),1);
    if sum(g) < 5, continue; end
    lam = ((Cw(:,g) - Pbar(g)) * dv(g)') / (dv(g) * dv(g)');

    Xn = [];
    if CFG.control_session
        [~,~,sid] = unique(D.ses);
        for u = 2:max(sid), Xn = [Xn, double(sid==u)]; end %#ok<AGROW>
    end
    if CFG.control_trialnum
        tn = D.tstamp(:); Xn = [Xn, (tn-mean(tn))/std(tn)]; %#ok<AGROW>
    end
    X = [ones(nC,1), D.pS1 - D.pS2, Xn];
    b = X \ lam;

    slopes(end+1,1) = b(2); %#ok<SAGROW>
    sdB(end+1,1)    = std(lam); %#ok<SAGROW>
    stRows(end+1,:) = {D.name, wlab, nC, size(Rw,1), size(Pn,1), a, b(2), ...
        mean(lam), std(lam)}; %#ok<SAGROW>
end

fprintf('\n  (B) SINGLE-TRIAL, regressed on P(S1)-P(S2)\n');
if numel(slopes) < 3
    fprintf('      only %d rats -- not testable\n', numel(slopes));
else
    st = signFlipTest(slopes, zeros(numel(slopes),1), 'greater');
    fprintf('      n=%2d  mean slope=%+.4f  median=%+.4f  %d/%d+\n', ...
        st.n, st.mean_diff, st.median_diff, st.n_pos, st.n);
    fprintf('      p_mean=%.4f%s  p_median=%.4f  p_sign=%.4f  dz=%.2f\n', ...
        st.p, pStars(st.p), st.p_median, st.p_sign, st.dz);
    fprintf('      single-trial lambda SD: median %.2f  range %.2f to %.2f\n', ...
        median(sdB), min(sdB), max(sdB));
    if median(sdB) > 2
        fprintf(2,['      NOTE: SD >> 1, so single-trial lambda is mostly noise.\n' ...
                   '      A null here is uninformative, not counter-evidence.\n']);
    end
end

end
%% ===================== END WINDOW LOOP ==================================

%% --- Outputs ------------------------------------------------------------
TA = table(); TB = table();
if ~isempty(binRows)
    TA = cell2table(binRows, 'VariableNames', {'Rat','Window','N_Conf_S1', ...
        'N_Conf_S2','N_Rew','N_Pun','Axis_cvd2','lambda_S1','lambda_S2', ...
        'lambda_diff'});
    writetable(TA, fullfile(CFG.out_dir,'press_lambda_thresholded.csv'));
end
if ~isempty(stRows)
    TB = cell2table(stRows, 'VariableNames', {'Rat','Window','N_Conflict', ...
        'N_Rew','N_Pun','Axis_cvd2','Slope_contrast','Lambda_mean','Lambda_sd'});
    writetable(TB, fullfile(CFG.out_dir,'press_lambda_singletrial.csv'));
end
if ~isempty(binRows)
    plotPress(TA, TB, CFG, tvec, TD);
end
fprintf('\nWritten to %s\n', CFG.out_dir);


%% =========================================================================
%  LOCAL FUNCTIONS
%  =========================================================================

function out = tern(c, a, b)
    if c, out = a; else, out = b; end
end

function [TD, QC] = buildPressData(CFG)
% Response-aligned traces, matched to the CSV by reverse-alignment on
% timestamps. Cue identity and state come from the CSV, not the trace row.
    T = readtable(CFG.path_excel);
    files = dir(fullfile(CFG.path_data,'*.mat'));
    if isempty(files), error('No .mat files in %s', CFG.path_data); end

    vn = T.Properties.VariableNames;
    need = {'Timestamp','Cue','Inferred_State','Prob_State_1','Prob_State_2'};
    miss = need(~ismember(need, vn));
    if ~isempty(miss), error('CSV lacks %s', strjoin(miss,', ')); end

    % the response loop used Session_Clean; fall back to Session
    if ismember('Session_Clean', vn), sesVar = 'Session_Clean';
    else,                             sesVar = 'Session'; end

    TD = struct();
    QC = struct('n_files',numel(files),'n_sessions',0,'nSamp',0, ...
                'matched',0,'failed',0,'n_rew',0,'n_pun',0,'n_conf',0, ...
                'n_conf_pellet',0,'n_conf_shock',0,'n_inconclusive',0, ...
                'notes',{{}});
    QC.notes{end+1} = sprintf('session matched on %s', sesVar);

    for i = 1:numel(files)
        S = load(fullfile(CFG.path_data, files(i).name));
        if ~isfield(S,'sesdat'), continue; end
        sd = S.sesdat;
        if ~isfield(sd, CFG.trace_field), continue; end

        tr = sd.(CFG.trace_field);
        tr = tr(ismember(tr(:,2), CFG.resp_codes), :);   % RESPONSE events only
        if isempty(tr), continue; end

        mask = strcmp(string(T.Rat), string(sd.rat)) & ...
               strcmp(string(T.(sesVar)), string(sd.ses));
        sdat = T(mask,:);
        if isempty(sdat), continue; end
        QC.n_sessions = QC.n_sessions + 1;

        nS = size(tr,2) - 4;
        if QC.nSamp == 0, QC.nSamp = nS; end
        if nS ~= QC.nSamp
            error('Session %s/%s has %d samples, expected %d.', ...
                string(sd.rat), string(sd.ses), nS, QC.nSamp);
        end

        fld = matlab.lang.makeValidName(char(string(sd.rat)));
        if ~isfield(TD, fld)
            TD.(fld) = struct('name',char(string(sd.rat)), 'conf',[], 'rew',[], ...
                'pun',[], 'state',[], 'pS1',[], 'pS2',[], 'outcome',[], ...
                'ses',{{}}, 'tstamp',[]);
        end

        csvTs = sdat.Timestamp;
        if iscell(csvTs), csvTs = cell2mat(csvTs); end

        for ti = 1:size(tr,1)
            resp_ts = tr(ti,1);
            outcome = tr(ti,2);
            latency = tr(ti,3);

            % ---- reverse-alignment: back out the trial timestamp ----------
            expected = resp_ts - CFG.cue_to_lever - latency;
            [mn, row] = min(abs(csvTs - expected));
            if isempty(mn) || mn > CFG.ts_tol
                QC.failed = QC.failed + 1; continue;
            end
            QC.matched = QC.matched + 1;

            seg = tr(ti, 5:end);
            if all(~isfinite(seg)), continue; end

            cue = lower(string(sdat.Cue(row)));
            if contains(cue,'reward')
                TD.(fld).rew = [TD.(fld).rew; seg];
                QC.n_rew = QC.n_rew + 1;
            elseif contains(cue,'punish')
                TD.(fld).pun = [TD.(fld).pun; seg];
                QC.n_pun = QC.n_pun + 1;
            elseif contains(cue,'conflict')
                if CFG.split_conflict_outcome && outcome == 6
                    continue;   % shock-outcome conflict presses excluded
                end
                st = stateNum(sdat.Inferred_State(row));
                if st == 0, QC.n_inconclusive = QC.n_inconclusive + 1; end
                p1 = sdat.Prob_State_1(row);
                p2 = sdat.Prob_State_2(row);
                if ~all(isfinite([p1 p2])), continue; end

                TD.(fld).conf    = [TD.(fld).conf; seg];
                TD.(fld).state   = [TD.(fld).state; st];
                TD.(fld).pS1     = [TD.(fld).pS1; p1];
                TD.(fld).pS2     = [TD.(fld).pS2; p2];
                TD.(fld).outcome = [TD.(fld).outcome; outcome];
                TD.(fld).ses{end+1,1} = char(string(sd.ses));
                TD.(fld).tstamp  = [TD.(fld).tstamp; resp_ts];
                QC.n_conf = QC.n_conf + 1;
                if outcome == 5, QC.n_conf_pellet = QC.n_conf_pellet + 1;
                else,            QC.n_conf_shock  = QC.n_conf_shock  + 1; end
            end
        end
    end
end

function s = stateNum(v)
% Accepts numeric, string or 'inconclusive'. Returns 0 when unusable.
    s = 0;
    if iscell(v), v = v{1}; end
    if isnumeric(v)
        if isscalar(v) && isfinite(v) && ismember(v,[1 2 3]), s = v; end
        return;
    end
    str = string(v);
    if contains(str,'inconclusive','IgnoreCase',true), return; end
    d = str2double(str);
    if isfinite(d) && ismember(d,[1 2 3]), s = d; return; end
    for c = 1:3
        if contains(str, sprintf('State_%d',c), 'IgnoreCase', true) || ...
           contains(str, sprintf('%d',c))
            s = c; return;
        end
    end
end

function d2 = crossnobisD2(A, B, nSplits)
% Cross-validated (unbiased) squared distance between condition means.
    nA = size(A,1); nB = size(B,1);
    if nA < 2 || nB < 2, d2 = NaN; return; end
    v = nan(nSplits,1);
    for s = 1:nSplits
        ia = randperm(nA); ib = randperm(nB);
        ha = floor(nA/2); hb = floor(nB/2);
        d1 = mean(A(ia(1:ha),:),1,'omitnan')     - mean(B(ib(1:hb),:),1,'omitnan');
        d2h= mean(A(ia(ha+1:end),:),1,'omitnan') - mean(B(ib(hb+1:end),:),1,'omitnan');
        g = isfinite(d1) & isfinite(d2h);
        if any(g), v(s) = (d1(g) * d2h(g)') / sum(g); end
    end
    d2 = mean(v,'omitnan');
end

function lam = projLambda(C, R, P, nSplits)
% Position of C on the P -> R axis, with numerator and denominator computed
% across independent trial halves so neither is inflated by noise.
    if min([size(C,1) size(R,1) size(P,1)]) < 4, lam = NaN; return; end
    v = nan(nSplits,1);
    for s = 1:nSplits
        [Ca,~]  = halves(C); [Ra,Rb] = halves(R); [Pa,Pb] = halves(P);
        g = isfinite(Ca) & isfinite(Ra) & isfinite(Rb) & isfinite(Pa) & isfinite(Pb);
        if ~any(g), continue; end
        num = (Ca(g) - Pa(g)) * (Rb(g) - Pb(g))';
        den = (Ra(g) - Pa(g)) * (Rb(g) - Pb(g))';
        if abs(den) > 1e-12, v(s) = num / den; end
    end
    lam = median(v,'omitnan');
end

function [m1, m2] = halves(X)
    idx = randperm(size(X,1)); h = floor(size(X,1)/2);
    m1 = mean(X(idx(1:h),:),1,'omitnan');
    m2 = mean(X(idx(h+1:end),:),1,'omitnan');
end

function st = signFlipTest(x1, x2, alternative)
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
    nulld = signs * d / n;
    switch alternative
        case 'greater', p = (sum(nulld >= obs)+1)/(numel(nulld)+1);
        case 'less',    p = (sum(nulld <= obs)+1)/(numel(nulld)+1);
        otherwise,      p = (sum(abs(nulld) >= abs(obs))+1)/(numel(nulld)+1);
    end
    om = median(d);
    nullm = median(signs .* repmat(d', size(signs,1), 1), 2);
    switch alternative
        case 'greater', pm = (sum(nullm >= om)+1)/(numel(nullm)+1);
        case 'less',    pm = (sum(nullm <= om)+1)/(numel(nullm)+1);
        otherwise,      pm = (sum(abs(nullm) >= abs(om))+1)/(numel(nullm)+1);
    end
    nPos = sum(d > 0); nNZ = sum(d ~= 0);
    kk = nPos; if strcmp(alternative,'less'), kk = nNZ - nPos; end
    ps = binomTail(kk, nNZ);
    if strcmp(alternative,'two-sided'), ps = min(1, 2*ps); end
    boot = mean(d(randi(n,10000,n)),2);
    st.mean_diff = obs; st.median_diff = om; st.p = p;
    st.p_median = pm; st.p_sign = ps; st.n_pos = nPos;
    st.dz = obs/std(d); st.ci_lo = pctl(boot,2.5); st.ci_hi = pctl(boot,97.5);
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
    else,             s = ' ns';
    end
end

function plotPress(TA, TB, CFG, tvec, TD)
    wlab = sprintf('%gto%gs', CFG.windows{CFG.primary_window}(1), ...
                              CFG.windows{CFG.primary_window}(2));
    A = TA(strcmp(string(TA.Window), wlab), :);
    if isempty(A), return; end

    c_rew=[0.12 0.80 0.01]; c_pun=[0.87 0.01 0.12]; c_conf=[0.01 0.11 0.86];
    c_s1=[0.69 0.70 0.00];  c_s2=[0.71 0.00 0.70];

    keep = tvec >= -10 & tvec <= 10;
    t = tvec(keep);
    names = string(A.Rat); nR = numel(names);
    Mr=nan(nR,sum(keep)); Mp=nan(nR,sum(keep));
    M1=nan(nR,sum(keep)); M2=nan(nR,sum(keep));

    flds = fieldnames(TD);
    for k = 1:nR
        fld = '';
        for j = 1:numel(flds)
            if strcmp(string(TD.(flds{j}).name), names(k)), fld = flds{j}; break; end
        end
        if isempty(fld), continue; end
        D = TD.(fld);
        Mr(k,:) = mean(D.rew(:,keep),1,'omitnan');
        Mp(k,:) = mean(D.pun(:,keep),1,'omitnan');
        M1(k,:) = mean(D.conf(D.state==1,keep),1,'omitnan');
        M2(k,:) = mean(D.conf(D.state==2,keep),1,'omitnan');
    end

    allv = [Mr(:); Mp(:); M1(:); M2(:)];
    yl = [min(allv,[],'omitnan')-0.5, max(allv,[],'omitnan')+0.8];

    figure('Position',[80 80 1150 420],'Color','w');
    for si = 1:2
        subplot(2,3,si*3-2); hold on;
        if si==1, Mc=M1; cs=c_s1; else, Mc=M2; cs=c_s2; end
        patch([CFG.windows{CFG.primary_window}(1) CFG.windows{CFG.primary_window}(2) ...
               CFG.windows{CFG.primary_window}(2) CFG.windows{CFG.primary_window}(1)], ...
              [yl(1) yl(1) yl(2) yl(2)], [.94 .94 .88], 'EdgeColor','none');
        plot([0 0], yl, 'k:', 'LineWidth',1);
        shadedTrace(t, Mr, c_rew); shadedTrace(t, Mp, c_pun); shadedTrace(t, Mc, c_conf);
        ylim(yl); xlim([-10 10]); ylabel('z-\DeltaF/F');
        title(sprintf('State %d  (n=%d)', si, nR),'Color',cs,'FontSize',9);
        if si==2, xlabel('Time from lever press (s)'); end
        set(gca,'Box','off','TickDir','out','Layer','top');
    end

    subplot(2,3,[2 5]); hold on;
    Y = [A.lambda_S1 A.lambda_S2];
    yline(1,'--','rewDS','Color',c_rew,'FontSize',8);
    yline(0,'--','punDS','Color',c_pun,'FontSize',8);
    yline(0.5,':','compromise','Color',[.4 .4 .4],'FontSize',8);
    for r = 1:size(Y,1)
        plot([1 2], Y(r,:), '-', 'Color',[.7 .7 .7], 'LineWidth',0.8);
    end
    scatter(ones(size(Y,1),1),  Y(:,1),55,c_s1,'filled','MarkerEdgeColor','k');
    scatter(2*ones(size(Y,1),1),Y(:,2),55,c_s2,'filled','MarkerEdgeColor','k');
    m = mean(Y,1,'omitnan');
    errorbar([1 2], m, std(Y,0,1,'omitnan')./sqrt(size(Y,1)), 'LineStyle','none', ...
        'Color','k','LineWidth',2,'CapSize',14);
    plot([0.8 1.2],[m(1) m(1)],'k-','LineWidth',3);
    plot([1.8 2.2],[m(2) m(2)],'k-','LineWidth',3);
    set(gca,'XTick',[1 2],'XTickLabel',{'State 1','State 2'}, ...
        'XLim',[0.6 2.5],'Box','off','TickDir','out');
    ylabel('\lambda  (punDS \rightarrow rewDS)');
    title('(A) thresholded','FontSize',9);

    subplot(2,3,[3 6]); hold on;
    if ~isempty(TB)
        B = TB(strcmp(string(TB.Window), wlab), :);
        if ~isempty(B)
            y = B.Slope_contrast;
            scatter(ones(numel(y),1)+0.05*randn(numel(y),1), y, 45, ...
                [.35 .35 .35],'filled','MarkerEdgeColor','k');
            plot([0.8 1.2],[mean(y) mean(y)],'k-','LineWidth',3);
            errorbar(1, mean(y), std(y)/sqrt(numel(y)),'k','LineWidth',2,'CapSize',12);
            yline(0,'--','Color',[.6 .6 .6]);
            title(sprintf('(B) single-trial slopes (n=%d)', numel(y)),'FontSize',9);
        end
    end
    set(gca,'XTick',[],'XLim',[0.6 1.4],'Box','off','TickDir','out');
    ylabel('slope on P(S1)-P(S2)');

    print(gcf, fullfile(CFG.out_dir,'press_lambda.png'), '-dpng','-r300');
    fprintf('    figure -> press_lambda.png\n');
end

function shadedTrace(t, M, col)
    m = mean(M,1,'omitnan');
    n = sum(isfinite(M),1);
    e = std(M,0,1,'omitnan') ./ sqrt(max(n,1));
    g = isfinite(m) & isfinite(e);
    patch([t(g) fliplr(t(g))], [m(g)+e(g) fliplr(m(g)-e(g))], col, ...
        'FaceAlpha',0.20,'EdgeColor','none');
    plot(t(g), m(g), '-', 'Color', col, 'LineWidth', 1.8);
end