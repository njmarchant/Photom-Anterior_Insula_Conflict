%% HMM Model Integration: Response-Aligned (-25 to +15) 
%  Goal: Separate RESPONSE traces (events 5 & 6) by Cue x State x Outcome.
%  Alignment: Reconstructs Trial TS from Response TS to find Excel State and Cue.

clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths 
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data\with_resp_traces';
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';

% Analysis Parameters

p_val = 0.05;
y_lims = [-2 8]; 
crop_pre  = 15;   % s before the press to keep
crop_post = 15;   % s after the press to keep

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

% Now with 5 conditions to split Conflict by Outcome
cond_names = {'Rew_Resp', 'Pun_Resp', 'Conf_Rew_Resp', 'Conf_Pun_Resp'};
RawData = struct(); 
time_window = [];   % Will be populated from the first file
n_cols_ref  = [];   % Number of trace samples every file must match
% Counters
matches_found = 0;
failed_alignments = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
        rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_resp;

    % --- Crop to [-crop_pre, +crop_post] s around the press ---
    t_resp = sesdat.traces_resp_time;
    i0 = find(abs(t_resp) < 1e-9, 1);
    c0 = i0 - ceil(crop_pre  * sesdat.conversion);
    c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
    trace_cols = 4 + (c0 : c1);                  % +4 skips the header columns

    % All files must give the same number of samples, or the vertical concatenation fails
    if isempty(n_cols_ref)
        n_cols_ref  = numel(trace_cols);
        time_window = t_resp(c0:c1);             % exact time axis from the data
    elseif numel(trace_cols) ~= n_cols_ref
        fprintf('  SKIP %s: %d samples after crop (expected %d)\n', filename, numel(trace_cols), n_cols_ref);
        continue;
    end

    % Initialize Rat fields
    if ~isfield(RawData, rat)
        for c = 1:length(cond_names)
            RawData.(rat).(cond_names{c}).S1 = [];
            RawData.(rat).(cond_names{c}).S2 = [];
            RawData.(rat).(cond_names{c}).S3 = [];
            % RawData.(rat).(cond_names{c}).S4 = [];
        end
    end
    
    % 1. Filter for RESPONSES ONLY (Column 2 == 5 or 6)
    valid_mask = ismember(traces(:, 2), [5, 6]) & ~any(isnan(traces(:, trace_cols)), 2);
    valid_traces = traces(valid_mask, :);
    
    % Get Excel Data for this Session
    excel_mask = strcmp(string(T.Rat), rat) & strcmp(T.Session_Clean, string(session));
    session_data = T(excel_mask, :);
    
    if isempty(session_data), continue; end
    
    
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
            % Split Conflict by Outcome
            if outcome == 5
                cond_field = 'Conf_Rew_Resp';
                
            elseif outcome == 6
                cond_field = 'Conf_Pun_Resp'; %shock outcomes go into REW_RESP
                cond_field = 'Conf_Rew_Resp'; %BOTH pellet and shock outcomes go into REW_RESP
                
            end
        end
        
        % Store Data
        if ~isempty(cond_field)
            data_seg = valid_traces(trace_idx, trace_cols);
            if contains(state_str, 'State_1', 'IgnoreCase', true) || contains(state_str, '1')
                RawData.(rat).(cond_field).S1 = [RawData.(rat).(cond_field).S1; data_seg];
            elseif contains(state_str, 'State_2', 'IgnoreCase', true) || contains(state_str, '2')
                RawData.(rat).(cond_field).S2 = [RawData.(rat).(cond_field).S2; data_seg];
            elseif contains(state_str, 'State_3', 'IgnoreCase', true) || contains(state_str, '3')
                RawData.(rat).(cond_field).S3 = [RawData.(rat).(cond_field).S3; data_seg];
            % elseif contains(state_str, 'State_4', 'IgnoreCase', true) || contains(state_str, '4')
            %     RawData.(rat).(cond_field).S4 = [RawData.(rat).(cond_field).S4; data_seg];
            end
        end
   end
end

fprintf('\nAlignment Results:\n');
fprintf('  ✅ Successfully aligned: %d responses\n', matches_found);
fprintf('  ❌ Failed alignments: %d responses\n', failed_alignments);

%% --- 4. Subject Means & Thresholding QC ---
fprintf('\n--- CALCULATING MEANS & CHECKING TRIAL COUNTS ---\n');
GroupData = struct();
for c = 1:length(cond_names)
    GroupData.(cond_names{c}).S1 = [];
    GroupData.(cond_names{c}).S2 = [];
    GroupData.(cond_names{c}).S3 = [];
    % GroupData.(cond_names{c}).S4 = [];
end

qc_report = {}; 
states = {'S1', 'S2', 'S3'};%, 'S4'};
rats = fieldnames(RawData);

for k = 1:length(rats)
    r = rats{k};
    for c = 1:length(cond_names)
        cn = cond_names{c};
        for s = 1:length(states)
            curr_state = states{s};
            
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
    end
end

