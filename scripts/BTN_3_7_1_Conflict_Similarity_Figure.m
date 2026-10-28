%% plot_similarity_figure.m
% =========================================================================
% THREE-PANEL FIGURE FOR THE CONFLICT SIMILARITY INDEX
%
% Panel A  geometry of lambda, drawn as a schematic
% Panel B  the phenomenon itself: group mean traces per state
% Panel C  the quantification: paired per-rat lambda
%
% Ordering is deliberate -- intuition, then phenomenon, then statistic.
% A reader who has not met a projection coefficient before should be able to
% follow A, see the effect for themselves in B, and only then be asked to
% accept C.
%
% PREREQUISITE
% -------------------------------------------------------------------------
% Run conflict_similarity_index.m first. This script uses:
%     RawData   (in the base workspace)  -- per-rat trials
%     CFG       (in the base workspace)  -- paths and time base
%     similarity_lambda_per_rat.csv      -- written by that script
%
% NOTE ON THE ANCHORS
% -------------------------------------------------------------------------
% rewDS and punDS reference profiles are pooled across states by design, so
% they are IDENTICAL in both sub-panels of B. Only the conflict trace moves.
% That is the point of the figure: a fixed reference axis, with conflict
% shifting along it as a function of latent state. Say so in the legend.
% =========================================================================

if ~exist('RawData','var') || ~exist('CFG','var')
    error(['Run conflict_similarity_index.m first -- this script needs ' ...
           'RawData and CFG in the workspace.']);
end

%% --- Configuration ------------------------------------------------------
FIG = struct();
FIG.window     = '5-10s';        % which lambda result to plot (matches CSV)
FIG.epoch      = 'Omitted';      % 'Omitted' (n=10) or 'Responded' (n=6)
FIG.plot_win    = [-2 10];       % x-range for the trace panels
FIG.shade_win   = [5 10];        % highlighted analysis window
FIG.anchor_states = [1 2];     % must match CFG.anchor_states

c_rew  = [0.12 0.80 0.01];
c_pun  = [0.87 0.01 0.12];
c_conf = [0.01 0.11 0.86];
c_s1   = [0.69 0.70 0.00];
c_s2   = [0.71 0.00 0.70];

switch FIG.epoch
    case 'Omitted',   f_conf = 'Conf_Omit'; f_rew = 'Rew_Omit'; f_pun = 'Pun_Omit';
    case 'Responded', f_conf = 'Conf_Resp'; f_rew = 'Rew_Resp'; f_pun = 'Pun_Resp';
    otherwise, error('FIG.epoch must be Omitted or Responded');
end

%% --- Load the lambda values ---------------------------------------------
lamFile = fullfile(CFG.out_dir, 'similarity_lambda_per_rat.csv');
if ~exist(lamFile, 'file')
    error('Cannot find %s. Re-run conflict_similarity_index.m.', lamFile);
end
L = readtable(lamFile);
sel = strcmp(string(L.Window), FIG.window) & strcmp(string(L.Epoch), FIG.epoch);
L = L(sel, :);
if isempty(L)
    error('No lambda rows for window %s / epoch %s.', FIG.window, FIG.epoch);
end
ratNames = string(L.Rat);
nRats = numel(ratNames);
fprintf('Plotting %s, window %s, n = %d rats\n', FIG.epoch, FIG.window, nRats);

%% --- Collect per-rat mean traces (same rats as the lambda analysis) -----
tw = CFG.time_window;
keep = tw >= FIG.plot_win(1) & tw <= FIG.plot_win(2);
t = tw(keep);

M_rew = nan(nRats, sum(keep));
M_pun = nan(nRats, sum(keep));
M_c1  = nan(nRats, sum(keep));
M_c2  = nan(nRats, sum(keep));

flds = fieldnames(RawData);
for k = 1:nRats
    % map the CSV rat name back onto its RawData field
    fld = '';
    for j = 1:numel(flds)
        if strcmp(string(RawData.(flds{j}).name), ratNames(k))
            fld = flds{j}; break;
        end
    end
    if isempty(fld)
        warning('Rat %s not found in RawData; skipped.', ratNames(k)); continue;
    end

    % anchors: pooled across states, exactly as in the analysis
    A_rew = []; A_pun = [];
    for s = FIG.anchor_states
        A_rew = [A_rew; RawData.(fld).(f_rew).(sprintf('S%d',s))]; %#ok<AGROW>
        A_pun = [A_pun; RawData.(fld).(f_pun).(sprintf('S%d',s))]; %#ok<AGROW>
    end
    M_rew(k,:) = mean(A_rew(:,keep), 1, 'omitnan');
    M_pun(k,:) = mean(A_pun(:,keep), 1, 'omitnan');

    % conflict: per state
    M_c1(k,:) = mean(RawData.(fld).(f_conf).S1(:,keep), 1, 'omitnan');
    M_c2(k,:) = mean(RawData.(fld).(f_conf).S2(:,keep), 1, 'omitnan');
end

