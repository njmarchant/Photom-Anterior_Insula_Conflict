%% HMM Model Integration: Alcohol vs Saline Photometry Comparison
%  Goal: Compare Saline vs Alcohol_High neural traces across States 1, 2, and 3
%  Excludes the first 15 mins of sedation.
clear all; close all; clc;

%% --- 1. Configuration & Setup ---
% Paths
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)';
path_csv   = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Conflict_02_Alc_tests_UPDATED_v2_with_Probabilities.csv';

% Analysis Parameters
time_window = linspace(-10, 10, 319); % Adjust based on your trace length
p_val = 0.05;
y_lims = [-2 5]; 

% Threshold Settings
min_trials_threshold = 2; 
exclude_first_15_mins = true; % Toggle to ignore the "too drunk" phase (Timestamp < 900)

% Colors
c_saline = [0.00, 0.45, 0.74]; % Blue for Saline
c_alcohol = [0.85, 0.33, 0.10]; % Red/Orange for Alcohol High
c_perm = [0.5, 0.5, 0.5];  

%% --- 2. Load and Clean CSV Data ---
fprintf('Loading CSV Data...\n');
try
    T = readtable(path_csv, 'TextType', 'string');
catch ME
    error('Failed to load CSV file. Check path.\nError: %s', ME.message);
end

% --- The Cleaning Block ---
% We must ensure Rat IDs, Dates, and Sessions match the .mat files exactly.
clean_rats = strings(height(T), 1);
for i = 1:height(T)
    val = regexprep(string(T.Rat(i)), '\D', ''); % Extract only numbers
    if ~isempty(val) && strlength(val) > 0
        num_val = str2double(val);
        if num_val < 10
            clean_rats(i) = sprintf('R0%d', num_val);
        else
            clean_rats(i) = sprintf('R%d', num_val); 
        end
    else
        clean_rats(i) = string(T.Rat(i)); % Fallback if no numbers found
    end
end
T.Rat = clean_rats;
T.Session_Type = strtrim(string(T.Session_Type)); % Trims invisible trailing spaces
T.Date = strtrim(string(T.Date));

fprintf('✅ CSV loaded and cleaned. Rows: %d\n', height(T));

%% --- 3. Data Extraction & Quality Control ---
fprintf('Processing Files & Extracting Traces...\n');
files = dir(fullfile(path_data, '*.mat'));

% --- Dynamic Target Groups ---
% Automatically generate all required conditions across States 1, 2, and 3
base_conditions = {'Rew_Resp', 'Pun_Resp', 'Pun_Omit', 'Conf_Resp', 'Conf_Omit'};
states_to_analyze = [1, 2, 3];
target_groups = {};

for c = 1:length(base_conditions)
    for s = states_to_analyze
        target_groups{end+1} = sprintf('%s_S%d', base_conditions{c}, s);
    end
end
                 
sessions_to_compare = {'Saline', 'Alcohol_High'};
RawData = struct(); 
mismatch_count = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = strrep(string(sesdat.rat), "'", ""); 
    session = strtrim(string(sesdat.ses));
    
    if isfield(sesdat, 'date')
        d1 = strtrim(string(sesdat.date));
    else
        fprintf('  [!] WARNING: No date found in %s, skipping.\n', filename);
        continue;
    end
    
    if ~ismember(session, sessions_to_compare), continue; end
    
    traces = sesdat.traces_z; 
    
    % Initialize Rat fields dynamically
    if ~isfield(RawData, rat)
        for g = 1:length(target_groups)
            for s = 1:length(sessions_to_compare)
                RawData.(rat).(target_groups{g}).(sessions_to_compare{s}) = [];
            end
        end
    end
    
    % Filter and Sort Traces
    valid_mask = ismember(traces(:, 2), [1, 2, 3]); 
    valid_traces = traces(valid_mask, :);
    [~, sortIdx] = sort(valid_traces(:, 1)); 
    sorted_traces = valid_traces(sortIdx, :);
    
    % Get CSV Data for this EXACT Session and Date
    excel_mask = strcmp(T.Rat, rat) & strcmp(T.Session_Type, session) & strcmp(T.Date, d1);
    session_data = T(excel_mask, :);
    if isempty(session_data), continue; end
    
    % Loop through trials
    for trial_idx = 1:size(sorted_traces, 1)
        trial_ts = sorted_traces(trial_idx, 1);
        
        if exclude_first_15_mins && trial_ts <= 900
            continue; 
        end
        
        row_idx = find(session_data.Trial == trial_idx);
        if isempty(row_idx), continue; end
        if length(row_idx) > 1, row_idx = row_idx(1); end
        
        % QC 1: Latency Check
        val_excel = session_data.Latency(row_idx); 
        val_mat   = sorted_traces(trial_idx, 3);    
        if abs(val_excel - val_mat) > 0.1
            mismatch_count = mismatch_count + 1;
        end
        
        % Get State
        state_num = session_data.Inferred_State(row_idx);
        if iscell(state_num), state_num = state_num{1}; end
        if isstring(state_num) || ischar(state_num), state_num = str2double(state_num); end
        if isnan(state_num) || isempty(state_num), continue; end
        
        state_num = round(state_num); 
        
        % Determine Condition Type
        cue_type = sorted_traces(trial_idx, 2); 
        outcome  = sorted_traces(trial_idx, 4); 
        
        cond_field = '';
        if cue_type == 1 
            if outcome >= 1, cond_field = 'Rew_Resp'; else, cond_field = 'Rew_Omit'; end
        elseif cue_type == 2 
            if outcome >= 1, cond_field = 'Pun_Resp'; else, cond_field = 'Pun_Omit'; end
        elseif cue_type == 3 
            if outcome >= 1, cond_field = 'Conf_Resp'; else, cond_field = 'Conf_Omit'; end
        end
        
        % Construct the specific group name
        group_name = sprintf('%s_S%d', cond_field, state_num);
        
        % Store Data
        if ismember(group_name, target_groups)
            data_seg = sorted_traces(trial_idx, 5:323);
            sess_safe_name = strrep(session, ' ', '_'); 
            RawData.(rat).(group_name).(sess_safe_name) = [RawData.(rat).(group_name).(sess_safe_name); data_seg];
        end
    end
