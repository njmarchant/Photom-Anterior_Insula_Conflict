%% BTN_2_2_QC_signal_v2.m
%  Signal-vs-noise QC for fibre photometry, pooled per rat across sessions.
%
%  Changes from v1, all prompted by the Conflict_06 R04 run:
%   - Skewness now measured on the LOWPASSED signal. Measuring it before the
%     3 Hz lowpass let symmetric shot noise (most of the variance above 3 Hz
%     at fs ~16 Hz) dilute the asymmetry of real transients, so good rats
%     scored ~0.07.
%   - The 405 self-referenced control is now a DIAGNOSTIC, not a pass/fail
%     criterion. The 490 has the isosbestic regressed out and the 405 has
%     not, so sd490 < sd405 is the expected result when the correction is
%     working. v1 flagged almost every rat on this.
%   - Event-locked test now uses the SAME baseline as your analysis scripts
%     (-25 to -20 s), not -5 to 0. In v1 the baseline sat on the rising edge
%     of the response and subtracted most of it away.
%   - Trials are POOLED PER RAT across sessions before testing. One session
%     of ~60 trials has almost no power against a max-statistic null; your
%     figures average ~5 sessions x 7 rats.
%   - Two new motion-artefact tests: waveform-shape correlation between the
%     490 and 405 PETHs, and a residual PETH after regressing the 405 dF/F
%     out of the 490 dF/F (a stricter correction than controlfit alone).
%   - Verdict is now two-stage: Stage A asks "is there signal in this fibre
%     at all", Stage B asks "is any of it time-locked". Stage B is only
%     interpreted if Stage A passes.
%
%  Requires Signal Processing Toolbox and the project functions
%  controlfit, deltaFF, hpFilter, lpFilter.

clear all; close all;

%% ============================== CONFIG ================================
tankfolder   = 'C:\Photometry\Conflict_06\Pun';
% use_sessions = {'R01','R02','R03','R04','R05'};   % {} = all
use_sessions = {};   % {} = all
use_rats     = {'R01','R02','R03','R04','R05','R07','R08'};  % {} = all

exc            = 100;    % seconds cut at start in BTN_1 (MUST match)
lowpass_cutoff = 3;
filt_steepness = 0.95;
db_atten       = 90;

% Event-locked test: match your analysis windows exactly
event_code   = 5;        % 1 rewDS 2 punDS 3 conflict 4 press 5 food 6 shock
qc_pre       = 25;       % s before event
qc_post      = 15;       % s after
base_win     = [-25 -20];% baseline, same as the z-scoring in BTN_2_1
resp_win     = [0 15];   % response window to test
nShuffle     = 1000;

% Optional manual artefact windows, same format as BTN_2_3_Exclude_sections
% {'filename.mat', [start_s end_s]; ...}   times in post-exclusion seconds
exclude_list = {};

saveFigs = false;
figDir   = fullfile(tankfolder, 'QC');

%% ===================== PASS 1: per-session processing =================
files = dir(fullfile(tankfolder, '*.mat'));
SES   = struct([]);

