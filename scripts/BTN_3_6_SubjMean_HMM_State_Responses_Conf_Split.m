%% HMM Model Integration: Response-Aligned (-25 to +15) 
%  Goal: Separate RESPONSE traces (events 5 & 6) by Cue x State x Outcome.
%  Alignment: Reconstructs Trial TS from Response TS to find Excel State and Cue.
clear all; %close all; clc;
%% --- 1. Configuration & Setup ---
% Paths 
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';
% Analysis Parameters
time_bounds = [-25, 15]; % The bounds of your new traces
p_val = 0.05;
y_lims = [-2 8]; 
% Threshold Setting: Min trials per state to include rat in average
min_trials_threshold = 5; 
% Colors
c_s3 = [0.00, 0.69, 0.70]; %blue
c_s1 = [0.69, 0.70, 0.00]; %Orange/Yellow
c_s2 = [0.71, 0.00, 0.70]; %Red
c_rewDS = [0.12, 0.80, 0.01];
c_punDS = [0.87, 0.01, 0.12];
c_conf = [0.01, 0.11, 0.86];
c_perm = [0.5, 0.5, 0.5];  
%% --- 2. Load and Clean Excel Data ---
fprintf('Loading Excel Data...\n');
try
    T = readtable(path_excel);
catch ME
    error('Failed to load Excel file. Check path.\nError: %s', ME.message);
end
% Sessions are already clean, so we just convert to string for easy matching
T.Session_Clean = string(T.Session); 
fprintf('Excel loaded successfully. Rows: %d\n', height(T));
%% --- 3. Data Extraction & Reverse Alignment ---
fprintf('Processing Files & Reconstructing Timestamps...\n');
files = dir(fullfile(path_data, '*.mat'));
% Dynamic condition arrays to separate Conflict outcomes cleanly at the trial level
cond_names = {'Rew_Resp', 'Pun_Resp', 'Conf_Rew_Resp', 'Conf_Pun_Resp'};
RawData = struct(); 
time_window = []; % Will be populated dynamically based on trace size
zero_idx = [];    % Index corresponding to T=0 (lever press)
% Counters
matches_found = 0;
failed_alignments = 0;
for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_25_15;
    
    % Initialize Rat fields
    if ~isfield(RawData, rat)
        for c = 1:length(cond_names)
            RawData.(rat).(cond_names{c}).S1 = [];
            RawData.(rat).(cond_names{c}).S2 = [];
            RawData.(rat).(cond_names{c}).S3 = [];
        end
    end
    
    % 1. Filter for RESPONSES ONLY (Column 2 == 5 or 6)
    valid_mask = ismember(traces(:, 2), [5, 6]); 
    valid_traces = traces(valid_mask, :);
    
    % Get Excel Data for this Session
    excel_mask = strcmp(string(T.Rat), rat) & strcmp(T.Session_Clean, string(session));
    session_data = T(excel_mask, :);
    
    if isempty(session_data), continue; end
    
    % Dynamically set time_window array and find the T=0 alignment index
    if isempty(time_window) && ~isempty(valid_traces)
        time_window = linspace(time_bounds(1), time_bounds(2), size(valid_traces, 2) - 4);
        [~, zero_idx] = min(abs(time_window)); % Find index closest to 0s (Lever Press)
    end
    
    % 2. Loop through response traces
    for trace_idx = 1:size(valid_traces, 1)
        
        resp_ts    = valid_traces(trace_idx, 1); % Col 1: Event Timestamp
        outcome    = valid_traces(trace_idx, 2); % Col 2: 5 (Pellet) or 6 (Shock)
        latency    = valid_traces(trace_idx, 3); % Col 3: Latency
        
        % --- REVERSE ALIGNMENT MATH ---
        expected_trial_ts = resp_ts - 10 - latency;
        
        % Find the closest Trial Timestamp in the Excel sheet
        ts_diffs = abs(session_data.Timestamp - expected_trial_ts);
        [min_diff, row_idx] = min(ts_diffs);
        
        % Check if the alignment was successful (tolerance of 0.15s)
        if isempty(min_diff) || min_diff > 0.15
            failed_alignments = failed_alignments + 1;
            continue; 
        end
        matches_found = matches_found + 1;
        
        % --- GET STATE FROM EXCEL ---
        state_str = string(session_data.Inferred_State(row_idx));
        if contains(state_str, 'inconclusive', 'IgnoreCase', true), continue; end
        
        % --- GET CUE FROM EXCEL AND ASSIGN CONDITION ---
        cue_str = lower(string(session_data.Cue(row_idx)));
        cond_field = '';
        
        if contains(cue_str, 'reward')
            cond_field = 'Rew_Resp';
        elseif contains(cue_str, 'punish')
            cond_field = 'Pun_Resp';
        elseif contains(cue_str, 'conflict')
            % Sort raw trials temporarily by outcome to process bifurcations later
            if outcome == 5
                cond_field = 'Conf_Rew_Resp';
            elseif outcome == 6
                cond_field = 'Conf_Pun_Resp';
            end
        end
        
        % Store Data
        if ~isempty(cond_field)
            data_seg = valid_traces(trace_idx, 5:end);
            if contains(state_str, 'State_1', 'IgnoreCase', true) || contains(state_str, '1')
                RawData.(rat).(cond_field).S1 = [RawData.(rat).(cond_field).S1; data_seg];
            elseif contains(state_str, 'State_2', 'IgnoreCase', true) || contains(state_str, '2')
                RawData.(rat).(cond_field).S2 = [RawData.(rat).(cond_field).S2; data_seg];
            elseif contains(state_str, 'State_3', 'IgnoreCase', true) || contains(state_str, '3')
                RawData.(rat).(cond_field).S3 = [RawData.(rat).(cond_field).S3; data_seg];
            end
        end
   end