%% --- Figure -------------------------------------------------------------
figure('Position',[80 80 1180 520],'Color','w');

% ============================ PANEL A ====================================
% Schematic of the projection. The two conflict points are placed at the
% lambda values actually observed, so the cartoon matches the result.
axA = subplot(2,3,[1 4]); hold(axA,'on');

P = [0.12 0.22];        % punDS reference
R = [0.88 0.78];        % rewDS reference
v = R - P; vn = v / norm(v);
nrm = [-vn(2) vn(1)];   % unit normal

lam1 = mean(L.lambda_S1);
lam2 = mean(L.lambda_S2);
C1 = P + lam1*v + 0.20*nrm;     % State 1 conflict
C2 = P + lam2*v - 0.20*nrm;     % State 2 conflict
F1 = P + lam1*v;                 % projections onto the axis
F2 = P + lam2*v;

% the reference axis
plot(axA, [P(1) R(1)], [P(2) R(2)], '-', 'Color', [.35 .35 .35], 'LineWidth', 2);
% ticks at 0, 0.5, 1
for lv = [0 0.5 1]
    q = P + lv*v;
    plot(axA, q(1)+[-1 1]*0.018*nrm(1), q(2)+[-1 1]*0.018*nrm(2), ...
        '-', 'Color', [.35 .35 .35], 'LineWidth', 1.5);
end