end

if mismatch_count > 0
    fprintf('\n⚠️ QC 1 WARNING: %d latency mismatches found. Check timing alignments.\n', mismatch_count);
end

%% --- 4. Subject Means & Thresholding QC ---
fprintf('\n--- CALCULATING MEANS & CHECKING TRIAL COUNTS ---\n');
GroupData = struct();
for g = 1:length(target_groups)
    for s = 1:length(sessions_to_compare)
        GroupData.(target_groups{g}).(sessions_to_compare{s}) = [];
    end
end

rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    for g = 1:length(target_groups)
        tg = target_groups{g};
        for s = 1:length(sessions_to_compare)
            sess = sessions_to_compare{s};
            traces = RawData.(r).(tg).(sess);
            
            n_trials = size(traces, 1);
            if n_trials >= min_trials_threshold
                avg_trace = mean(traces, 1, 'omitnan');
                GroupData.(tg).(sess) = [GroupData.(tg).(sess); avg_trace];
            end
        end
    end
end
fprintf('✅ Data grouped successfully.\n');

%% --- 5. Generate Comparison Plots ---

% --- Colors for Cross-State Plotting (Matching your exact publication Hex) ---
rgb_state1 = [176/255, 179/255, 0/255];  % #B0B300 (Yellow/Orange)
rgb_state3 = [0/255, 176/255, 179/255];  % #00B0B3 (Blue/Teal)

% =========================================================================
% PLOT TYPE A: Traditional Saline vs Alcohol High per Group
% =========================================================================
fprintf('\n--- Running Plot Type A: Saline vs Alcohol High per State ---\n');
plots_typeA = 0;
for g = 1:length(target_groups)
    tg = target_groups{g};
    
    % Skip State 2 entirely if it fails to hit minimum subject thresholds
    if contains(tg, '_S2')
        continue; 
    end
    
    if size(GroupData.(tg).Saline, 1) >= 3 && size(GroupData.(tg).Alcohol_High, 1) >= 3
        
        % Formatting Clean Labels
        title_str = strrep(tg, '_', ' '); 
        title_str = strrep(title_str, 'Rew Resp', 'Reward Press');
        title_str = strrep(title_str, 'Pun Resp', 'Punish Press');
        title_str = strrep(title_str, 'Conf Resp', 'Conflict Press');
        title_str = strrep(title_str, 'Pun Omit', 'Punish Omit');
        title_str = strrep(title_str, 'Conf Omit', 'Conflict Omit');
        title_str = strrep(title_str, 'S1', 'State 1 (Risk-Taking)');
        title_str = strrep(title_str, 'S3', 'State 3 (Repeating)');
        
        createComparisonPlot(GroupData.(tg).Saline, GroupData.(tg).Alcohol_High, ...
            'Saline', 'Alcohol High', c_saline, c_alcohol, c_perm, ...
            [title_str ' [Saline vs Alc High]'], time_window, p_val, min_trials_threshold, y_lims);
            
        plots_typeA = plots_typeA + 1;
    end
end
fprintf('✅ Total Saline vs Alcohol plots generated: %d\n', plots_typeA);

% =========================================================================
% PLOT TYPE B: State 1 vs State 3 Cross-Comparison WITHIN Alcohol High
% =========================================================================
fprintf('\n--- Running Plot Type B: State 1 vs State 3 Within Alcohol High ---\n');
plots_typeB = 0;

for c = 1:length(base_conditions)
    bc = base_conditions{c};
    
    % Construct the paired state group handles for the exact same behavior
    tg_s1 = sprintf('%s_S1', bc);
    tg_s3 = sprintf('%s_S3', bc);
    
    if isfield(GroupData, tg_s1) && isfield(GroupData, tg_s3)
        % Pull the Alcohol High matrices for both states
        traces_s1_alc = GroupData.(tg_s1).Alcohol_High;
        traces_s3_alc = GroupData.(tg_s3).Alcohol_High;
        
        % Ensure we have enough subjects in both state matrices to run the permutation test
        if size(traces_s1_alc, 1) >= 3 && size(traces_s3_alc, 1) >= 3
            
            % Formatting Clean Labels
            behavior_label = strrep(bc, '_', ' ');
            behavior_label = strrep(behavior_label, 'Rew Resp', 'Reward Press');
            behavior_label = strrep(behavior_label, 'Pun Resp', 'Punish Press');
            behavior_label = strrep(behavior_label, 'Conf Resp', 'Conflict Press');
            behavior_label = strrep(behavior_label, 'Pun Omit', 'Punish Omit');
            behavior_label = strrep(behavior_label, 'Conf Omit', 'Conflict Omit');
            
            fig_title = sprintf('%s: State 1 vs State 3 [Alcohol High Only]', behavior_label);
            
            % Execute the plot using the exact matching publication color vectors
            createComparisonPlot(traces_s1_alc, traces_s3_alc, ...
                'State 1 (Risk-Taking)', 'State 3 (Repeating)', rgb_state1, rgb_state3, c_perm, ...
                fig_title, time_window, p_val, min_trials_threshold, y_lims);
                
            plots_typeB = plots_typeB + 1;
        end
    end
end
fprintf('✅ Total Cross-State Alcohol plots generated: %d\n', plots_typeB);