for i = 1:numel(files)

    S = load(fullfile(tankfolder, files(i).name));
    if ~isfield(S,'sesdat'), continue; end
    sd = S.sesdat; clear S

    rat = char(getfielddef(sd,'rat','?'));
    ses = char(getfielddef(sd,'ses','?'));
    if ~isempty(use_rats)     && ~ismember(rat, use_rats),     continue; end
    if ~isempty(use_sessions) && ~ismember(ses, use_sessions), continue; end

    % ---- raw channels on a common post-exclusion time base ------------
    if isfield(sd,'raw490') && isfield(sd,'raw405')
        raw490 = double(sd.raw490(:)); raw405 = double(sd.raw405(:));
        fs = sd.conversion;
        c  = max(1, ceil(fs*exc));
        w490 = raw490(c:end); w405 = raw405(c:end);
    elseif isfield(sd,'filt490')
        w490 = double(sd.filt490(:)); w405 = double(sd.filt405(:));
        raw490 = w490; raw405 = w405; fs = sd.conversion;
    else
        fprintf('%s: no raw channels, skipped\n', files(i).name); continue
    end
    n = min(numel(w490), numel(w405));
    w490 = w490(1:n); w405 = w405(1:n);
    ts   = (0:n-1)'/fs;  dur = n/fs;

    % ---- pipeline, keeping the pre-lowpass signal for the spectrum ----
    cf     = controlfit(w490, w405);
    dff    = deltaFF(w490, cf); dff = dff(:);
    [hp490, ~]      = hpFilter(ts, dff);
    lp490           = lpFilter(hp490, fs, lowpass_cutoff, filt_steepness, db_atten);
    [hp405, mov405] = hpFilter(ts, w405);
    dff405          = 100*hp405./mov405;
    lp405           = lpFilter(dff405, fs, lowpass_cutoff, filt_steepness, db_atten);

    % ---- stricter correction: regress the 405 dF/F out of the 490 -----
    % If a response survives this it is very unlikely to be motion.
    pr    = polyfit(lp405, lp490, 1);
    if pr(1) > 0
        lpres = lp490 - polyval(pr, lp405);
    else
        lpres = lp490;                 % no positive coupling, nothing to remove
    end

    % ---- manual artefact windows -> NaN (applied AFTER filtering) -----
    if ~isempty(exclude_list)
        hit = strcmp(exclude_list(:,1), files(i).name);
        for e = find(hit)'
            wnd = exclude_list{e,2};
            k = ts >= wnd(1) & ts <= min(wnd(2), ts(end));
            lp490(k) = NaN; lp405(k) = NaN; lpres(k) = NaN;
        end
    end

    % ============================ METRICS =============================
    m = struct();
    m.rat = string(rat); m.ses = string(ses);
    m.fs = fs; m.dur_min = dur/60;

    % -- Stage A metric 1: raw light level and photobleaching ----------
    k = max(1, round(0.1*numel(raw490)));
    m.mean490 = mean(raw490); m.mean405 = mean(raw405);
    m.ratio_490_405 = m.mean490/m.mean405;
    m.bleach490_pct = 100*(median(raw490(1:k))-median(raw490(end-k+1:end)))/median(raw490(1:k));
    m.bleach405_pct = 100*(median(raw405(1:k))-median(raw405(end-k+1:end)))/median(raw405(1:k));
    m.pinned_pct = 100*mean(w490 <= min(w490)+eps | w490 >= max(w490)-eps);

    % -- Stage A metric 2: isosbestic regression -----------------------
    p = polyfit(w405, w490, 1);
    m.fit_slope = p(1);
    m.fit_R2    = 1 - var(w490 - polyval(p, w405))/var(w490);

    % -- Stage A metric 3: dF/F magnitude ------------------------------
    m.sd_dFF490 = std(lp490, 'omitnan');
    m.sd_dFF405 = std(lp405, 'omitnan');
    m.sd_ratio  = m.sd_dFF490/m.sd_dFF405;   % diagnostic only, not a flag

    % -- Stage A metric 4: spectrum, measured BEFORE the lowpass -------
    win = min(numel(hp490), round(60*fs));
    [pxx,f] = pwelch(hp490,  hamming(win), round(win/2), [], fs);
    [pxc,~] = pwelch(dff405-mean(dff405), hamming(win), round(win/2), [], fs);
    nyq = fs/2;
    sel = f>=0.15 & f<=0.9*nyq & pxx>0;
    ps  = polyfit(log10(f(sel)), log10(pxx(sel)), 1);  m.spec_slope     = ps(1);
    ps4 = polyfit(log10(f(sel)), log10(pxc(sel)), 1);  m.spec_slope_405 = ps4(1);
    loB = f>=0.1 & f<=2;  hiB = f>=0.6*nyq & f<=0.95*nyq;
    m.LF_HF_dB = 10*log10(mean(pxx(loB))/mean(pxx(hiB)));

    % -- Stage A metric 5: skew, measured AFTER the lowpass ------------
    m.skew490 = skew_(lp490);
    m.skew405 = skew_(lp405);

    % -- Stage A metric 6: transients above the noise floor ------------
    [r490, a490] = transientRate(lp490, fs);
    [r405, ~]    = transientRate(lp405, fs);
    m.trans_rate490 = r490; m.trans_rate405 = r405;
    m.trans_ratio   = r490/max(r405, eps);
    m.trans_amp_med = a490;

    % -- z-scoring sanity: per-trial baseline SD -----------------------
    m.med_baseSD = NaN; m.frac_tinySD = NaN; m.max_absz = NaN;
    upd = firstFieldStarting(sd, 'traces_updated_');
    if ~isempty(upd)
        A = sd.(upd); tv = linspace(-parseWin(upd,1), parseWin(upd,2), size(A,2)-4);
        b  = tv >= -parseWin(upd,1) & tv <= -parseWin(upd,1)+5;
        sds = std(A(:,5:end), 0, 2, 'omitnan');   % placeholder if b empty
        sds = std(A(:,[false(1,4) b]), 0, 2, 'omitnan');
        m.med_baseSD  = median(sds, 'omitnan');
        m.frac_tinySD = mean(sds < 0.25*m.med_baseSD);
    end
    zf = firstFieldStarting(sd, 'traces_z_');
    if ~isempty(zf)
        zz = sd.(zf)(:,5:end); m.max_absz = max(abs(zz(:)), [], 'omitnan');
    end

    % ---- stash what pass 2 needs -------------------------------------
    evt = [];
    if ~isempty(zf)
        E = sd.(zf); evt = E(E(:,2)==event_code, 1);
    end

    m.file = string(files(i).name);
    e = numel(SES)+1;
    SES(e).m = m; SES(e).rat = rat; SES(e).ses = ses; SES(e).fs = fs;
    SES(e).lp490 = lp490; SES(e).lp405 = lp405; SES(e).lpres = lpres;
    SES(e).evt = evt; SES(e).n = n;

    fprintf('%-45s %s/%s  bleach %5.1f%%  sd %5.2f  slope %5.2f  skew %5.2f\n', ...
        files(i).name, rat, ses, m.bleach490_pct, m.sd_dFF490, m.spec_slope, m.skew490);

    clear sd
