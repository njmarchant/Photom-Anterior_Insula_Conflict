%% conflict_lambda_single_trial.m
% =========================================================================
% SINGLE-TRIAL PROJECTION vs STATE POSTERIOR
%
% Replaces the two-bin (State 1 vs State 2) comparison with a continuous
% within-rat regression. No confidence threshold, no per-state cell-count
% requirement, and every rat contributes.
%
% MODEL
% -------------------------------------------------------------------------
% For each rat, build a fixed reference axis from that rat's own trials:
%
%     Pbar = mean punDS trace      (all trials, this choice condition)
%     Rbar = mean rewDS trace      (all trials, this choice condition)
%     d    = Rbar - Pbar           the punDS -> rewDS axis
%
% Project every INDIVIDUAL conflict trial onto it:
%
%     lambda_t = < C_t - Pbar , d > / < d , d >
%
%     lambda_t = 1  the trial sits on the rewDS reference
%     lambda_t = 0  the trial sits on the punDS reference
%
% Then regress lambda on the trial's state posterior, within rat:
%
%     PRIMARY    lambda_t ~ b0 + b1 * ( P(S1)_t - P(S2)_t )
%     SECONDARY  lambda_t ~ b0 + b1 * P(S1)_t + b2 * P(S2)_t   (S3 = reference)
%
% H1: b1 > 0. Higher State-1 probability -> activity closer to the reward
% reference. Tested across rats on the per-rat slopes.
%
% WHY THIS IS BETTER THAN THE BINNED VERSION
% -------------------------------------------------------------------------
%  - No 0.65 threshold, so the ~2,100 low-confidence trials come back in,
%    weighted by how confident the model actually is.
%  - No requirement for >=5 trials per state per cue, so no rat is dropped
%    for having a sparse cell. n goes from 10 to all rats with an axis.
%  - A per-rat regression slope is far less outlier-prone than a difference
%    of two noisy cell means, which was the failure mode of the distance
%    contrasts.
%  - "Trial-by-trial state probability predicts position on the
%    reward-punishment axis" is a graded claim, and closer to the mixture
%    account than any two-bin comparison.
%
% WHAT TO WATCH
% -------------------------------------------------------------------------
%  - Single-trial photometry is noisy. Noise in lambda is in the DEPENDENT
%    variable and is unbiased, so it costs precision, not validity.
%  - Anchor noise is shared across all trials of a rat, so it rescales that
%    rat's lambda slightly but cannot create a within-rat slope.
%  - If a rat's axis is unreliable (rewDS and punDS profiles indistinguishable)
%    then lambda is meaningless for that rat. The script cross-validates the
%    axis per rat and reports it; set CFG.require_axis to exclude on it.
%
% PREREQUISITE: none. Standalone.
% =========================================================================

clear; close all; clc;

%% --- Configuration ------------------------------------------------------
CFG = struct();
CFG.path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
CFG.path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
                  'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];
CFG.out_dir    = fullfile(pwd, 'lambda_singletrial_output');

CFG.time_window  = linspace(-10, 45, 876);
CFG.windows      = {[0 10], [5 10]};   % primary, then secondary (see note below)
CFG.epochs       = {'Omitted', 'Responded'};

CFG.cue_col = 2; CFG.latency_col = 3; CFG.outcome_col = 4; CFG.trace_col0 = 5;
CFG.latency_tol = 0.1; CFG.min_latency_agree = 0.90;

CFG.min_conflict_trials = 20;   % conflict trials needed to fit a slope
CFG.min_anchor_trials   = 10;   % per anchor
CFG.require_axis        = true; % drop rats whose punDS/rewDS axis is unreliable

% Nuisance controls. Session dummies absorb slow drift and between-session
% differences; trial index absorbs within-session bleaching and satiety.
CFG.control_session  = true;
CFG.control_trialnum = true;

CFG.n_bins = 5;                 % for the visualisation only, not the test
CFG.seed   = 14;

if ~exist(CFG.out_dir,'dir'), mkdir(CFG.out_dir); end
rng(CFG.seed);

