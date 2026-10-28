%% HMM Model Integration: 6-Way Split with Quality Control (N-Trial Thresholding)
%  Goal: Separate traces by Cue x Response x State.
%  QC 1: Verifies that Excel 'Latency' matches MAT file Column 3.
%  QC 2: Checks N-trials per subject and removes rats below threshold.

clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';

% Analysis Parameters
time_window = linspace(-10, 45, 876); 
% time_window = linspace(-10, 10, 319); 

% Any subject with fewer than this many trials in a specific state will be REMOVED from that mean.
min_trials_threshold = 5; 
% -----------------------------

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


%% --- 3. Data Extraction & Quality Control (Latency Match) ---
fprintf('Processing Files & Running QC (Latency Check)...\n');

files = dir(fullfile(path_data, '*.mat'));
cond_names = {'Rew_Resp', 'Rew_Omit', 'Pun_Resp', 'Pun_Omit', 'Conf_Resp', 'Conf_Omit'};
RawData = struct(); 

% Counter for mismatches
mismatch_count = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_10_45;
    
    % Initialize Rat fields
    if ~isfield(RawData, rat)
        for c = 1:length(cond_names)
            RawData.(rat).(cond_names{c}).S1 = [];
            RawData.(rat).(cond_names{c}).S2 = [];
            RawData.(rat).(cond_names{c}).S3 = [];
            % RawData.(rat).(cond_names{c}).S4 = [];
        end
    end
    
    % 1. Filter and Sort Traces
    valid_mask = ismember(traces(:, 2), [1, 2, 3]); 
    valid_traces = traces(valid_mask, :);
    [~, sortIdx] = sort(valid_traces(:, 1)); 
    sorted_traces = valid_traces(sortIdx, :);
    
    % 2. Get Excel Data for this Session
    excel_mask = strcmp(string(T.Rat), rat) & strcmp(string(T.Session), session);
    session_data = T(excel_mask, :);
    
    if isempty(session_data), continue; end
    
    % 3. Loop through trials
    for trial_idx = 1:size(sorted_traces, 1)
        
        % Match Trial Number
        row_idx = find(session_data.Trial == trial_idx);
        if isempty(row_idx), continue; end
        
        % % --- QUALITY CONTROL CHECK 1: LATENCY ---
        % val_excel = session_data.Latency(row_idx); 
        % val_mat   = sorted_traces(trial_idx, 3);    
        % 
        % if abs(val_excel - val_mat) > 0.1
        %     fprintf('⚠️ MISMATCH [%s %s Trial %d]: Excel=%.2f, MAT=%.2f\n', ...
        %         rat, session, trial_idx, val_excel, val_mat);
        %     mismatch_count = mismatch_count + 1;
        % end
        % ----------------------------------------
        
        % Handle table columns safely (whether read as array or cell of numbers)
        if iscell(session_data.Inferred_State)
            state_num = session_data.Inferred_State{row_idx};
        else
            state_num = session_data.Inferred_State(row_idx);
        end
        
        % Skip if NaN or not 1, 2, or 3
        if isnan(state_num) || ~ismember(state_num, [1, 2, 3])
            continue; 
        end
        
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
        
        % Store Data
        if ~isempty(cond_field)
            data_seg = sorted_traces(trial_idx, 5:end);
            
            if state_num == 1
                RawData.(rat).(cond_field).S1 = [RawData.(rat).(cond_field).S1; data_seg];
            elseif state_num == 2
                RawData.(rat).(cond_field).S2 = [RawData.(rat).(cond_field).S2; data_seg];
            elseif state_num == 3
                RawData.(rat).(cond_field).S3 = [RawData.(rat).(cond_field).S3; data_seg];
            % elseif state_num == 4
            %     RawData.(rat).(cond_field).S4 = [RawData.(rat).(cond_field).S4; data_seg];
            end
        end
    end
end

if mismatch_count == 0
    fprintf('\n✅ QC 1 PASSED: Latency match verified.\n');