end

if isempty(SES), error('No sessions matched the rat/session filters.'); end

%% ===================== PASS 2: pool per rat, test ====================
rats = unique({SES.rat});
RES  = [];

for r = 1:numel(rats)
    ratID = rats{r};
    idxS  = find(strcmp({SES.rat}, ratID));

    % --- aggregate Stage A metrics (median across sessions) -----------
    M = struct2table(arrayfun(@(x) x.m, SES(idxS)));
    q = struct();
    q.rat = string(ratID);
    q.nSessions = numel(idxS);
    for fn = {'bleach490_pct','bleach405_pct','ratio_490_405','pinned_pct', ...
              'fit_slope','fit_R2','sd_dFF490','sd_dFF405','sd_ratio', ...
              'spec_slope','spec_slope_405','LF_HF_dB','skew490','skew405', ...
              'trans_rate490','trans_ratio','max_absz','frac_tinySD'}
        q.(fn{1}) = median(M.(fn{1}), 'omitnan');
    end

    % --- build pooled PETHs -------------------------------------------
    fs   = SES(idxS(1)).fs;
    pre_s  = round(qc_pre*fs); post_s = round(qc_post*fs);
    tvec   = (-pre_s:post_s)/fs;
    bW     = tvec >= base_win(1) & tvec <= base_win(2);
    rW     = tvec >= resp_win(1) & tvec <= resp_win(2);

    P490 = []; P405 = []; PRES = []; sessOfTrial = []; IDX = cell(1,numel(idxS));
    for s = 1:numel(idxS)
        E = SES(idxS(s));
        idx = pethIndex(E.evt, fs, E.n, qc_pre, qc_post);
        IDX{s} = idx;
        if isempty(idx), continue; end
        P490 = [P490; baseSub(E.lp490(idx), bW)]; %#ok<AGROW>
        P405 = [P405; baseSub(E.lp405(idx), bW)]; %#ok<AGROW>
        PRES = [PRES; baseSub(E.lpres(idx), bW)]; %#ok<AGROW>
        sessOfTrial = [sessOfTrial; s*ones(size(idx,1),1)]; %#ok<AGROW>
    end

    q.nTrials = size(P490,1);
    q.evoked = NaN; q.evoked405 = NaN; q.evoked_resid = NaN;
    q.shape_corr = NaN; q.evoked_z = NaN; q.evoked_p = NaN; q.splithalf_r = NaN;
    nulldist = [];

    if q.nTrials >= 20
        m490 = mean(P490,1,'omitnan');
        m405 = mean(P405,1,'omitnan');
        mres = mean(PRES,1,'omitnan');

        [q.evoked, pk] = maxabs(m490(rW));
        q.evoked405    = maxabs(m405(rW));
        q.evoked_resid = maxabs(mres(rW));
        q.resid_frac   = q.evoked_resid / max(q.evoked, eps);

        % motion test 1: do the 490 and 405 event waveforms have the same shape?
        cc = corrcoef(m490(rW), m405(rW)); q.shape_corr = cc(1,2);

        % motion test 2 is q.resid_frac above (survives 405 regression?)

        % --- pooled circular-shift null, each session shifted separately
        nulldist = zeros(nShuffle,1);
        for sh = 1:nShuffle
            acc = [];
            for s = 1:numel(idxS)
                if isempty(IDX{s}), continue; end
                E = SES(idxS(s));
                sidx = mod(IDX{s} + randi(E.n) - 1, E.n) + 1;
                acc = [acc; baseSub(E.lp490(sidx), bW)]; %#ok<AGROW>
            end
            mm = mean(acc,1,'omitnan');
            nulldist(sh) = maxabs(mm(rW));
        end
        q.evoked_z = (q.evoked - mean(nulldist))/std(nulldist);
        q.evoked_p = (1 + sum(nulldist >= q.evoked))/(nShuffle + 1);

        % --- split-half reliability of the mean waveform ---------------
        o = mean(P490(1:2:end,:),1,'omitnan');
        e = mean(P490(2:2:end,:),1,'omitnan');
        cc = corrcoef(o(rW), e(rW)); q.splithalf_r = cc(1,2);
    end

    %% ------------------------- TWO-STAGE VERDICT ---------------------
    % STAGE A - is there fluorescence-derived signal in this fibre at all?
    % Each criterion is independent of the others; that is the point.
    A = struct();
    A.bleaching   = q.bleach490_pct >= 10;    % fluorophore is actually bleaching
    A.dFF_size    = q.sd_dFF490     >= 0.40;  % dF/F excursions above noise floor
    A.spectrum    = q.spec_slope    <= -0.80; % 1/f, not white
    A.skewness    = q.skew490       >=  0.20; % asymmetric transients
    A.fit_ok      = q.fit_slope     >   0;    % controlfit did not force a=1
    A.no_clipping = q.pinned_pct    <   0.5;
    stageA = sum(struct2array(A));
    if     stageA >= 5, q.signal = "GOOD";
    elseif stageA >= 3, q.signal = "MARGINAL";
    else,               q.signal = "NO SIGNAL";
    end
    q.stageA_score = stageA;

    % STAGE B - is any of it time-locked, and is it biological?
    B = struct();
    B.locked    = ~isnan(q.evoked_p)   && q.evoked_p   < 0.05;
    B.reliable  = ~isnan(q.splithalf_r)&& q.splithalf_r> 0.30;
    B.not_shape = ~isnan(q.shape_corr) && q.shape_corr < 0.70;
    B.survives  = ~isnan(q.resid_frac) && q.resid_frac > 0.50;
    stageB = sum(struct2array(B));
    if q.signal == "NO SIGNAL"
        q.locking = "n/a";
    elseif stageB >= 4, q.locking = "TIME-LOCKED";
    elseif stageB >= 2, q.locking = "WEAK / CHECK ARTEFACT";
    else,               q.locking = "NOT TIME-LOCKED";
    end
    q.stageB_score = stageB;

    printRat(q, A, B);
    RES = [RES; struct2table(q)]; %#ok<AGROW>

    %% ---------------------------- FIGURE -----------------------------
    fh = figure('Name', ['QC ' ratID], 'Position', [50 50 1400 800]);
    tl = tiledlayout(2,3,'TileSpacing','compact');
    title(tl, sprintf('Rat %s | %d sessions, %d trials | Stage A: %s (%d/6)  Stage B: %s (%d/4)', ...
        ratID, q.nSessions, q.nTrials, q.signal, stageA, q.locking, stageB));

    % 1. example session dF/F
    nexttile; E = SES(idxS(1));
    plot((0:E.n-1)/E.fs/60, E.lp490, 'Color',[0 .45 .74]); hold on
    plot((0:E.n-1)/E.fs/60, E.lp405 - 6*q.sd_dFF490, 'Color',[.6 .2 .8]);
    xlabel('min'); ylabel('% dF/F'); legend({'490','405 (offset)'},'Location','best');
    title(sprintf('session %s | sd %.2f vs %.2f', E.ses, q.sd_dFF490, q.sd_dFF405));

    % 2. spectrum (last session computed)
    nexttile; loglog(f, pxx, 'Color',[0 .45 .74]); hold on; loglog(f, pxc, 'Color',[.6 .2 .8]);
    xline(lowpass_cutoff,'k:'); xlabel('Hz'); ylabel('PSD');
    title(sprintf('slope %.2f (white = 0)', q.spec_slope));

    % 3. amplitude distribution of the lowpassed signal
    nexttile; hold on
    histogram(zscore_(E.lp490), 80, 'Normalization','pdf','FaceColor',[0 .45 .74],'EdgeColor','none');
    xx = linspace(-5,6,200); plot(xx, exp(-xx.^2/2)/sqrt(2*pi),'k--');
    xlim([-5 6]); xlabel('normalised dF/F'); title(sprintf('skew %.2f', q.skew490));

    % 4. pooled PETH: signal, control, residual
    nexttile; hold on
    if ~isempty(P490)
        shadeMean(tvec, P490, [0 .45 .74]);
        shadeMean(tvec, P405, [.6 .2 .8]);
        plot(tvec, mean(PRES,1,'omitnan'), 'k-', 'LineWidth',1);
        xline(0,'k--'); yline(0,'k:');
        patch([base_win fliplr(base_win)], [ylim fliplr(ylim)], [.9 .9 .9], ...
              'FaceAlpha',.3,'EdgeColor','none','HandleVisibility','off');
        xlabel('time from event (s)'); ylabel('% dF/F');
        legend({'','490','','405 control','405-regressed residual'},'Location','best');
        title(sprintf('490 %.3f | 405 %.3f | resid %.3f%%', q.evoked, q.evoked405, q.evoked_resid));
    end

    % 5. circular-shift null
    nexttile;
    if ~isempty(nulldist)
        histogram(nulldist, 40, 'FaceColor',[.7 .7 .7],'EdgeColor','none'); hold on
        xline(q.evoked, 'r','LineWidth',2);
        xlabel('peak of shifted-event mean (% dF/F)');
        title(sprintf('z = %.1f, p = %.3f', q.evoked_z, q.evoked_p));
    else
        axis off; text(.5,.5,'too few trials','HorizontalAlignment','center');
    end

    % 6. split-half
    nexttile; hold on
    if ~isempty(P490)
        plot(tvec, mean(P490(1:2:end,:),1,'omitnan'), 'Color',[0 .45 .74]);
        plot(tvec, mean(P490(2:2:end,:),1,'omitnan'), 'Color',[.2 .7 .3]);
        xline(0,'k--'); legend({'odd trials','even trials'},'Location','best');
        xlabel('time from event (s)'); ylabel('% dF/F');
        title(sprintf('split-half r = %.2f | shape corr with 405 = %.2f', ...
            q.splithalf_r, q.shape_corr));
    end

    if saveFigs
        if ~isfolder(figDir), mkdir(figDir); end
        exportgraphics(fh, fullfile(figDir, sprintf('QCv2_%s.png', ratID)), 'Resolution',150);
    end
