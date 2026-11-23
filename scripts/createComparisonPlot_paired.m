%% ========================================================================
%  HELPER FUNCTION FOR PLOTTING - PAIRED (WITHIN-SUBJECT) VERSION
% =========================================================================
function [sig_windows, common_ids] = createComparisonPlot_paired(data1, data2, ids1, ids2, label1, label2, color1, color2, perm_color, plotTitle, time, p_val, thres, y_limits)
    % Same plot and output as createComparisonPlot, but the two conditions
    % are compared WITHIN subjects:
    %   - ids1 / ids2 are the subject IDs (cellstr) of the rows of data1 / data2
    %   - only subjects with data in BOTH conditions are kept, and rows are
    %     put in the same subject order
    %   - the between-condition test is a paired sign-flip permutation test
    %     (permTest_paired) instead of the unpaired permTest_array
    %   - bootstrapped CIs, means and SEMs are computed on the same subjects
    % Subjects present in only one condition are listed in the command window.
    % Returns the significant windows and the IDs of the subjects used.

    if nargin < 14
        y_limits = [];
    end

    % --- 0. Match subjects across the two conditions ---
    ids1 = cellstr(ids1(:)); ids2 = cellstr(ids2(:));
    if numel(ids1) ~= size(data1, 1) || numel(ids2) ~= size(data2, 1)
        error('createComparisonPlot_paired: number of IDs does not match number of rows of data.');
    end
    [common_ids, i1, i2] = intersect(ids1, ids2, 'stable');
    only1 = setdiff(ids1, common_ids, 'stable');
    only2 = setdiff(ids2, common_ids, 'stable');
    fprintf('Paired comparison "%s": %d subjects in both conditions (%s)\n', ...
        plotTitle, numel(common_ids), strjoin(common_ids', ', '));
    if ~isempty(only1), fprintf('  excluded, only in %s: %s\n', label1, strjoin(only1', ', ')); end
    if ~isempty(only2), fprintf('  excluded, only in %s: %s\n', label2, strjoin(only2', ', ')); end
    data1 = data1(i1, :);
    data2 = data2(i2, :);
    
    % --- Handle Optional Y-Limits ---
    if isempty(y_limits)
        set_manual_ylim = false;
    else
        set_manual_ylim = true;
    end
    
    % --- 1. Prepare Labels and Stats ---
    n1 = size(data1, 1);
    n2 = size(data2, 1);
    full_label1 = sprintf('%s (n=%d)', label1, n1);
    full_label2 = sprintf('%s (n=%d)', label2, n2);
    
    fprintf('Running stats for "%s"...\n', plotTitle);
    
    % Initialize bootstrap variables with default zeros to prevent errors
    btsrp.d1 = zeros(2, size(data1, 2));
    btsrp.d2 = zeros(2, size(data2, 2));
    run_boot1 = false;
    run_boot2 = false;
    
    % Only run bootstrap if sample size satisfies your function's requirement
    if n1 >= 4
        try
            tmp = bootstrap_data(data1, 5000, 0.001);
            if size(tmp, 1) >= 2
                btsrp.d1 = CIadjust(tmp(1,:), tmp(2,:), tmp, n1, 2);
                run_boot1 = true;
            end
        catch
            fprintf('  [!] Warning: Bootstrapping failed for Group 1\n');
        end
    else
        fprintf('  [!] Gated: Group 1 sample size (n=%d) too small for bootstrap. Skipped.\n', n1);
    end
    
    if n2 >= 4
        try
            tmp = bootstrap_data(data2, 5000, 0.001);
            if size(tmp, 1) >= 2
                btsrp.d2 = CIadjust(tmp(1,:), tmp(2,:), tmp, n2, 2);
                run_boot2 = true;
            end
        catch
            fprintf('  [!] Warning: Bootstrapping failed for Group 2\n');
        end
    else
        fprintf('  [!] Gated: Group 2 sample size (n=%d) too small for bootstrap. Skipped.\n', n2);
    end
    clear tmp;
    
    % Paired (sign-flip) permutation test between conditions
    if numel(common_ids) >= 2
        [perm.d1_vs_d2, ~, n_perm, is_exact] = permTest_paired(data1, data2, 1000);
        if is_exact
            fprintf('  paired test: exact, all %d sign patterns (smallest possible p = %.4f)\n', n_perm, 2/n_perm);
        else
            fprintf('  paired test: %d random sign flips\n', n_perm);
        end
    else
        fprintf('  [!] Fewer than 2 subjects in both conditions: no paired test.\n');
        perm.d1_vs_d2 = ones(1, size(data1, 2));
    end
    
    % --- 2. Create the Plot ---
    figure('Name', plotTitle, 'NumberTitle', 'off');
    hold on;
    
    h1 = plot(time, mean(data1, 1), 'Color', color1, 'LineWidth', 1.0);
    jbfill(time, (mean(data1, 1) + std(data1, 0, 1) / sqrt(n1)), ...
                 (mean(data1, 1) - std(data1, 0, 1) / sqrt(n1)), ...
                 color1, 'none', 0, 0.2);
    
    h2 = plot(time, mean(data2, 1), 'Color', color2, 'LineWidth', 1.0);
    jbfill(time, (mean(data2, 1) + std(data2, 0, 1) / sqrt(n2)), ...
                 (mean(data2, 1) - std(data2, 0, 1) / sqrt(n2)), ...
                 color2, 'none', 0, 0.2);
             
    % --- 3. Find & Plot Significance Markers ---
    ax = gca;
    
    % Use manual Y-limits if provided, otherwise get from plot
    if set_manual_ylim
        ylim(y_limits);
    end
    yLimits = ax.YLim;
    yMin = yLimits(1);
    
    % Define offsets for markers
    offsets.boot1_pos = 0.6; offsets.boot1_neg = 0.7;
    offsets.boot2_pos = 0.4; offsets.boot2_neg = 0.5;
    offsets.perm      = 0.2;
    
    % Find significant indices for permutation test safely
    idx.perm = find(perm.d1_vs_d2(1, :) < p_val);
    id.perm  = idx.perm(consec_idx(idx.perm, thres));
    plot(time(id.perm), (yMin + offsets.perm) * ones(1, length(id.perm)), 's', 'MarkerSize', 5, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    win.perm = find_windows_from_indices(id.perm, time);
    
    % Plot Group 1 Bootstrap markers only if executed
    if run_boot1
        idx.boot1_pos = find(btsrp.d1(1,:) > 0);
        idx.boot1_neg = find(btsrp.d1(2,:) < 0);
        id.boot1_pos = idx.boot1_pos(consec_idx(idx.boot1_pos, thres));
        id.boot1_neg = idx.boot1_neg(consec_idx(idx.boot1_neg, thres));
        plot(time(id.boot1_pos), (yMin + offsets.boot1_pos) * ones(1, length(id.boot1_pos)), 's', 'MarkerSize', 5, 'MarkerFaceColor', color1, 'Color', color1);
        plot(time(id.boot1_neg), (yMin + offsets.boot1_neg) * ones(1, length(id.boot1_neg)), 's', 'MarkerSize', 5, 'MarkerFaceColor', color1, 'Color', color1);
        win.boot1_pos = find_windows_from_indices(id.boot1_pos, time);
        win.boot1_neg = find_windows_from_indices(id.boot1_neg, time);
    else
        win.boot1_pos = []; win.boot1_neg = [];
    end
    
    % Plot Group 2 Bootstrap markers only if executed
    if run_boot2
        idx.boot2_pos = find(btsrp.d2(1,:) > 0);
        idx.boot2_neg = find(btsrp.d2(2,:) < 0);
        id.boot2_pos = idx.boot2_pos(consec_idx(idx.boot2_pos, thres));
        id.boot2_neg = idx.boot2_neg(consec_idx(idx.boot2_neg, thres));
        plot(time(id.boot2_pos), (yMin + offsets.boot2_pos) * ones(1, length(id.boot2_pos)), 's', 'MarkerSize', 5, 'MarkerFaceColor', color2, 'Color', color2);
        plot(time(id.boot2_neg), (yMin + offsets.boot2_neg) * ones(1, length(id.boot2_neg)), 's', 'MarkerSize', 5, 'MarkerFaceColor', color2, 'Color', color2);
        win.boot2_pos = find_windows_from_indices(id.boot2_pos, time);
        win.boot2_neg = find_windows_from_indices(id.boot2_neg, time);
    else
        win.boot2_pos = []; win.boot2_neg = [];
    end
    
    % --- 4. Compile and Output Significance Windows ---
    % FIXED: Redundant lines re-running find_windows_from_indices on id.* have been removed here
    
    % Assemble the final output table dynamically
    TestType = [repmat({[label1 ' > Baseline']}, size(win.boot1_pos,1), 1); ...
                repmat({[label1 ' < Baseline']}, size(win.boot1_neg,1), 1); ...
                repmat({[label2 ' > Baseline']}, size(win.boot2_pos,1), 1); ...
                repmat({[label2 ' < Baseline']}, size(win.boot2_neg,1), 1); ...
                repmat({[label1 ' vs ' label2 ' (paired)']}, size(win.perm,1), 1)];
            
    TimeWindows = [win.boot1_pos; win.boot1_neg; win.boot2_pos; win.boot2_neg; win.perm];
    
    % Check if TimeWindows exists and is not empty
    if exist('TimeWindows', 'var') && ~isempty(TimeWindows)
        sig_windows = table(TestType, TimeWindows(:,1), TimeWindows(:,2), ...
            'VariableNames', {'Test', 'StartTime_s', 'EndTime_s'});
    else
        warning('No significant time windows found for this comparison.');
        sig_windows = table({}, [], [], 'VariableNames', {'Test', 'StartTime_s', 'EndTime_s'});
    end
    
    % --- 5. Finalize Plot Aesthetics ---
    line([0, 0], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
    line(ax.XLim, [0, 0], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
    
    xlabel('Time from trial start (s)');
    ylabel('Z-Scored Fluorescence');
    title(plotTitle);
    legend([h1, h2], {full_label1, full_label2}, 'Location', 'northwest', 'Interpreter', 'none');
    
    set(gca, 'FontSize', 12);
    box off;
    hold off;
end