else
    fprintf('\n❌ QC 1 FAILED: %d mismatches found.\n', mismatch_count);
    return; 
end

%% --- 4. Subject Means & Thresholding QC ---
fprintf('\n--- CALCULATING MEANS & CHECKING TRIAL COUNTS ---\n');
fprintf('Threshold set to: %d trials per subject per state.\n', min_trials_threshold);

% Initialize Final Group Structures
GroupData = struct();
for c = 1:length(cond_names)
    GroupData.(cond_names{c}).S1 = [];
    GroupData.(cond_names{c}).S2 = [];
    GroupData.(cond_names{c}).S3 = [];
    % GroupData.(cond_names{c}).S4 = [];
end

% Initialize Table for QC Reporting
qc_report = {}; 
states = {'S1', 'S2', 'S3'};%, 'S4'};
rats = fieldnames(RawData);

for k = 1:length(rats)
    r = rats{k};
    
    for c = 1:length(cond_names)
        cn = cond_names{c};
        
        for s = 1:length(states)
            curr_state = states{s};
            
            % 1. Get the raw traces for this specific Rat/Condition/State
            traces = RawData.(r).(cn).(curr_state);
            
            % 2. Count Trials
            n_trials = size(traces, 1);
            
            % 3. Check Threshold
            if n_trials >= min_trials_threshold
                % PASS: Calculate mean and add to GroupData
                avg_trace = mean(traces, 1, 'omitnan');
                GroupData.(cn).(curr_state) = [GroupData.(cn).(curr_state); avg_trace];
                
                status = 'Included';
            else
                % FAIL: Do NOT add to GroupData
                % (We do nothing here, effectively dropping the rat from the plot)
                status = 'DROPPED';
            end
            
            % 4. Log to Report
            if n_trials > 0 || strcmp(status, 'DROPPED')
                 qc_report{end+1, 1} = r;
                 qc_report{end, 2} = cn;
                 qc_report{end, 3} = curr_state;
                 qc_report{end, 4} = n_trials;
                 qc_report{end, 5} = status;
            end
        end
    end
end

% --- DISPLAY QC TABLE ---
% T_QC = cell2table(qc_report, 'VariableNames', {'Rat', 'Condition', 'State', 'N_Trials', 'Status'});
% fprintf('\n=== QC TRIAL COUNT REPORT ===\n');
% disp(T_QC);
% 
% % Summary of Drops 
% dropped_data = T_QC(strcmp(T_QC.Status, 'DROPPED'), :);
% if height(dropped_data) > 0
%     fprintf('\n⚠️ WARNING: The following data points were removed due to low trial count (<%d):\n', min_trials_threshold);
%     disp(dropped_data);
% else
%     fprintf('\n✅ All active subjects met the threshold of %d trials.\n', min_trials_threshold);
% end

%% --- 5. Generate the 6 Plots ---
fprintf('Generating Comparison Plots (using only "Included" data)...\n');

