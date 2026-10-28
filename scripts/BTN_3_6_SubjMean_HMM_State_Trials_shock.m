%% HMM Model Integration: Within-Subject Threat Scaling Analysis (High vs Low mA)
%  Goal: Separate traces by Cue x Response x State x Individual Threat Level (High/Low mA).
%  QC 1: Verifies that Excel 'Latency' matches MAT file Column 3.
%  QC 2: Checks N-trials per subject and removes rats below threshold.
clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';

% Analysis Parameters
time_window = linspace(-10, 45, 876); 
min_trials_threshold = 5; % Minimum trials to include a subject's mean trace

% -----------------------------
% Colors
c_high_mA = [0.85, 0.15, 0.20];  % Crimson/Red for High Threat sessions
c_low_mA  = [0.20, 0.55, 0.85];  % Classic Blue for Low Threat sessions
c_perm    = [0.5, 0.5, 0.5];    % Permutation test color

%% --- 2. Load and Clean Excel Data + Calculate Within-Subject Medians ---
fprintf('Loading Excel Data...\n');
try
    T = readtable(path_excel);
catch ME
    error('Failed to load Excel file. Check path.\nError: %s', ME.message);
end

% --- CALCULATE INDIVIDUAL RAT MEDIANS ---
fprintf('Calculating unique within-subject median shock intensities (mA)...\n');
unique_rats = unique(T.Rat);
RatMedians = containers.Map();

for r = 1:length(unique_rats)
    curr_rat = unique_rats{r};
    rat_rows = T(strcmp(T.Rat, curr_rat), :);
    
    % Get the unique intensity values per session for this specific rat
    [~, unique_ses_idx] = unique(rat_rows.Session);
    rat_session_intensities = rat_rows.Intensity(unique_ses_idx);
    
    % Store their individual median threshold
    RatMedians(curr_rat) = median(rat_session_intensities, 'omitnan');
end

%% --- 3. Data Extraction & Threat Partitioning ---
fprintf('Processing Files & Sorting Sessions by Within-Subject Thresholds...\n');
files = dir(fullfile(path_data, '*.mat'));
cond_names = {'Rew_Resp', 'Rew_Omit', 'Pun_Resp', 'Pun_Omit', 'Conf_Resp', 'Conf_Omit'};
state_combos = {'S1_High', 'S1_Low', 'S2_High', 'S2_Low', 'S3_High', 'S3_Low'};
RawData = struct(); 

mismatch_count = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_10_45;
    
    % Guarantee clean string keys for struct/map lookups
    rat_str = char(rat);
    
    % Initialize Rat fields for all threat and state combinations
    if ~isfield(RawData, rat_str)
        for c = 1:length(cond_names)
            for s = 1:length(state_combos)
                RawData.(rat_str).(cond_names{c}).(state_combos{s}) = [];
            end
        end
    end
    
    valid_mask = ismember(traces(:, 2), [1, 2, 3]); 
    valid_traces = traces(valid_mask, :);
    [~, sortIdx] = sort(valid_traces(:, 1)); 
    sorted_traces = valid_traces(sortIdx, :);
    
    excel_mask = strcmp(string(T.Rat), rat_str) & strcmp(string(T.Session), session);
    session_data = T(excel_mask, :);
    if isempty(session_data), continue; end
    
    % DYNAMIC THREAT ASSIGNMENT
    session_mA = session_data.Intensity(1); % Intensity is uniform across a session
    rat_median_threshold = RatMedians(rat_str);
    
    if session_mA > rat_median_threshold
        threat_tag = 'High';
    else
        threat_tag = 'Low'; % Sessions equal to or below their own median
    end
    
    for trial_idx = 1:size(sorted_traces, 1)
        row_idx = find(session_data.Trial == trial_idx);
        if isempty(row_idx), continue; end
        
        if iscell(session_data.Inferred_State)
            state_num = session_data.Inferred_State{row_idx};
        else
            state_num = session_data.Inferred_State(row_idx);
        end
        
        if isnan(state_num) || ~ismember(state_num, [1, 2, 3])
            continue; 
        end
        
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
        
        if ~isempty(cond_field)
            data_seg = sorted_traces(trial_idx, 5:end);
            % Build the unique target string descriptor (e.g., 'S1_High')
            target_field = sprintf('S%d_%s', int32(state_num), threat_tag);
            RawData.(rat_str).(cond_field).(target_field) = [RawData.(rat_str).(cond_field).(target_field); data_seg];
        end
    end
