%% --- Statistical Analysis V3: Grouped by Outcome (State 1,2,3 clustered) ---
%  1. X-Axis: Outcome (Responded, Omitted)
%  2. Colors/Group: States (1, 2, 3)
%  3. QC: Ensures dots (swarm) align perfectly with boxes

% 1. SETUP: Define the Analysis Window
% ---------------------------------------------------------
STAT_WINDOW = [10 40]; % Time in seconds
[~, idx_start] = min(abs(time_window - STAT_WINDOW(1)));
[~, idx_end]   = min(abs(time_window - STAT_WINDOW(2)));

fprintf('Running Stats Window: %.1fs to %.1fs\n', STAT_WINDOW(1), STAT_WINDOW(2));

% Define Colors (from your plotting script)
c_s1 = [0.00, 0.45, 0.74]; % Blue
c_s2 = [0.85, 0.33, 0.10]; % Orange/Red
c_s3 = [0.47, 0.67, 0.19]; % Green

% 2. EXTRACT DATA (Subject Means)
% ---------------------------------------------------------
stats_data = {}; 
cues     = {'Rew', 'Pun', 'Conf'};
states   = {'S1', 'S2', 'S3'};
outcomes = {'Resp', 'Omit'}; % Desired X-axis order
rats     = fieldnames(RawData);

for r = 1:length(rats)
    ratID = rats{r};
    for c = 1:length(cues)
        cue_type = cues{c};
        for s = 1:length(states)
            state_name = states{s};
            for o = 1:length(outcomes)
                outcome_name = outcomes{o};
                
                % Field construction (e.g., Rew_Resp)
                field_name = sprintf('%s_%s', cue_type, outcome_name);
                scalar_val = NaN;
                
                if isfield(RawData.(ratID), field_name) && ...
                   isfield(RawData.(ratID).(field_name), state_name)
                    traces = RawData.(ratID).(field_name).(state_name);
                    if ~isempty(traces)
                        % Subject Mean Calculation
                        mean_trace = mean(traces, 1, 'omitnan');
                        scalar_val = mean(mean_trace(idx_start:idx_end), 'omitnan');
                    end
                end
                
                % Append to list
                stats_data{end+1, 1} = ratID;
                stats_data{end, 2} = cue_type;
                stats_data{end, 3} = state_name;
                stats_data{end, 4} = outcome_name;
                stats_data{end, 5} = scalar_val;
            end
        end
    end
end

% Create Table
T_Stats = cell2table(stats_data, 'VariableNames', {'RatID', 'Cue', 'State', 'Outcome', 'Mean_aIC'});

% ENFORCE ORDERING (Crucial for Plotting)
T_Stats.State = categorical(T_Stats.State, states);       % S1, S2, S3
T_Stats.Outcome = categorical(T_Stats.Outcome, outcomes); % Resp, Omit
T_Stats.Cue = categorical(T_Stats.Cue, cues);

%% 3. VISUALIZATION (Grouped by State)
% ---------------------------------------------------------
plot_cues = {'Rew', 'Pun', 'Conf'};

% Offsets for Swarmplot alignment (to match boxchart dodging)
% When plotting 3 groups, they usually sit at: Center-0.23, Center, Center+0.23
x_offsets = [-0.23, 0, 0.23]; 

for i = 1:length(plot_cues)
    curr_cue = plot_cues{i};
    
    % Filter Data
    mask = T_Stats.Cue == curr_cue;
    T_Sub = T_Stats(mask, :);
    
    % Create Figure
    figure('Name', ['Stats V3: ' curr_cue], 'Color', 'w', 'Position', [100+(i*50) 100 600 500]);
    
    % --- A. BOXPLOT (The Background) ---
    % X-Axis = Outcome, Group = State
    b = boxchart(T_Sub.Outcome, T_Sub.Mean_aIC, 'GroupByColor', T_Sub.State);
    
    % Apply Colors and Style
    b(1).BoxFaceColor = c_s1; b(1).MarkerStyle = 'none'; % Hide outliers (we use swarm)
    b(2).BoxFaceColor = c_s2; b(2).MarkerStyle = 'none';
    b(3).BoxFaceColor = c_s3; b(3).MarkerStyle = 'none';
    
    % Set Transparency so we can see dots
    b(1).BoxFaceAlpha = 0.4;
    b(2).BoxFaceAlpha = 0.4;
    b(3).BoxFaceAlpha = 0.4;
    
    ylabel(['Mean Z-Score (' num2str(STAT_WINDOW(1)) '-' num2str(STAT_WINDOW(2)) 's)']);
    title([curr_cue ' Trials: Grouped by Outcome']);
    grid on; hold on;
    
    % --- B. SWARMPLOT (The Individual Dots) ---
    % We must loop manually to place dots on top of the correct box
    
    % 1. Loop Outcome (X-axis positions: 1=Resp, 2=Omit)
    x_cats = categories(T_Sub.Outcome);
    
    for x_idx = 1:length(x_cats)
        
        % 2. Loop States (Groups: S1, S2, S3)
        g_cats = categories(T_Sub.State);
        
        for g_idx = 1:length(g_cats)
            
            % Filter for specific Outcome AND State
            mask_dots = (T_Sub.Outcome == x_cats{x_idx}) & (T_Sub.State == g_cats{g_idx});
            y_vals = T_Sub.Mean_aIC(mask_dots);
            
            if isempty(y_vals), continue; end
            
            % CALCULATE EXACT X-POSITION
            % Base X (1 or 2) + Offset based on State index
            x_pos = x_idx + x_offsets(g_idx);
            
            % Generate dots 
            scatter_col = [0.2 0.2 0.2]; % Dark Grey dots
            swarmchart(ones(size(y_vals))*x_pos, y_vals, 20, scatter_col, ...
                'filled', 'MarkerFaceAlpha', 0.8, ...
                'XJitter', 'density', 'XJitterWidth', 0.08); 
        end
    end
    
    % Cleanup Legend (Boxchart automatically creates legend for groups)
    legend({'State 1', 'State 2', 'State 3'}, 'Location', 'Best');
    hold off;
end

disp('✅ Plots generated: X-Axis = Outcome, Colors = State.');