y_lims = [-1 3]; 
consec_threshold = 8;
p_val = 0.05;
% createComparisonPlot_3way(GroupData.Rew_Resp.S1, GroupData.Rew_Resp.S2, GroupData.Rew_Resp.S3, ...
%     'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
%     ['RewDS - Responded (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% sig_34TR = createComparisonPlot(GroupData.Rew_Resp.S3, GroupData.Rew_Resp.S4, ...
%     'State 3', 'State 4', c_s1, c_s2, c_perm, ...
%     ['Conflict - Resp (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% sig_34TO = createComparisonPlot(GroupData.Pun_Omit.S3, GroupData.Pun_Omit.S4, ...
%     'State 3', 'State 4', c_s1, c_s2, c_perm, ...
    % ['Conflict - Omitted (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

% sig_12TR = createComparisonPlot(GroupData.Rew_Resp.S1, GroupData.Rew_Resp.S2, ...
%     'State 1', 'State 2', c_s1, c_s2, c_perm, ...
%     ['Conflict - Resp (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

sig_12TO = createComparisonPlot(GroupData.Pun_Omit.S1, GroupData.Pun_Omit.S2, ...
    'State 1', 'State 2', c_s1, c_s2, c_perm, ...
    ['Conflict - Omitted (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);


% createComparisonPlot_3way(GroupData.Pun_Resp.S1, GroupData.Pun_Resp.S2, GroupData.Pun_Resp.S3, ...
%      'State 1', ' State 2' , 'State 3', c_s1, c_s2, c_s3, c_perm, ...
%     ['PunDS - Responded (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot_3way(GroupData.Pun_Omit.S1, GroupData.Pun_Omit.S2, GroupData.Pun_Omit.S3, ...
%     'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
%     ['PunDS - Omitted (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

sig_S123R = createComparisonPlot_3way(GroupData.Conf_Resp.S1, GroupData.Conf_Resp.S2, GroupData.Conf_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    ['Conflict - Responded (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

sig_S123O = createComparisonPlot_3way(GroupData.Conf_Omit.S1, GroupData.Conf_Omit.S2, GroupData.Conf_Omit.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    ['Conflict - Omitted (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

% createComparisonPlot(GroupData.Conf_Resp.S1, GroupData.Conf_Omit.S1, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 1 Conf - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Conf_Resp.S2, GroupData.Conf_Omit.S2, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 2 Conf - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Conf_Resp.S3, GroupData.Conf_Omit.S3, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 3 Conf - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Rew_Resp.S1, GroupData.Rew_Omit.S1, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 1 Rew- Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Rew_Resp.S2, GroupData.Rew_Omit.S2, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 2 Rew - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Rew_Resp.S3, GroupData.Rew_Omit.S3, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%      ['State 3 Rew- Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Pun_Resp.S1, GroupData.Pun_Omit.S1, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 1 Pun - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Pun_Resp.S2, GroupData.Pun_Omit.S2, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%     ['State 2 Pun - Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Pun_Resp.S3, GroupData.Pun_Omit.S3, ...
%      'Respond', 'Omit', c_s1, c_s2, c_perm, ...
%      ['State 3 Pun- Resp v Omit (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Conf_Resp.S1, GroupData.Conf_Resp.S2, ...
%      'State 1', 'State 2', c_s1, c_s2, c_perm, ...
%     ['Conf Resp - 1 v 2 (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);
% 
% createComparisonPlot(GroupData.Conf_Omit.S1, GroupData.Conf_Omit.S2, ...
%      'State 1', 'State 2', c_s1, c_s2, c_perm, ...
%     ['Conf Omit - 1 v 2 (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);


sig_S1R = createComparisonPlot(GroupData.Conf_Resp.S1, GroupData.Rew_Resp.S1, ...
     'Conf', 'rewDS', c_conf, c_rewDS, c_perm, ...
    ['State 1 (resp) - Conf v RewDS (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

sig_S2O = createComparisonPlot(GroupData.Conf_Omit.S1, GroupData.Pun_Omit.S1, ...
     'Conf', 'punDS', c_conf, c_punDS, c_perm, ...
    ['State 1 (omit) - Conf v punDS (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);


sig_S2R = createComparisonPlot(GroupData.Conf_Resp.S2, GroupData.Rew_Resp.S2, ...
     'Conf', 'rewDS', c_conf, c_rewDS, c_perm, ...
    ['State 2 (resp) - Conf v RewDS (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);

sig_S1O = createComparisonPlot(GroupData.Conf_Omit.S2, GroupData.Pun_Omit.S2, ...
     'Conf', 'punDS', c_conf, c_punDS, c_perm, ...
    ['State 2 (omit) - Conf v punDS (Min ' num2str(min_trials_threshold) ' trials)'], time_window, p_val, consec_threshold, y_lims);


fprintf('✅ All plots generated.\n');