%% HMM Model Integration: 6-Way Split (ALL TRIALS POOLED)
%  Goal: Separate traces by Cue x Response x State.
%  METHOD: Pools ALL trials from all subjects into a single array (No Subject Means).

clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-45)';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Merged_dataframe_neural_plus_model.xlsx';

% Analysis Parameters
% Note: Ensure 876 matches the column width of traces (5:end)
time_window = linspace(-10, 45, 876); 
p_val = 0.05;
thres = 5; 
y_lims = [-2 5]; 

% Colors
c_s1 = [0.00, 0.45, 0.74]; 
c_s2 = [0.85, 0.33, 0.10]; 
c_s3 = [0.47, 0.67, 0.19]; 
c_perm = [0.5, 0.5, 0.5];  

%% --- 2. Load and Clean Excel Data ---
fprintf('Loading Excel Data...\n');
try
    T = readtable(path_excel);
catch ME
    error('Failed to load Excel file. Check path.\nError: %s', ME.message);
end

% FIX 1: Normalize Rat IDs (9 -> R09)
clean_rats = cell(height(T), 1);
for i = 1:height(T)
    val = T.Rat(i);
    if isnumeric(val), num_val = val; else, num_val = str2double(string(val)); end
    if num_val < 10, clean_rats{i} = sprintf('R0%d', num_val);
    else, clean_rats{i} = sprintf('R%d', num_val); end
end
T.Rat_Formatted = clean_rats;

% FIX 2: Clean Session IDs (Remove quotes)
T.Session_Clean = strrep(string(T.Session), "'", ""); 
fprintf('✅ Excel loaded and cleaned. Rows: %d\n', height(T));

%% --- 3. Data Extraction & Pooling (Direct to GroupData) ---
fprintf('Processing Files & Pooling Trials...\n');
files = dir(fullfile(path_data, '*.mat'));

cond_names = {'Rew_Resp', 'Rew_Omit', 'Pun_Resp', 'Pun_Omit', 'Conf_Resp', 'Conf_Omit'};

% Initialize GroupData to hold ALL trials directly
GroupData = struct();
for c = 1:length(cond_names)
    GroupData.(cond_names{c}).S1 = [];
    GroupData.(cond_names{c}).S2 = [];
    GroupData.(cond_names{c}).S3 = [];
end

% Counter for mismatches
mismatch_count = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z;
    
    % 1. Filter and Sort Traces
    valid_mask = ismember(traces(:, 2), [1, 2, 3]); 
    valid_traces = traces(valid_mask, :);
    [~, sortIdx] = sort(valid_traces(:, 1)); 
    sorted_traces = valid_traces(sortIdx, :);
    
    % 2. Get Excel Data for this Session
    excel_mask = strcmp(string(T.Rat_Formatted), rat) & strcmp(string(T.Session_Clean), session);
    session_data = T(excel_mask, :);
    
    if isempty(session_data), continue; end
    
    % 3. Loop through trials
    for trial_idx = 1:size(sorted_traces, 1)
        
        % Match Trial Number
        row_idx = find(session_data.Trial == trial_idx);
        if isempty(row_idx), continue; end
        
        % --- QUALITY CONTROL CHECK ---
        val_excel = session_data.Latency_x(row_idx); % Latency from Excel
        val_mat   = sorted_traces(trial_idx, 3);     % Column 3 from MAT file
        
        % Check difference (Allowing small floating point tolerance)
        if abs(val_excel - val_mat) > 0.1
            fprintf('⚠️ MISMATCH [%s %s Trial %d]: Excel Latency=%.2f, MAT Col3=%.2f\n', ...
                rat, session, trial_idx, val_excel, val_mat);
            mismatch_count = mismatch_count + 1;
        end
        % -----------------------------

        % Get State
        state_str = string(session_data.Most_likely_state{row_idx});
        if contains(state_str, 'inconclusive'), continue; end
        
        % Determine Condition Type
        cue_type = sorted_traces(trial_idx, 2); 
        outcome  = sorted_traces(trial_idx, 4); 
        
        cond_field = '';
        if cue_type == 1 % RewDS
            if outcome >= 1, cond_field = 'Rew_Resp'; else, cond_field = 'Rew_Omit'; end
        elseif cue_type == 2 % PunDS
            if outcome >= 1, cond_field = 'Pun_Resp'; else, cond_field = 'Pun_Omit'; end
        elseif cue_type == 3 % Conf
            if outcome >= 1, cond_field = 'Conf_Resp'; else, cond_field = 'Conf_Omit'; end
        end
        
        % Store Data DIRECTLY into GroupData (Pooling all trials)
        if ~isempty(cond_field)
            data_seg = sorted_traces(trial_idx, 5:end);
            
            if strcmpi(state_str, 'State_1')
                GroupData.(cond_field).S1 = [GroupData.(cond_field).S1; data_seg];
            elseif strcmpi(state_str, 'State_2')
                GroupData.(cond_field).S2 = [GroupData.(cond_field).S2; data_seg];
            elseif strcmpi(state_str, 'State_3')
                GroupData.(cond_field).S3 = [GroupData.(cond_field).S3; data_seg];
            end
        end
    end
end

if mismatch_count == 0
    fprintf('\n✅ QUALITY CONTROL PASSED: All latency values match.\n');
else
    fprintf('\n❌ QUALITY CONTROL FAILED: Found %d mismatches.\n', mismatch_count);
    return; 
end

%% --- 4. Generate the 6 Plots (Pooled Data) ---
fprintf('Generating 6 Comparison Plots (Pooled Trials)...\n');

createComparisonPlot_3way(GroupData.Rew_Resp.S1, GroupData.Rew_Resp.S2, GroupData.Rew_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'RewDS - Responded', time_window, p_val, thres, y_lims);

createComparisonPlot_3way(GroupData.Rew_Omit.S1, GroupData.Rew_Omit.S2, GroupData.Rew_Omit.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'RewDS - Omitted', time_window, p_val, thres, y_lims);

createComparisonPlot_3way(GroupData.Pun_Resp.S1, GroupData.Pun_Resp.S2, GroupData.Pun_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'PunDS - Responded', time_window, p_val, thres, y_lims);

createComparisonPlot_3way(GroupData.Pun_Omit.S1, GroupData.Pun_Omit.S2, GroupData.Pun_Omit.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'PunDS - Omitted', time_window, p_val, thres, y_lims);

createComparisonPlot_3way(GroupData.Conf_Resp.S1, GroupData.Conf_Resp.S2, GroupData.Conf_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'Conflict - Responded', time_window, p_val, thres, y_lims);

createComparisonPlot_3way(GroupData.Conf_Omit.S1, GroupData.Conf_Omit.S2, GroupData.Conf_Omit.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    'Conflict - Omitted', time_window, p_val, thres, y_lims);

fprintf('✅ All plots generated.\n');