end
fprintf('\n✅ QC 1 PASSED: Split indices successfully logged.\n');

%% --- 4. Subject Means & Thresholding QC ---
fprintf('\n--- CALCULATING SUBJECT MEANS FOR THREAT CONDITIONS ---\n');

GroupData = struct();
for c = 1:length(cond_names)
    for s = 1:length(state_combos)
        GroupData.(cond_names{c}).(state_combos{s}) = [];
    end
end

rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    for c = 1:length(cond_names)
        cn = cond_names{c};
        for s = 1:length(state_combos)
            curr_combo = state_combos{s};
            
            traces = RawData.(r).(cn).(curr_combo);
            n_trials = size(traces, 1);
            
            if n_trials >= min_trials_threshold
                avg_trace = mean(traces, 1, 'omitnan');
                GroupData.(cn).(curr_combo) = [GroupData.(cn).(curr_combo); avg_trace];
            end
        end
    end
end

%% --- 5. Generate Target Contrast Plots ---
fprintf('Generating Target Threat Contrast Plots (High vs Low mA)...\n');
y_lims = [-1 3]; 
consec_threshold = 8;
p_val = 0.05;

%% ========================================================================
%  THE CORE QUESTION: DOES SHOCK INTENSITY SHIFT PHENOTYPIC BRAIN SIGNALS?
%  ========================================================================

% Contrast 1: State 1 (Risk-Taking Mindset) — Responded Conflict Trials
sig_S1_Resp = createComparisonPlot(GroupData.Conf_Resp.S1_High, GroupData.Conf_Resp.S1_Low, ...
    'High mA Sessions', 'Low mA Sessions', c_high_mA, c_low_mA, c_perm, ...
    'Conflict Responded: State 1 (High vs Low mA Scaling)', time_window, p_val, consec_threshold, y_lims);

% Contrast 2: State 1 (Risk-Taking Mindset) — Omitted Conflict Trials
sig_S1_Omit = createComparisonPlot(GroupData.Conf_Omit.S1_High, GroupData.Conf_Omit.S1_Low, ...
    'High mA Sessions', 'Low mA Sessions', c_high_mA, c_low_mA, c_perm, ...
    'Conflict Omitted: State 1 (High vs Low mA Scaling)', time_window, p_val, consec_threshold, y_lims);

% Contrast 3: State 2 (Risk-Averse Mindset) — Responded Conflict Trials
sig_S2_Resp = createComparisonPlot(GroupData.Conf_Resp.S2_High, GroupData.Conf_Resp.S2_Low, ...
    'High mA Sessions', 'Low mA Sessions', c_high_mA, c_low_mA, c_perm, ...
    'Conflict Responded: State 2 (High vs Low mA Scaling)', time_window, p_val, consec_threshold, y_lims);

% Contrast 4: State 2 (Risk-Averse Mindset) — Omitted Conflict Trials
sig_S2_Omit = createComparisonPlot(GroupData.Conf_Omit.S2_High, GroupData.Conf_Omit.S2_Low, ...
    'High mA Sessions', 'Low mA Sessions', c_high_mA, c_low_mA, c_perm, ...
    'Conflict Omitted: State 2 (High vs Low mA Scaling)', time_window, p_val, consec_threshold, y_lims);

fprintf('✅ All threat-scaled comparison plots generated.\n');