end

%% ============================= SUMMARY ================================
disp(' ');
disp(RES(:, {'rat','nSessions','nTrials','bleach490_pct','sd_dFF490','spec_slope', ...
             'skew490','fit_slope','stageA_score','signal', ...
             'evoked','evoked405','resid_frac','shape_corr','evoked_p', ...
             'splithalf_r','stageB_score','locking'}));
writetable(RES, fullfile(tankfolder,'QC_summary_v2.csv'));
fprintf('\nWrote %s\n', fullfile(tankfolder,'QC_summary_v2.csv'));

fprintf(['\nHow to read this:\n' ...
    '  Stage A is about the fibre, not the task. A rat failing Stage A should be\n' ...
    '  excluded before any behavioural analysis, and its Stage B result ignored.\n' ...
    '  Stage B distinguishes a real time-locked response from movement artefact:\n' ...
    '  resid_frac is the fraction of the response surviving regression of the 405\n' ...
    '  dF/F out of the 490, and shape_corr is how similar the 490 and 405 event\n' ...
    '  waveforms are. High shape_corr with low resid_frac means artefact.\n' ...
    '  Calibrate all thresholds against a known-good rat and a dead control\n' ...
    '  (patch cord in a dark box, or a no-virus animal).\n']);

%% ========================= LOCAL FUNCTIONS ============================
function idx = pethIndex(evt, fs, n, pre, post)
    pre_s = round(pre*fs); post_s = round(post*fs);
    idx = [];
    for k = 1:numel(evt)
        c = round(evt(k)*fs);
        if c-pre_s >= 1 && c+post_s <= n
            idx(end+1,:) = (c-pre_s):(c+post_s); %#ok<AGROW>
        end
    end