fprintf('\n%s\nSINGLE-TRIAL LAMBDA vs STATE POSTERIOR\n%s\n', ...
    repmat('=',1,74), repmat('=',1,74));

%% --- 1. Load ------------------------------------------------------------
fprintf('\n[1] Loading\n');
[TD, QC] = buildTrialData(CFG);
fprintf('    %d rats, %d of %d sessions used\n', ...
    numel(fieldnames(TD)), QC.n_sessions, QC.n_files);
fprintf('    %d trials retained (NO confidence threshold applied)\n', QC.n_trials);
if QC.n_latency_checked > 0
    fprintf('    Latency QC: %d / %d mismatches\n', ...
        QC.n_latency_mismatch, QC.n_latency_checked);
end
if ~isempty(QC.bad_sessions)
    fprintf(2,'    Skipped %d sessions\n', numel(QC.bad_sessions));
end

rats = fieldnames(TD);
allRes = {}; allBins = {};

%% ===================== LOOP OVER EPOCH x WINDOW =========================
for ei = 1:numel(CFG.epochs)
for wi = 1:numel(CFG.windows)

epoch = CFG.epochs{ei};
win   = CFG.windows{wi};
wlab  = sprintf('%g-%gs', win(1), win(2));
ekey  = epochKey(epoch);
widx  = CFG.time_window >= win(1) & CFG.time_window <= win(2);

fprintf('\n%s\n  %s  |  window %s  (%d samples)\n%s\n', ...
    repmat('-',1,74), upper(epoch), wlab, sum(widx), repmat('-',1,74));