end
fprintf('\nAlignment Results:\n');
fprintf('  ✅ Successfully aligned: %d responses\n', matches_found);
fprintf('  ❌ Failed alignments: %d responses\n', failed_alignments);
%% --- 4. Subject Means & Bifurcation QC ---
fprintf('\n--- CALCULATING MEANS & BIFURCATING CONFLICT TRACES ---\n');
GroupData = struct();
for c = 1:length(cond_names)
    GroupData.(cond_names{c}).S1 = [];
    GroupData.(cond_names{c}).S2 = [];
    GroupData.(cond_names{c}).S3 = [];
end
qc_report = {}; 
states = {'S1', 'S2', 'S3'};
rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    for s = 1:length(states)
        curr_state = states{s};
        
        % --- 4a. Process Standard Conditions (Baseline Reward & Punishment) ---
        standard_conds = {'Rew_Resp', 'Pun_Resp'};
        for c = 1:length(standard_conds)
            cn = standard_conds{c};
            traces = RawData.(r).(cn).(curr_state);
            n_trials = size(traces, 1);
            
            if n_trials >= min_trials_threshold
                avg_trace = mean(traces, 1, 'omitnan');
                GroupData.(cn).(curr_state) = [GroupData.(cn).(curr_state); avg_trace];
                status = 'Included';
            else
                status = 'DROPPED';
            end
            
            if n_trials > 0 || strcmp(status, 'DROPPED')
                 qc_report{end+1, 1} = r;
                 qc_report{end, 2} = cn;
                 qc_report{end, 3} = curr_state;
                 qc_report{end, 4} = n_trials;
                 qc_report{end, 5} = status;
            end
        end
        
        % --- 4b. Process Conflict Conditions with Mathematical Forking ---
        traces_pellet = RawData.(r).Conf_Rew_Resp.(curr_state);
        traces_shock  = RawData.(r).Conf_Pun_Resp.(curr_state);
        
        n_pellet = size(traces_pellet, 1);
        n_shock  = size(traces_shock, 1);
        
        % Merge all conflict trials for a single, noise-reduced pre-press dataset
        all_conf_traces = [traces_pellet; traces_shock];
        
        if ~isempty(all_conf_traces)
            shared_pre_press = mean(all_conf_traces(:, 1:zero_idx-1), 1, 'omitnan');
        else
            shared_pre_press = [];
        end
        
        % --- Conflict Pellet Branch ---
        if n_pellet >= min_trials_threshold
            avg_trace_pellet = zeros(1, size(traces_pellet, 2));
            avg_trace_pellet(1:zero_idx-1) = shared_pre_press; % Pure combined array before press
            avg_trace_pellet(zero_idx:end)  = mean(traces_pellet(:, zero_idx:end), 1, 'omitnan'); % Outcome trace
            
            GroupData.Conf_Rew_Resp.(curr_state) = [GroupData.Conf_Rew_Resp.(curr_state); avg_trace_pellet];
            status_pellet = 'Included';
        else
            status_pellet = 'DROPPED';
        end
        
        if n_pellet > 0 || strcmp(status_pellet, 'DROPPED')
             qc_report{end+1, 1} = r;
             qc_report{end, 2} = 'Conf_Rew_Resp';
             qc_report{end, 3} = curr_state;
             qc_report{end, 4} = n_pellet;
             qc_report{end, 5} = status_pellet;
        end
        
        % --- Conflict Shock Branch ---
        if n_shock >= min_trials_threshold
            avg_trace_shock = zeros(1, size(traces_shock, 2));
            avg_trace_shock(1:zero_idx-1) = shared_pre_press; % Pure combined array before press
            avg_trace_shock(zero_idx:end)  = mean(traces_shock(:, zero_idx:end), 1, 'omitnan'); % Outcome trace
            
            GroupData.Conf_Pun_Resp.(curr_state) = [GroupData.Conf_Pun_Resp.(curr_state); avg_trace_shock];
            status_shock = 'Included';
        else
            status_shock = 'DROPPED';
        end
        
        if n_shock > 0 || strcmp(status_shock, 'DROPPED')
             qc_report{end+1, 1} = r;
             qc_report{end, 2} = 'Conf_Pun_Resp';
             qc_report{end, 3} = curr_state;
             qc_report{end, 4} = n_shock;
             qc_report{end, 5} = status_shock;
        end
    end
