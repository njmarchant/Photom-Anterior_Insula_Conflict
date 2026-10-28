%% ========================================================================
%  HELPER FUNCTION FOR PLOTTING
% =========================================================================
function [sig_windows] = createComparisonPlot(data1, data2, label1, label2, color1, color2, perm_color, plotTitle, time, p_val, thres, y_limits)
    % Creates a standardized plot comparing two datasets.
    % Optionally sets Y-axis limits and returns significant time windows.
    
    % --- Handle Optional Y-Limits ---
    if nargin < 12 || isempty(y_limits)
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
    
    % Permutation tests between conditions remain fully operational with small samples
    [perm.d1_vs_d2, ~] = permTest_array(data1, data2, 1000);
    
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
                repmat({[label1 ' vs ' label2]}, size(win.perm,1), 1)];
            
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