rows = {};
for k = 1:numel(rats)
    r = rats{k};
    if ~isfield(TD.(r), ekey), continue; end
    D = TD.(r).(ekey);

    nC = size(D.conf,1);
    if nC < CFG.min_conflict_trials, continue; end
    if size(D.rew,1) < CFG.min_anchor_trials, continue; end
    if size(D.pun,1) < CFG.min_anchor_trials, continue; end

    C = D.conf(:,widx);  Rw = D.rew(:,widx);  Pn = D.pun(:,widx);

    % ---- reference axis, plus a cross-validated check that it is real ----
    Pbar = mean(Pn,1,'omitnan');
    Rbar = mean(Rw,1,'omitnan');
    dvec = Rbar - Pbar;
    axis_d2 = crossnobisD2(Rw, Pn, 200);      % unbiased separation of anchors
    if CFG.require_axis && ~(axis_d2 > 0)
        fprintf('    %-5s skipped: punDS/rewDS axis not separable (cv d2=%.3f)\n', ...
            D.name, axis_d2);
        continue;
    end

    % ---- single-trial projection ------------------------------------------
    denom = dvec * dvec';
    lam = ((C - Pbar) * dvec') / denom;        % nC x 1

    % ---- design matrix ---------------------------------------------------
    contrastP = D.pS1 - D.pS2;
    Xn = [];                                   % nuisance block
    if CFG.control_session
        [~,~,sid] = unique(D.ses);
        for u = 2:max(sid), Xn = [Xn, double(sid==u)]; end %#ok<AGROW>
    end
    if CFG.control_trialnum
        tn = D.trial(:);
        Xn = [Xn, (tn - mean(tn)) / std(tn)]; %#ok<AGROW>
    end

    X1 = [ones(nC,1), contrastP, Xn];
    b1 = X1 \ lam;
    slope_contrast = b1(2);

    X2 = [ones(nC,1), D.pS1, D.pS2, Xn];
    b2 = X2 \ lam;

    % variance explained by the posterior over and above nuisance
    Xn0 = [ones(nC,1), Xn];
    res0 = lam - Xn0*(Xn0\lam);
    res1 = lam - X1 *b1;
    dR2  = 1 - sum(res1.^2)/sum(res0.^2);

    rows(end+1,:) = {D.name, epoch, wlab, nC, size(D.rew,1), size(D.pun,1), ...
        axis_d2, slope_contrast, b2(2), b2(3), dR2, ...
        mean(lam), std(lam)}; %#ok<SAGROW>

    % ---- binned means, for the figure only -------------------------------
    edges = linspace(-1, 1, CFG.n_bins+1);
    for bb = 1:CFG.n_bins
        m = contrastP >= edges(bb) & contrastP < edges(bb+1);
        if bb == CFG.n_bins, m = m | contrastP == 1; end
        if sum(m) >= 3
            allBins(end+1,:) = {D.name, epoch, wlab, bb, ...
                mean(edges(bb:bb+1)), sum(m), mean(lam(m))}; %#ok<SAGROW>
        end
    end
end

if isempty(rows)
    fprintf('    No rats met criteria.\n'); continue;
end

Rt = cell2table(rows, 'VariableNames', {'Rat','Epoch','Window', ...
    'N_Conflict','N_Rew','N_Pun','Axis_cvd2','Slope_contrast', ...
    'Beta_pS1','Beta_pS2','Delta_R2','Lambda_mean','Lambda_sd'});
allRes = [allRes; rows];

fprintf('    n = %d rats | conflict trials %d to %d (total %d)\n', ...
    height(Rt), min(Rt.N_Conflict), max(Rt.N_Conflict), sum(Rt.N_Conflict));

st = signFlipTest(Rt.Slope_contrast, zeros(height(Rt),1), 'greater');
fprintf(['    PRIMARY  slope on [P(S1)-P(S2)]:  mean=%+.4f  med=%+.4f  ' ...
         '%d/%d+\n'], st.mean_diff, st.median_diff, st.n_pos, st.n);
fprintf('             p_mean=%.4f%s   p_median=%.4f   p_sign=%.4f\n', ...
    st.p, pStars(st.p), st.p_median, st.p_sign);
fprintf('             95%% CI [%+.4f, %+.4f]   dz=%.2f\n', ...
    st.ci_lo, st.ci_hi, st.dz);

s1 = signFlipTest(Rt.Beta_pS1, zeros(height(Rt),1), 'greater');
s2 = signFlipTest(Rt.Beta_pS2, zeros(height(Rt),1), 'less');
fprintf(['    SECONDARY  beta P(S1)=%+.4f (p=%.4f, %d/%d+)   ' ...
         'beta P(S2)=%+.4f (p=%.4f)\n'], s1.mean_diff, s1.p, s1.n_pos, ...
         s1.n, s2.mean_diff, s2.p);
fprintf('    Mean extra variance explained by posterior: %.1f%%\n', ...
    100*mean(Rt.Delta_R2));

end
end
%% ===================== END LOOPS ========================================

%% --- Outputs ------------------------------------------------------------
if ~isempty(allRes)
    T = cell2table(allRes, 'VariableNames', {'Rat','Epoch','Window', ...
        'N_Conflict','N_Rew','N_Pun','Axis_cvd2','Slope_contrast', ...
        'Beta_pS1','Beta_pS2','Delta_R2','Lambda_mean','Lambda_sd'});
    writetable(T, fullfile(CFG.out_dir,'lambda_singletrial_per_rat.csv'));
end
if ~isempty(allBins)
    B = cell2table(allBins, 'VariableNames', {'Rat','Epoch','Window', ...
        'Bin','Bin_centre','N_Trials','Lambda_mean'});
    writetable(B, fullfile(CFG.out_dir,'lambda_singletrial_bins.csv'));
    plotSingleTrial(B, T, CFG);
end
fprintf('\nWritten to %s\n', CFG.out_dir);

fprintf(['\n%s\nREADING THIS\n%s\n' ...
  'The slope is the primary result. A positive slope means that the more\n' ...
  'State-1-like a trial is, the closer aIC activity sits to the reward\n' ...
  'reference. Report p_median and p_sign alongside p_mean -- if they agree,\n' ...
  'the effect is not carried by one animal.\n\n' ...
  'The binned panel is illustration only. Monotonic bins are reassuring but\n' ...
  'the test is on the slopes, so do not report bin-wise statistics.\n'], ...
  repmat('=',1,74), repmat('=',1,74));


%% =========================================================================
%  LOCAL FUNCTIONS
%  =========================================================================

function k = epochKey(epoch)
    if strcmp(epoch,'Omitted'), k = 'Omit'; else, k = 'Resp'; end
end

function [TD, QC] = buildTrialData(CFG)
% Keeps each conflict trial's trace TOGETHER WITH its state posterior, and
% collects the rewDS / punDS anchor traces. No confidence threshold.
    T = readtable(CFG.path_excel);
    files = dir(fullfile(CFG.path_data,'*.mat'));
    if isempty(files), error('No .mat files in %s', CFG.path_data); end

    need = {'Prob_State_1','Prob_State_2','Prob_State_3'};
    miss = need(~ismember(need, T.Properties.VariableNames));
    if ~isempty(miss)
        error('CSV lacks %s', strjoin(miss,', '));
    end

    TD = struct();
    QC = struct('n_files',numel(files),'n_sessions',0,'n_trials',0, ...
                'n_latency_checked',0,'n_latency_mismatch',0,'bad_sessions',{{}});

    for i = 1:numel(files)
        S = load(fullfile(CFG.path_data, files(i).name));
        if ~isfield(S,'sesdat'), continue; end
        sd = S.sesdat;
        if ~isfield(sd,'traces_z_10_45'), continue; end

        tr = sd.traces_z_10_45;
        tr = tr(ismember(tr(:,CFG.cue_col),[1 2 3]), :);
        [~,ord] = sort(tr(:,1)); tr = tr(ord,:);

        mask = strcmp(string(T.Rat), string(sd.rat)) & ...
               strcmp(string(T.Session), string(sd.ses));
        sdat = T(mask,:);
        if isempty(sdat), continue; end
        sdat = sortrows(sdat, 'Trial');   % positional indexing below needs this

        if size(tr,1) ~= height(sdat)
            QC.bad_sessions{end+1} = sprintf('%s/%s row count', ...
                string(sd.rat), string(sd.ses));
            continue;
        end

        lat = sdat.Latency; if iscell(lat), lat = cell2mat(lat); end
        cmp = isfinite(lat) & isfinite(tr(:,CFG.latency_col));
        nAg = sum(abs(lat(cmp) - tr(cmp,CFG.latency_col)) <= CFG.latency_tol);
        QC.n_latency_checked  = QC.n_latency_checked + sum(cmp);
        QC.n_latency_mismatch = QC.n_latency_mismatch + (sum(cmp)-nAg);
        if sum(cmp) > 0 && nAg/sum(cmp) < CFG.min_latency_agree
            QC.bad_sessions{end+1} = sprintf('%s/%s latency', ...
                string(sd.rat), string(sd.ses));
            continue;
        end
        QC.n_sessions = QC.n_sessions + 1;

        fld = matlab.lang.makeValidName(char(string(sd.rat)));
        for ek = {'Omit','Resp'}
            if ~isfield(TD, fld) || ~isfield(TD.(fld), ek{1})
                TD.(fld).name = char(string(sd.rat));
                TD.(fld).(ek{1}) = struct('name', char(string(sd.rat)), ...
                    'conf',[], 'rew',[], 'pun',[], ...
                    'pS1',[], 'pS2',[], 'pS3',[], 'ses',{{}}, 'trial',[]);
            end
        end

        for ti = 1:size(tr,1)
            resp = tr(ti,CFG.outcome_col) >= 1;
            ek = 'Omit'; if resp, ek = 'Resp'; end
            seg = tr(ti, CFG.trace_col0:end);

            switch tr(ti, CFG.cue_col)
                case 1
                    TD.(fld).(ek).rew = [TD.(fld).(ek).rew; seg];
                case 2
                    TD.(fld).(ek).pun = [TD.(fld).(ek).pun; seg];
                case 3
                    p1 = sdat.Prob_State_1(ti);
                    p2 = sdat.Prob_State_2(ti);
                    p3 = sdat.Prob_State_3(ti);
                    if ~all(isfinite([p1 p2 p3])), continue; end
                    TD.(fld).(ek).conf  = [TD.(fld).(ek).conf; seg];
                    TD.(fld).(ek).pS1   = [TD.(fld).(ek).pS1; p1];
                    TD.(fld).(ek).pS2   = [TD.(fld).(ek).pS2; p2];
                    TD.(fld).(ek).pS3   = [TD.(fld).(ek).pS3; p3];
                    TD.(fld).(ek).ses{end+1,1} = char(string(sd.ses));
                    TD.(fld).(ek).trial = [TD.(fld).(ek).trial; ti];
            end
            QC.n_trials = QC.n_trials + 1;
        end
    end
end

function d2 = crossnobisD2(A, B, nSplits)
% Cross-validated (unbiased) squared distance between condition means.
% Used here only to confirm each rat's reference axis is real.
    nA = size(A,1); nB = size(B,1);
    if nA < 2 || nB < 2, d2 = NaN; return; end
    T = size(A,2); v = zeros(nSplits,1);
    for s = 1:nSplits
        ia = randperm(nA); ib = randperm(nB);
        ha = floor(nA/2); hb = floor(nB/2);
        d1 = mean(A(ia(1:ha),:),1)     - mean(B(ib(1:hb),:),1);
        d2h= mean(A(ia(ha+1:end),:),1) - mean(B(ib(hb+1:end),:),1);
        v(s) = (d1 * d2h') / T;
    end
    d2 = mean(v);
end

function st = signFlipTest(x1, x2, alternative)
% Paired sign-flip permutation test with robust companions.
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

function plotSingleTrial(B, T, CFG)
% Left: binned lambda vs posterior contrast (illustration).
% Right: per-rat slopes (the actual test).
    combos = unique(B(:,{'Epoch','Window'}));
    nC = height(combos);
    % nC rows x 2 columns: binned illustration on the left, slopes on the right
    figure('Position',[80 80 780 300*nC],'Color','w');

    for c = 1:nC
        ep = string(combos.Epoch(c)); wn = string(combos.Window(c));
        sel = strcmp(string(B.Epoch),ep) & strcmp(string(B.Window),wn);
        Bs = B(sel,:);
        Ts = T(strcmp(string(T.Epoch),ep) & strcmp(string(T.Window),wn), :);

        subplot(nC, 2, c*2-1); hold on;
        rr = unique(string(Bs.Rat));
        for i = 1:numel(rr)
            m = strcmp(string(Bs.Rat), rr(i));
            plot(Bs.Bin_centre(m), Bs.Lambda_mean(m), '-', ...
                'Color',[.75 .75 .75], 'LineWidth',0.8);
        end
        g = grpstats_simple(Bs.Bin_centre, Bs.Lambda_mean);
        errorbar(g(:,1), g(:,2), g(:,3), 'ko-', 'LineWidth',2, ...
            'MarkerFaceColor','k', 'CapSize',10);
        yline(0.5, ':', 'Color',[.4 .4 .4]);
        xlabel('P(State 1) - P(State 2)');
        ylabel('\lambda  (punDS \rightarrow rewDS)');
        title(sprintf('%s | %s', ep, wn), 'FontSize',9);
        set(gca,'Box','off','TickDir','out');

        subplot(nC, 2, c*2); hold on;
        y = Ts.Slope_contrast;
        scatter(ones(numel(y),1)+0.06*randn(numel(y),1), y, 45, ...
            [.35 .35 .35], 'filled', 'MarkerEdgeColor','k');
        plot([0.8 1.2], [mean(y) mean(y)], 'k-', 'LineWidth',3);
        errorbar(1, mean(y), std(y)/sqrt(numel(y)), 'k', 'LineWidth',2, ...
            'CapSize',12);
        yline(0, '--', 'Color',[.6 .6 .6]);
        set(gca,'XTick',[],'XLim',[0.6 1.4],'Box','off','TickDir','out');
        ylabel('per-rat slope');
        title(sprintf('n = %d', numel(y)), 'FontSize',9);
    end
    print(gcf, fullfile(CFG.out_dir,'lambda_singletrial.png'), '-dpng','-r300');
    fprintf('    figure -> lambda_singletrial.png\n');
end

function g = grpstats_simple(x, y)
% mean and SEM of y within each unique x
    u = unique(x);
    g = zeros(numel(u),3);
    for i = 1:numel(u)
        m = x == u(i);
        g(i,:) = [u(i), mean(y(m)), std(y(m))/sqrt(sum(m))];
    end
end