% projections
plot(axA, [C1(1) F1(1)], [C1(2) F1(2)], ':', 'Color', c_s1, 'LineWidth', 1.5);
plot(axA, [C2(1) F2(1)], [C2(2) F2(2)], ':', 'Color', c_s2, 'LineWidth', 1.5);
plot(axA, F1(1), F1(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', c_s1, ...
    'MarkerEdgeColor','k');
plot(axA, F2(1), F2(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', c_s2, ...
    'MarkerEdgeColor','k');

% anchors and conflict points
plot(axA, P(1), P(2), 'o', 'MarkerSize', 13, 'MarkerFaceColor', c_pun, ...
    'MarkerEdgeColor','k','LineWidth',1);
plot(axA, R(1), R(2), 'o', 'MarkerSize', 13, 'MarkerFaceColor', c_rew, ...
    'MarkerEdgeColor','k','LineWidth',1);
plot(axA, C1(1), C1(2), 's', 'MarkerSize', 12, 'MarkerFaceColor', c_conf, ...
    'MarkerEdgeColor', c_s1, 'LineWidth', 2.5);
plot(axA, C2(1), C2(2), 's', 'MarkerSize', 12, 'MarkerFaceColor', c_conf, ...
    'MarkerEdgeColor', c_s2, 'LineWidth', 2.5);

text(axA, P(1)-0.02, P(2)-0.09, 'punDS', 'Color', c_pun, 'FontWeight','bold', ...
    'HorizontalAlignment','center','FontSize',9);
text(axA, R(1)+0.02, R(2)+0.09, 'rewDS', 'Color', c_rew, 'FontWeight','bold', ...
    'HorizontalAlignment','center','FontSize',9);
text(axA, P(1)-0.03, P(2)+0.03, '\lambda = 0', 'FontSize',8, 'Color',[.35 .35 .35]);
text(axA, R(1)-0.10, R(2)+0.02, '\lambda = 1', 'FontSize',8, 'Color',[.35 .35 .35]);
q = P + 0.5*v;
text(axA, q(1)-0.02, q(2)+0.07, '\lambda = 0.5', 'FontSize',8, ...
    'Color',[.35 .35 .35], 'HorizontalAlignment','center');
text(axA, C1(1)+0.04, C1(2), sprintf('conflict | State 1\n\\lambda = %.2f', lam1), ...
    'Color', c_s1, 'FontSize',8.5, 'FontWeight','bold');
text(axA, C2(1)+0.04, C2(2), sprintf('conflict | State 2\n\\lambda = %.2f', lam2), ...
    'Color', c_s2, 'FontSize',8.5, 'FontWeight','bold');

title(axA, {'\bfA'; ...
            'Where does conflict sit on the'; ...
            'punDS \rightarrow rewDS axis?'}, 'FontSize',10);
axis(axA, [-0.05 1.25 -0.05 1.05]); axis(axA,'off');

% ============================ PANEL B ====================================
% The phenomenon. Anchors are identical in both panels by construction;
% only the conflict trace moves.
yl = [min([mean(M_pun,1) mean(M_c1,1) mean(M_c2,1) mean(M_rew,1)]) - 0.35, ...
      max([mean(M_pun,1) mean(M_c1,1) mean(M_c2,1) mean(M_rew,1)]) + 0.45];

for si = 1:2
    ax = subplot(2,3,si*3-1); hold(ax,'on');
    if si == 1, Mc = M_c1; cs = c_s1; else, Mc = M_c2; cs = c_s2; end

    % shaded analysis window, drawn first so it sits behind
    patch(ax, [FIG.shade_win(1) FIG.shade_win(2) FIG.shade_win(2) FIG.shade_win(1)], ...
        [yl(1) yl(1) yl(2) yl(2)], [.94 .94 .88], 'EdgeColor','none');
    plot(ax, [0 0], yl, 'k:', 'LineWidth', 1);

    shadedTrace(ax, t, M_rew,  c_rew);
    shadedTrace(ax, t, M_pun,  c_pun);
    shadedTrace(ax, t, Mc,     c_conf);

    ylim(ax, yl); xlim(ax, FIG.plot_win);
    set(ax,'Box','off','TickDir','out','Layer','top');
    ylabel(ax, 'z-\DeltaF/F');
    if si == 2, xlabel(ax, 'Time from cue onset (s)'); end
    ttl = sprintf('State %d', si);
    title(ax, ttl, 'Color', cs, 'FontSize',10);
    if si == 1
        title(ax, {'\bfB', sprintf('State %d', si)}, 'Color', cs, 'FontSize',10);
        text(ax, FIG.plot_win(1)+0.3, yl(2)-0.15, ...
            sprintf('n = %d rats', nRats), 'FontSize',8, 'Color',[.3 .3 .3]);
        legend(ax, {'','','rewDS','','punDS','','conflict'}, 'Box','off', ...
            'FontSize',8, 'Location','southeast');
    end
end

% ============================ PANEL C ====================================
axC = subplot(2,3,[3 6]); hold(axC,'on');
Y = [L.lambda_S1 L.lambda_S2];

yline(1,   '--', 'rewDS',      'Color', c_rew, 'LabelHorizontalAlignment','left', ...
    'FontSize',8);
yline(0,   '--', 'punDS',      'Color', c_pun, 'LabelHorizontalAlignment','left', ...
    'FontSize',8);
yline(0.5, ':',  'compromise', 'Color', [.4 .4 .4], ...
    'LabelHorizontalAlignment','left', 'FontSize',8);

for r = 1:size(Y,1)
    plot(axC, [1 2], Y(r,:), '-', 'Color', [.7 .7 .7], 'LineWidth', 0.8);
end
scatter(axC, ones(size(Y,1),1),   Y(:,1), 55, c_s1, 'filled', 'MarkerEdgeColor','k');
scatter(axC, 2*ones(size(Y,1),1), Y(:,2), 55, c_s2, 'filled', 'MarkerEdgeColor','k');

m = mean(Y,1,'omitnan');
e = std(Y,0,1,'omitnan') ./ sqrt(sum(isfinite(Y),1));
errorbar(axC, [1 2], m, e, 'LineStyle','none','Color','k','LineWidth',2,'CapSize',14);
plot(axC, [0.80 1.20], [m(1) m(1)], 'k-', 'LineWidth', 3);
plot(axC, [1.80 2.20], [m(2) m(2)], 'k-', 'LineWidth', 3);

nPos = sum(Y(:,1) > Y(:,2));
text(axC, 1.5, max(Y(:))+0.12, sprintf('%d/%d rats', nPos, size(Y,1)), ...
    'HorizontalAlignment','center', 'FontSize',9);

set(axC,'XTick',[1 2],'XTickLabel',{'State 1','State 2'}, ...
    'XLim',[0.6 2.5],'Box','off','TickDir','out');
ylabel(axC, '\lambda   (punDS \rightarrow rewDS)');
title(axC, {'\bfC','Per-rat projection'}, 'FontSize',10);

%% --- Save ---------------------------------------------------------------
outName = fullfile(CFG.out_dir, sprintf('Fig_similarity_%s_%s', ...
    FIG.epoch, strrep(FIG.window,'-','_')));
print(gcf, [outName '.png'], '-dpng', '-r300');
if exist('exportgraphics','file')
    exportgraphics(gcf, [outName '.pdf'], 'ContentType','vector');
end
fprintf('Saved %s.png\n', outName);

fprintf(['\nLegend points to make explicit:\n' ...
         '  - rewDS and punDS profiles pool across states, so they are the\n' ...
         '    SAME in both sub-panels of B. Only conflict moves.\n' ...
         '  - lambda can exceed 1 or fall below 0; conflict is not constrained\n' ...
         '    to lie between the references.\n' ...
         '  - Neither state differs from 0.5, so this is a graded shift along\n' ...
         '    the axis, not categorical switching.\n' ...
         '  - Anchors pooled across states %s; conflict split by state.\n'], ...
         mat2str(FIG.anchor_states));


%% =========================================================================
function shadedTrace(ax, t, M, col)
% Group mean with SEM band across rats.
    m = mean(M, 1, 'omitnan');
    n = sum(isfinite(M), 1);
    e = std(M, 0, 1, 'omitnan') ./ sqrt(max(n,1));
    good = isfinite(m) & isfinite(e);
    tt = t(good); mm = m(good); ee = e(good);
    patch(ax, [tt fliplr(tt)], [mm+ee fliplr(mm-ee)], col, ...
        'FaceAlpha', 0.20, 'EdgeColor','none');
    plot(ax, tt, mm, '-', 'Color', col, 'LineWidth', 1.8);
end