end

function M = baseSub(M, bW)
    M = M - mean(M(:,bW), 2, 'omitnan');
end

function [v, i] = maxabs(x)
    [~, i] = max(abs(x)); v = x(i);
end

function [rate, ampMed] = transientRate(x, fs)
    x = x(~isnan(x));
    rsd = 1.4826*median(abs(x - median(x)));
    [pk, ~] = findpeaks(x, fs, 'MinPeakHeight', median(x)+2*rsd, 'MinPeakDistance', 0.5);
    rate = numel(pk)/(numel(x)/fs);
    ampMed = median(pk);
end

function s = skew_(x)
    x = x(~isnan(x)); x = x - mean(x);
    s = mean(x.^3)/(mean(x.^2)^1.5);
end

function z = zscore_(x)
    z = (x - mean(x,'omitnan'))/std(x,'omitnan');
end

function shadeMean(t, M, c)
    m = mean(M,1,'omitnan');
    e = std(M,0,1,'omitnan')/sqrt(size(M,1));
    fill([t fliplr(t)], [m+e fliplr(m-e)], c, 'FaceAlpha',.25,'EdgeColor','none');
    plot(t, m, 'Color', c, 'LineWidth', 1.5);
end

function v = getfielddef(s, f, d)
    if isfield(s,f), v = s.(f); else, v = d; end