end
T_QC = cell2table(qc_report, 'VariableNames', {'Rat', 'Condition', 'State', 'N_Trials', 'Status'});
fprintf('\n=== QC RESPONSE COUNT REPORT ===\n');
disp(T_QC);
%% --- 5. Generate the Plots ---
fprintf('Generating Response Plots...\n');
y_lims = [-2 8]; 
consec_threshold = 8; % Passed to the functions as 'thres'
p_val = 0.05;

% =========================================================================
% PLOT 1: Baseline Reward Responses (Pure Pellet Outcomes)
% =========================================================================
sig_S123R = createComparisonPlot_3way(...
    GroupData.Rew_Resp.S1, GroupData.Rew_Resp.S2, GroupData.Rew_Resp.S3, ...
    'State 1', 'State 2', 'State 3', ...
    c_s1, c_s2, c_s3, c_perm, ...
    ['RewDS Responses (Min ' num2str(min_trials_threshold) ')'], ...
    time_window, p_val, consec_threshold, y_lims);

% =========================================================================
% PLOT 2: Baseline Punishment Responses (Pure Shock Outcomes)
% =========================================================================
sig_S123P = createComparisonPlot_3way(...
    GroupData.Pun_Resp.S1, GroupData.Pun_Resp.S2, GroupData.Pun_Resp.S3, ...
    'State 1', 'State 2', 'State 3', ...
    c_s1, c_s2, c_s3, c_perm, ...
    ['PunDS Responses (Min ' num2str(min_trials_threshold) ')'], ...
    time_window, p_val, consec_threshold, y_lims);

% =========================================================================
% PLOT 3: Grand Conflict Overview (NEW BIFURCATED / FORKED TRACES)
% =========================================================================
% This single function completely replaces the old, separate Plot 3 and 4.
% It plots a unified pre-press trace for each state, then forks at T=0.
sig123C_Bifurcated = createBifurcatedPlot_3way(...
    GroupData.Conf_Rew_Resp.S1, GroupData.Conf_Pun_Resp.S1, ... % State 1 (Pellet, Shock)
    GroupData.Conf_Rew_Resp.S2, GroupData.Conf_Pun_Resp.S2, ... % State 2 (Pellet, Shock)
    GroupData.Conf_Rew_Resp.S3, GroupData.Conf_Pun_Resp.S3, ... % State 3 (Pellet, Shock)
    'State 1', 'State 2', 'State 3', ...
    c_s1, c_s2, c_s3, c_perm, ...
    ['Conflict Responses - Forked Outcomes (Min ' num2str(min_trials_threshold) ')'], ...
    time_window, p_val, consec_threshold, y_lims);

% =========================================================================
% OPTIONAL: Within-State Baseline Comparison Plots 
% =========================================================================
% If you want to view a single state's conflict trace mapped against its 
% baseline reward/punishment traces, you can use either branch here:

% --- State 1: Conflict (Pellet Branch) vs Baselines ---
sig_S1 = createComparisonPlot_3way(...
     GroupData.Conf_Rew_Resp.S1, GroupData.Pun_Resp.S1, GroupData.Rew_Resp.S1, ...
     'confDS (Pellet)', 'punDS', 'rewDS', ...
     c_conf, c_punDS, c_rewDS, c_perm, ...
     ['State 1 Baseline Overlap (Min ' num2str(min_trials_threshold) ')'], ...
     time_window, p_val, consec_threshold, y_lims);

% --- State 2: Conflict (Shock Branch) vs Baselines ---
sig_S2 = createComparisonPlot_3way(...
     GroupData.Conf_Pun_Resp.S2, GroupData.Pun_Resp.S2, GroupData.Rew_Resp.S2, ...
     'confDS (Shock)', 'punDS', 'rewDS', ...
     c_conf, c_punDS, c_rewDS, c_perm, ...
     ['State 2 Baseline Overlap (Min ' num2str(min_trials_threshold) ')'], ...
     time_window, p_val, consec_threshold, y_lims);

% --- State 3: Conflict (Pellet Branch) vs Baselines ---
sig_S3 = createComparisonPlot_3way(...
     GroupData.Conf_Rew_Resp.S3, GroupData.Pun_Resp.S3, GroupData.Rew_Resp.S3, ...
     'confDS (Pellet)', 'punDS', 'rewDS', ...
     c_conf, c_punDS, c_rewDS, c_perm, ...
     ['State 3 Baseline Overlap (Min ' num2str(min_trials_threshold) ')'], ...
     time_window, p_val, consec_threshold, y_lims);

fprintf('✅ All figures and bifurcated outcomes processed successfully.\n');