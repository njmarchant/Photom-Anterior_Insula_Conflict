%% ========================================================================
%  HELPER FUNCTION FOR PLOTTING (UPDATED FOR 3 DATASETS)
% =========================================================================
function [sig_windows] = createComparisonPlot_3way(data1, data2, data3, ...
    label1, label2, label3, ...
    color1, color2, color3, ...
    perm_color, plotTitle, time, p_val, thres, y_limits)
    
    % Creates a standardized plot comparing THREE datasets.
    % Runs bootstrapping on all three against baseline.
    % Runs permutation tests on: 1vs2, 1vs3, and 2vs3.
    
    % --- Handle Optional Y-Limits ---
    % Adjusted arg count check for new inputs (total inputs = 15)
    if nargin < 15 || isempty(y_limits)
        set_manual_ylim = false;
    else
        set_manual_ylim = true;
    end
    
    % --- 1. Prepare Labels and Stats ---
    n1 = size(data1, 1);
    n2 = size(data2, 1);
    n3 = size(data3, 1);
    
    full_label1 = sprintf('%s (n=%d)', label1, n1);
    full_label2 = sprintf('%s (n=%d)', label2, n2);
    full_label3 = sprintf('%s (n=%d)', label3, n3);
    
    fprintf('Running stats for "%s"...\n', plotTitle);
    
    % -- Bootstrapping (CI vs Baseline) --
    tmp = bootstrap_data(data1, 5000, 0.001);
    btsrp.d1 = CIadjust(tmp(1,:), tmp(2,:), tmp, n1, 2);
    
    tmp = bootstrap_data(data2, 5000, 0.001);
    btsrp.d2 = CIadjust(tmp(1,:), tmp(2,:), tmp, n2, 2);
    
    tmp = bootstrap_data(data3, 5000, 0.001);
    btsrp.d3 = CIadjust(tmp(1,:), tmp(2,:), tmp, n3, 2);
    clear tmp;
    
    % -- Permutation Tests (Pairwise) --
    [perm.d1_vs_d2, ~] = permTest_array(data1, data2, 1000);
    [perm.d1_vs_d3, ~] = permTest_array(data1, data3, 1000);
    [perm.d2_vs_d3, ~] = permTest_array(data2, data3, 1000);

    % --- 2. Create the Plot ---
    figure('Name', plotTitle, 'NumberTitle', 'off');
    hold on;
    
    % Plot Data 1
    h1 = plot(time, mean(data1, 1), 'Color', color1, 'LineWidth', 1.0);
    jbfill(time, (mean(data1, 1) + std(data1, 0, 1) / sqrt(n1)), ...
                 (mean(data1, 1) - std(data1, 0, 1) / sqrt(n1)), ...
                 color1, 'none', 0, 0.2);
    
    % Plot Data 2
    h2 = plot(time, mean(data2, 1), 'Color', color2, 'LineWidth', 1.0);
    jbfill(time, (mean(data2, 1) + std(data2, 0, 1) / sqrt(n2)), ...
                 (mean(data2, 1) - std(data2, 0, 1) / sqrt(n2)), ...
                 color2, 'none', 0, 0.2);
             
    % Plot Data 3
    h3 = plot(time, mean(data3, 1), 'Color', color3, 'LineWidth', 1.0);
    jbfill(time, (mean(data3, 1) + std(data3, 0, 1) / sqrt(n3)), ...
                 (mean(data3, 1) - std(data3, 0, 1) / sqrt(n3)), ...
                 color3, 'none', 0, 0.2);
             
    % --- 3. Find & Plot Significance Markers ---
    ax = gca;
    
    % Use manual Y-limits if provided, otherwise get from plot
    if set_manual_ylim
        ylim(y_limits);
    end
    yLimits = ax.YLim;
    yMin = yLimits(1);
    
    % Define offsets for markers (Stacked from bottom up)
    % We have many markers now, so we stack them carefully
    % Permutations at the very bottom, Bootstraps above
    offsets.perm_2v3  = 0.2;
    offsets.perm_1v3  = 0.4;
    offsets.perm_1v2  = 0.6;
    
    offsets.boot3_pos = 0.9; offsets.boot3_neg = 0.8;
    offsets.boot2_pos = 1.2; offsets.boot2_neg = 1.1;
    offsets.boot1_pos = 1.5; offsets.boot1_neg = 1.4;

    
    % Find significant indices for BOOTSTRAP
    idx.boot1_pos = find(btsrp.d1(1,:) > 0);
    idx.boot1_neg = find(btsrp.d1(2,:) < 0);
    idx.boot2_pos = find(btsrp.d2(1,:) > 0);
    idx.boot2_neg = find(btsrp.d2(2,:) < 0);
    idx.boot3_pos = find(btsrp.d3(1,:) > 0);
    idx.boot3_neg = find(btsrp.d3(2,:) < 0);
    
    % Find significant indices for PERMUTATION
    idx.perm_1v2  = find(perm.d1_vs_d2(1, :) < p_val);
    idx.perm_1v3  = find(perm.d1_vs_d3(1, :) < p_val);
    idx.perm_2v3  = find(perm.d2_vs_d3(1, :) < p_val);
    
    % Apply consecutive points threshold to ALL
    id.boot1_pos = idx.boot1_pos(consec_idx(idx.boot1_pos, thres));
    id.boot1_neg = idx.boot1_neg(consec_idx(idx.boot1_neg, thres));
    id.boot2_pos = idx.boot2_pos(consec_idx(idx.boot2_pos, thres));
    id.boot2_neg = idx.boot2_neg(consec_idx(idx.boot2_neg, thres));
    id.boot3_pos = idx.boot3_pos(consec_idx(idx.boot3_pos, thres));
    id.boot3_neg = idx.boot3_neg(consec_idx(idx.boot3_neg, thres));
    
    id.perm_1v2  = idx.perm_1v2(consec_idx(idx.perm_1v2, thres));
    id.perm_1v3  = idx.perm_1v3(consec_idx(idx.perm_1v3, thres));
    id.perm_2v3  = idx.perm_2v3(consec_idx(idx.perm_2v3, thres));

    % Plot markers (Squares)
    ms = 5; % Marker Size
    
    % -- Data 1 Markers --
    plot(time(id.boot1_pos), (yMin + offsets.boot1_pos) * ones(1, length(id.boot1_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color1, 'Color', color1);
    plot(time(id.boot1_neg), (yMin + offsets.boot1_neg) * ones(1, length(id.boot1_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color1, 'Color', color1);
    
    % -- Data 2 Markers --
    plot(time(id.boot2_pos), (yMin + offsets.boot2_pos) * ones(1, length(id.boot2_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color2, 'Color', color2);
    plot(time(id.boot2_neg), (yMin + offsets.boot2_neg) * ones(1, length(id.boot2_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color2, 'Color', color2);

    % -- Data 3 Markers --
    plot(time(id.boot3_pos), (yMin + offsets.boot3_pos) * ones(1, length(id.boot3_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color3, 'Color', color3);
    plot(time(id.boot3_neg), (yMin + offsets.boot3_neg) * ones(1, length(id.boot3_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color3, 'Color', color3);
    
    % -- Permutation Markers --
    % Note: You can customize colors here if you want distinct colors for specific comparisons
    plot(time(id.perm_1v2), (yMin + offsets.perm_1v2) * ones(1, length(id.perm_1v2)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    plot(time(id.perm_1v3), (yMin + offsets.perm_1v3) * ones(1, length(id.perm_1v3)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    plot(time(id.perm_2v3), (yMin + offsets.perm_2v3) * ones(1, length(id.perm_2v3)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);

    
    % --- 4. Compile and Output Significance Windows ---
    
    % Get windows from the final significant indices
    win.boot1_pos = find_windows_from_indices(id.boot1_pos, time);
    win.boot1_neg = find_windows_from_indices(id.boot1_neg, time);
    win.boot2_pos = find_windows_from_indices(id.boot2_pos, time);
    win.boot2_neg = find_windows_from_indices(id.boot2_neg, time);
    win.boot3_pos = find_windows_from_indices(id.boot3_pos, time);
    win.boot3_neg = find_windows_from_indices(id.boot3_neg, time);
    
    win.perm_1v2  = find_windows_from_indices(id.perm_1v2, time);
    win.perm_1v3  = find_windows_from_indices(id.perm_1v3, time);
    win.perm_2v3  = find_windows_from_indices(id.perm_2v3, time);

    % Assemble the final output table
    TestType = [repmat({[label1 ' > Baseline']}, size(win.boot1_pos,1), 1); ...
                repmat({[label1 ' < Baseline']}, size(win.boot1_neg,1), 1); ...
                repmat({[label2 ' > Baseline']}, size(win.boot2_pos,1), 1); ...
                repmat({[label2 ' < Baseline']}, size(win.boot2_neg,1), 1); ...
                repmat({[label3 ' > Baseline']}, size(win.boot3_pos,1), 1); ...
                repmat({[label3 ' < Baseline']}, size(win.boot3_neg,1), 1); ...
                repmat({[label1 ' vs ' label2]}, size(win.perm_1v2,1), 1); ...
                repmat({[label1 ' vs ' label3]}, size(win.perm_1v3,1), 1); ...
                repmat({[label2 ' vs ' label3]}, size(win.perm_2v3,1), 1)];
            
    TimeWindows = [win.boot1_pos; win.boot1_neg; 
                   win.boot2_pos; win.boot2_neg; 
                   win.boot3_pos; win.boot3_neg;
                   win.perm_1v2; win.perm_1v3; win.perm_2v3];

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
    
    % Update Legend
    legend([h1, h2, h3], {full_label1, full_label2, full_label3}, 'Location', 'northwest', 'Interpreter', 'none');
    
    set(gca, 'FontSize', 12);
    box off;
    hold off;
end