end

function f = firstFieldStarting(s, pre)
    fn = fieldnames(s); k = find(startsWith(fn, pre), 1);
    if isempty(k), f = ''; else, f = fn{k}; end
end

function v = parseWin(name, which)
    t = regexp(name, '_(\d+)_(\d+)$', 'tokens');
    if isempty(t), v = NaN; else, v = str2double(t{1}{which}); end
end

function printRat(q, A, B)
    fprintf('\n---------------- Rat %s (%d sessions, %d trials) ----------------\n', ...
        q.rat, q.nSessions, q.nTrials);
    fprintf('  STAGE A  %s  (%d/6)\n', q.signal, q.stageA_score);
    fprintf('     bleaching   %s  %.1f%%\n',  tick(A.bleaching),   q.bleach490_pct);
    fprintf('     dF/F size   %s  SD %.2f%%\n', tick(A.dFF_size),  q.sd_dFF490);
    fprintf('     spectrum    %s  slope %.2f\n', tick(A.spectrum), q.spec_slope);
    fprintf('     skewness    %s  %.2f\n',     tick(A.skewness),   q.skew490);
    fprintf('     iso fit     %s  slope %.2f, R2 %.2f\n', tick(A.fit_ok), q.fit_slope, q.fit_R2);
    fprintf('     no clipping %s  %.2f%%\n',   tick(A.no_clipping), q.pinned_pct);
    fprintf('  STAGE B  %s  (%d/4)\n', q.locking, q.stageB_score);
    fprintf('     time-locked %s  z %.1f, p %.3f\n', tick(B.locked),   q.evoked_z, q.evoked_p);
    fprintf('     reliable    %s  split-half r %.2f\n', tick(B.reliable), q.splithalf_r);
    fprintf('     not 405shape%s  shape corr %.2f\n', tick(B.not_shape), q.shape_corr);
    fprintf('     survives405 %s  resid %.0f%% of response\n', tick(B.survives), 100*q.resid_frac);
    if q.frac_tinySD > 0.05
        fprintf('     [!] %.0f%% of trials have a very small baseline SD - z-scores in\n', 100*q.frac_tinySD);
        fprintf('         traces_z will be inflated for those trials (max |z| = %.1f)\n', q.max_absz);
    end
end

function s = tick(b)
    if b, s = ' PASS'; else, s = ' FAIL'; end
end