T_QC = cell2table(qc_report, 'VariableNames', {'Rat', 'Condition', 'State', 'N_Trials', 'Status'});
fprintf('\n=== QC RESPONSE COUNT REPORT ===\n');
disp(T_QC);

%% --- 5. Generate the 4 Plots ---
fprintf('Generating 4 Response Plots...\n');
y_lims = [-2 8]; 
consec_threshold = 8;
p_val = 0.05;
% Plot 1: Reward Responses
sig_S123R = createComparisonPlot_3way(GroupData.Rew_Resp.S1, GroupData.Rew_Resp.S2, GroupData.Rew_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    ['RewDS Responses (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% Plot 2: Punishment Responses 
% sig_S123P = createComparisonPlot_3way(GroupData.Pun_Resp.S4, GroupData.Pun_Resp.S2, GroupData.Pun_Resp.S3, ...
%     'State 4', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
%     ['PunDS Responses (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% Plot 3: Conflict Responses -> COMBINED Pellet AND SHOCK Outcome
sig123C_Pellet = createComparisonPlot_3way(GroupData.Conf_Rew_Resp.S1, GroupData.Conf_Rew_Resp.S2, GroupData.Conf_Rew_Resp.S3, ...
    'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
    ['Conflict Responses (Pellet) (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% Plot 3: Conflict Responses -> S1 vs S2
sig12C = createComparisonPlot(GroupData.Conf_Rew_Resp.S1, GroupData.Conf_Rew_Resp.S2, ...
    'State 1', 'State 2', c_s1, c_s2, c_perm, ...
    ['Conflict Responses (ALL) (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% 
% % % Plot 4: Conflict Responses -> Shock Outcome
% % createComparisonPlot_3way(GroupData.Conf_Pun_Resp.S1, GroupData.Conf_Pun_Resp.S2, GroupData.Conf_Pun_Resp.S3, ...
% %     'State 1', 'State 2', 'State 3', c_s1, c_s2, c_s3, c_perm, ...
% %     ['Conflict (Shock) Responses (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);
% 
% % % Plot 5: Conflict Responses -> State 1 vs 2
% createComparisonPlot(GroupData.Conf_Rew_Resp.S1, GroupData.Conf_Rew_Resp.S2, ...
%     'State 1', 'State 2', c_s1, c_s2, c_perm, ...
%     ['Conflict Responses (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);
% 
% % Plot 6: State 1 Response - rewDS vs confDS
sigS1CvR = createComparisonPlot(GroupData.Conf_Rew_Resp.S1, GroupData.Rew_Resp.S1, ...
    'confDS', 'rewDS', c_conf, c_rewDS, c_perm, ...
    ['State 1 Response - rewDS vs confDS (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);
% % 
% % % Plot 7: State 2 Response - punDS vs confDS
sigS2CvP = createComparisonPlot(GroupData.Conf_Rew_Resp.S2, GroupData.Pun_Resp.S2, ...
     'confDS', 'punDS', c_conf, c_punDS, c_perm, ...
     ['State 2 Response - punDS vs confDS (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);
% 
% % Plot 8: State 2 Response - rewDS vs confDS
sigS2CvR = createComparisonPlot(GroupData.Conf_Rew_Resp.S2, GroupData.Rew_Resp.S2, ...
    'confDS', 'rewDS', c_conf, c_rewDS, c_perm, ...
    ['State 2 Response - rewDS vs confDS (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);
% % 
% % % Plot 8: State 1 Response - punDS vs confDS
sigS1CvP = createComparisonPlot(GroupData.Conf_Rew_Resp.S1, GroupData.Pun_Resp.S1, ...
     'confDS', 'punDS', c_conf, c_punDS, c_perm, ...
     ['State 1 Response - punDS vs confDS (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

p_val = 0.05;
% % Plot State 1 rewDS v punDS vs confDS
sig_S1 = createComparisonPlot(GroupData.Conf_Rew_Resp.S1, GroupData.Rew_Resp.S1, ...
     'confDS', 'rewDS', c_conf, c_rewDS, c_perm, ...
     ['State 1 - rewDS v confDS(Both) (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% % Plot State 2 - rewDS vs dpunDS vs confDS
% sig_S2 = createComparisonPlot_3way(GroupData.Conf_Rew_Resp.S2, GroupData.Pun_Resp.S2, GroupData.Rew_Resp.S2, ...
%      'confDS', 'punDS', 'rewDS', c_conf, c_punDS, c_rewDS, c_perm, ...
%      ['State 2 - rewDS vs punDS vs confDS(Both) (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

% % Plot State 3 Response - rewDS vs punDS vs confDS
% sig_S3 = createComparisonPlot(GroupData.Pun_Resp.S2, GroupData.Conf_Rew_Resp.S2, ...
%      'confDS', 'punDS', c_conf, c_punDS, c_perm, ...
%      ['State 2 rewDS vs punDS vs confDS(Both) (Min ' num2str(min_trials_threshold) ')'], time_window, p_val, consec_threshold, y_lims);

fprintf('✅ All plots generated.\n');