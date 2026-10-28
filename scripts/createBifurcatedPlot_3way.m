function [sig_windows] = createBifurcatedPlot_3way(...
    d1_pellet, d1_shock, ...
    d2_pellet, d2_shock, ...
    d3_pellet, d3_shock, ...
    label1, label2, label3, ...
    color1, color2, color3, ...
    perm_color, plotTitle, time, p_val, thres, y_limits)
    
    % Creates a standardized bifurcated (forked) plot comparing THREE states.
    % Pre-response (T <= 0): A single shared solid line per state.
    % Post-response (T >= 0): Splits into Solid (Pellet) and Dashed (Shock) lines.
    
    if nargin < 18 || isempty(y_limits)
        set_manual_ylim = false;
    else
        set_manual_ylim = true;
    end
    
    % --- 1. Identify Alignment and Sample Sizes ---
    [~, zero_idx] = min(abs(time)); % Index where T = 0
    
    n1_p = size(d1_pellet, 1); n1_s = size(d1_shock, 1);
    n2_p = size(d2_pellet, 1); n2_s = size(d2_shock, 1);
    n3_p = size(d3_pellet, 1); n3_s = size(d3_shock, 1);
    
    % --- 2. Statistical Analysis ---
    % Note: For cross-state statistics, we analyze the primary outcome (Pellet branches)
    fprintf('Running stats for bifurcated plot: "%s"...\n', plotTitle);
    
    tmp = bootstrap_data(d1_pellet, 5000, 0.001);
    btsrp.d1 = CIadjust(tmp(1,:), tmp(2,:), tmp, n1_p, 2);
    tmp = bootstrap_data(d2_pellet, 5000, 0.001);
    btsrp.d2 = CIadjust(tmp(1,:), tmp(2,:), tmp, n2_p, 2);
    tmp = bootstrap_data(d3_pellet, 5000, 0.001);
    btsrp.d3 = CIadjust(tmp(1,:), tmp(2,:), tmp, n3_p, 2);
    clear tmp;
    
    [perm.d1_vs_d2, ~] = permTest_array(d1_pellet, d2_pellet, 1000);
    [perm.d1_vs_d3, ~] = permTest_array(d1_pellet, d3_pellet, 1000);
    [perm.d2_vs_d3, ~] = permTest_array(d2_pellet, d3_pellet, 1000);

    % --- 3. Slice Time & Data Indices ---
    % Slicing vectors overlap at zero_idx so lines connect perfectly without gaps
    idx_pre  = 1:zero_idx;
    idx_post = zero_idx:length(time);
    
    time_pre  = time(idx_pre);
    time_post = time(idx_post);
    
    % --- 4. Render the Plots ---
    figure('Name', plotTitle, 'NumberTitle', 'off');
    hold on;
    
    % ==================== STATE 1 (Orange/Yellow) ====================
    % Pre-press Shared
    m1_pre = mean(d1_pellet(:, idx_pre), 1);
    sem1_pre = std(d1_pellet(:, idx_pre), 0, 1) / sqrt(n1_p + n1_s);
    plot(time_pre, m1_pre, 'Color', color1, 'LineWidth', 1.5);
    jbfill(time_pre, m1_pre + sem1_pre, m1_pre - sem1_pre, color1, 'none', 0, 0.2);
    
    % Post-press Pellet (Solid)
    m1_pel = mean(d1_pellet(:, idx_post), 1);
    sem1_pel = std(d1_pellet(:, idx_post), 0, 1) / sqrt(n1_p);
    h1 = plot(time_post, m1_pel, '-', 'Color', color1, 'LineWidth', 1.5);
    jbfill(time_post, m1_pel + sem1_pel, m1_pel - sem1_pel, color1, 'none', 0, 0.15);
    
    % Post-press Shock (Dashed)
    if n1_s > 0
        m1_shk = mean(d1_shock(:, idx_post), 1);
        sem1_shk = std(d1_shock(:, idx_post), 0, 1) / sqrt(n1_s);
        plot(time_post, m1_shk, '--', 'Color', color1, 'LineWidth', 1.5);
        jbfill(time_post, m1_shk + sem1_shk, m1_shk - sem1_shk, color1, 'none', 0, 0.05); % Lighter shading
    end

    % ==================== STATE 2 (Red/Purple) ====================
    % Pre-press Shared
    m2_pre = mean(d2_pellet(:, idx_pre), 1);
    sem2_pre = std(d2_pellet(:, idx_pre), 0, 1) / sqrt(n2_p + n2_s);
    plot(time_pre, m2_pre, 'Color', color2, 'LineWidth', 1.5);
    jbfill(time_pre, m2_pre + sem2_pre, m2_pre - sem2_pre, color2, 'none', 0, 0.2);
    
    % Post-press Pellet (Solid)
    m2_pel = mean(d2_pellet(:, idx_post), 1);
    sem2_pel = std(d2_pellet(:, idx_post), 0, 1) / sqrt(n2_p);
    h2 = plot(time_post, m2_pel, '-', 'Color', color2, 'LineWidth', 1.5);
    jbfill(time_post, m2_pel + sem2_pel, m2_pel - sem2_pel, color2, 'none', 0, 0.15);
    
    % Post-press Shock (Dashed)
    if n2_s > 0
        m2_shk = mean(d2_shock(:, idx_post), 1);
        sem2_shk = std(d2_shock(:, idx_post), 0, 1) / sqrt(n2_s);
        plot(time_post, m2_shk, '--', 'Color', color2, 'LineWidth', 1.5);
        jbfill(time_post, m2_shk + sem2_shk, m2_shk - sem2_shk, color2, 'none', 0, 0.05);
    end

    % ==================== STATE 3 (Blue) ====================
    % Pre-press Shared
    m3_pre = mean(d3_pellet(:, idx_pre), 1);
    sem3_pre = std(d3_pellet(:, idx_pre), 0, 1) / sqrt(n3_p + n3_s);
    plot(time_pre, m3_pre, 'Color', color3, 'LineWidth', 1.5);
    jbfill(time_pre, m3_pre + sem3_pre, m3_pre - sem3_pre, color3, 'none', 0, 0.2);
    
    % Post-press Pellet (Solid)
    m3_pel = mean(d3_pellet(:, idx_post), 1);
    sem3_pel = std(d3_pellet(:, idx_post), 0, 1) / sqrt(n3_p);
    h3 = plot(time_post, m3_pel, '-', 'Color', color3, 'LineWidth', 1.5);
    jbfill(time_post, m3_pel + sem3_pel, m3_pel - sem3_pel, color3, 'none', 0, 0.15);
    
    % Post-press Shock (Dashed)
    if n3_s > 0
        m3_shk = mean(d3_shock(:, idx_post), 1);
        sem3_shk = std(d3_shock(:, idx_post), 0, 1) / sqrt(n3_s);
        plot(time_post, m3_shk, '--', 'Color', color3, 'LineWidth', 1.5);
        jbfill(time_post, m3_shk + sem3_shk, m3_shk - sem3_shk, color3, 'none', 0, 0.05);
    end

    % --- 5. Significance Markers (Reused layout logic) ---
    ax = gca;
    if set_manual_ylim, ylim(y_limits); end
    yLimits = ax.YLim; yMin = yLimits(1);
    
    offsets.perm_2v3  = 0.1;  offsets.perm_1v3  = 0.2;  offsets.perm_1v2  = 0.3;
    offsets.boot3_pos = 0.5;  offsets.boot3_neg = 0.55;
    offsets.boot2_pos = 0.6;  offsets.boot2_neg = 0.65;
    offsets.boot1_pos = 0.7;  offsets.boot1_neg = 0.75;
    
    idx.boot1_pos = find(btsrp.d1(1,:) > 0);  idx.boot1_neg = find(btsrp.d1(2,:) < 0);
    idx.boot2_pos = find(btsrp.d2(1,:) > 0);  idx.boot2_neg = find(btsrp.d2(2,:) < 0);
    idx.boot3_pos = find(btsrp.d3(1,:) > 0);  idx.boot3_neg = find(btsrp.d3(2,:) < 0);
    
    idx.perm_1v2  = find(perm.d1_vs_d2(1, :) < p_val);
    idx.perm_1v3  = find(perm.d1_vs_d3(1, :) < p_val);
    idx.perm_2v3  = find(perm.d2_vs_d3(1, :) < p_val);
    
    id.boot1_pos = idx.boot1_pos(consec_idx(idx.boot1_pos, thres));
    id.boot1_neg = idx.boot1_neg(consec_idx(idx.boot1_neg, thres));
    id.boot2_pos = idx.boot2_pos(consec_idx(idx.boot2_pos, thres));
    id.boot2_neg = idx.boot2_neg(consec_idx(idx.boot2_neg, thres));
    id.boot3_pos = idx.boot3_pos(consec_idx(idx.boot3_pos, thres));
    id.boot3_neg = idx.boot3_neg(consec_idx(idx.boot3_neg, thres));
    
    id.perm_1v2  = idx.perm_1v2(consec_idx(idx.perm_1v2, thres));
    id.perm_1v3  = idx.perm_1v3(consec_idx(idx.perm_1v3, thres));
    id.perm_2v3  = idx.perm_2v3(consec_idx(idx.perm_2v3, thres));
    
    ms = 5;
    plot(time(id.boot1_pos), (yMin + offsets.boot1_pos) * ones(1, length(id.boot1_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color1, 'Color', color1);
    plot(time(id.boot1_neg), (yMin + offsets.boot1_neg) * ones(1, length(id.boot1_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color1, 'Color', color1);
    plot(time(id.boot2_pos), (yMin + offsets.boot2_pos) * ones(1, length(id.boot2_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color2, 'Color', color2);
    plot(time(id.boot2_neg), (yMin + offsets.boot2_neg) * ones(1, length(id.boot2_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color2, 'Color', color2);
    plot(time(id.boot3_pos), (yMin + offsets.boot3_pos) * ones(1, length(id.boot3_pos)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color3, 'Color', color3);
    plot(time(id.boot3_neg), (yMin + offsets.boot3_neg) * ones(1, length(id.boot3_neg)), 's', 'MarkerSize', ms, 'MarkerFaceColor', color3, 'Color', color3);
    
    plot(time(id.perm_1v2), (yMin + offsets.perm_1v2) * ones(1, length(id.perm_1v2)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    plot(time(id.perm_1v3), (yMin + offsets.perm_1v3) * ones(1, length(id.perm_1v3)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    plot(time(id.perm_2v3), (yMin + offsets.perm_2v3) * ones(1, length(id.perm_2v3)), 's', 'MarkerSize', ms, 'MarkerFaceColor', perm_color, 'Color', perm_color);
    
    % --- 6. Aesthetic Formatting & Clean Legend ---
    line([0, 0], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
    line(ax.XLim, [0, 0], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
    
    xlabel('Time from response execution (s)');
    ylabel('Z-Scored Fluorescence');
    title(plotTitle);
    
    % Build descriptive layout strings for the legend box
    leg1 = sprintf('%s (Pellet n=%d, Shock n=%d)', label1, n1_p, n1_s);
    leg2 = sprintf('%s (Pellet n=%d, Shock n=%d)', label2, n2_p, n2_s);
    leg3 = sprintf('%s (Pellet n=%d, Shock n=%d)', label3, n3_p, n3_s);
    
    % Links the handles specifically to the primary lines to avoid legend redundancy
    legend([h1, h2, h3], {leg1, leg2, leg3}, 'Location', 'northwest', 'Interpreter', 'none');
    
    set(gca, 'FontSize', 12);
    box off;
    hold off;
    sig_windows = []; % Empty placeholder matching function footprint
end