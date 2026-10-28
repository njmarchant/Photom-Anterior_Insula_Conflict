%% HMM Model Integration: Response-Aligned Phenotype Analysis
%  Goal: Separate RESPONSE traces by Phenotype Cluster x Cue x State x Outcome.
%  Alignment: Reconstructs Trial TS from Response TS to find Excel State and Cue.
clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths 
path_data   = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';
path_pheno  = fullfile(fileparts(path_excel), 'Rat_Phenotype_Classifications.csv');

% Analysis Parameters
time_bounds = [-25, 15]; 
p_val = 0.05;
y_lims = [-2 8]; 
min_trials_threshold = 5; % Min trials per state to include rat in average

% -----------------------------
% Colors
c_s1 = [0.69, 0.70, 0.00]; % Orange/Yellow (State 1)
c_s2 = [0.71, 0.00, 0.70]; % Red/Pink (State 2)
c_s3 = [0.00, 0.69, 0.70]; % Blue/Teal (State 3)
c_perm = [0.5, 0.5, 0.5];  

% Phenotype specific colors
c_tolerant = [0.40, 0.75, 0.20]; % Green for Risk-Tolerant group
c_averse   = [0.85, 0.20, 0.25]; % Crimson for Risk-Averse group

%% --- 2. Load and Clean Excel Data ---
fprintf('Loading Behavioral & Phenotype Datasets...\n');
try
    T = readtable(path_excel);
    T_pheno = readtable(path_pheno);
catch ME
    error('Failed to load tracking data or phenotype CSV. Check paths.\nError: %s', ME.message);
end
T.Session_Clean = string(T.Session); 

%% --- 3. Data Extraction & Reverse Alignment ---
fprintf('Processing Files & Reconstructing Timestamps...\n');
files = dir(fullfile(path_data, '*.mat'));
cond_names = {'Rew_Resp', 'Pun_Resp', 'Conf_Rew_Resp', 'Conf_Pun_Resp'};
RawData = struct(); 
time_window = []; 

matches_found = 0;
failed_alignments = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_25_15;
    
    if ~isfield(RawData, rat)
        for c = 1:length(cond_names)
            RawData.(rat).(cond_names{c}).S1 = [];
            RawData.(rat).(cond_names{c}).S2 = [];
            RawData.(rat).(cond_names{c}).S3 = [];
        end
    end
    
    valid_mask = ismember(traces(:, 2), [5, 6]); 
    valid_traces = traces(valid_mask, :);
    
    excel_mask = strcmp(string(T.Rat), rat) & strcmp(T.Session_Clean, string(session));
    session_data = T(excel_mask, :);
    if isempty(session_data), continue; end
    
    if isempty(time_window) && ~isempty(valid_traces)
        time_window = linspace(time_bounds(1), time_bounds(2), size(valid_traces, 2) - 4);
    end
    
    for trace_idx = 1:size(valid_traces, 1)
        resp_ts    = valid_traces(trace_idx, 1); 
        outcome    = valid_traces(trace_idx, 2); % 5 = Pellet, 6 = Shock
        latency    = valid_traces(trace_idx, 3); 
        
        expected_trial_ts = resp_ts - 10 - latency;
        ts_diffs = abs(session_data.Timestamp - expected_trial_ts);
        [min_diff, row_idx] = min(ts_diffs);
        
        if isempty(min_diff) || min_diff > 0.15
            failed_alignments = failed_alignments + 1;
            continue; 
        end
        matches_found = matches_found + 1;
        
        state_str = string(session_data.Inferred_State(row_idx));
        if contains(state_str, 'inconclusive', 'IgnoreCase', true), continue; end
        
        cue_str = lower(string(session_data.Cue(row_idx)));
        cond_field = '';
        
        if contains(cue_str, 'reward')
            cond_field = 'Rew_Resp';
        elseif contains(cue_str, 'punish')
            cond_field = 'Pun_Resp';
        elseif contains(cue_str, 'conflict')
            % FIXED: Cleanly separating pellet choices from shocked choices
            if outcome == 5
                cond_field = 'Conf_Rew_Resp';
            elseif outcome == 6
                cond_field = 'Conf_Pun_Resp'; 
            end
        end
        
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

%% --- 4. Phenotype Sorting & Subject Means ---
fprintf('\n--- SEPARATING SUBJECT MEANS BY GMM PHENOTYPE ---\n');

pheno_fields = {'Tolerant', 'Averse'};
GroupData = struct();

% Corrected cell indexing to guarantee valid structure field names
for p = 1:length(pheno_fields)
    pf = pheno_fields{p}; 
    for c = 1:length(cond_names)
        cn = cond_names{c};
        GroupData.(pf).(cn).S1 = [];
        GroupData.(pf).(cn).S2 = [];
        GroupData.(pf).(cn).S3 = [];
        GroupData.(pf).(cn).S1_S2_Combined = []; 
    end
end

rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    
    p_idx = find(strcmp(string(T_pheno.Rat), r));
    if isempty(p_idx), continue; end
    
    raw_pheno_str = T_pheno.Phenotype{p_idx};
    if contains(raw_pheno_str, 'Tolerant')
        pf = 'Tolerant';
    elseif contains(raw_pheno_str, 'Averse')
        pf = 'Averse';
    else
        continue;
    end
    
    for c = 1:length(cond_names)
        cn = cond_names{c};
        
        % Process single HMM states
        states = {'S1', 'S2', 'S3'};
        for s = 1:length(states)
            curr_state = states{s};
            traces = RawData.(r).(cn).(curr_state);
            if size(traces, 1) >= min_trials_threshold
                GroupData.(pf).(cn).(curr_state) = [GroupData.(pf).(cn).(curr_state); mean(traces, 1, 'omitnan')];
            end
        end
        
        % PLOT SET 2 CONFIG: Pool raw response traces across State 1 and State 2
        combined_s1_s2 = [RawData.(r).(cn).S1; RawData.(r).(cn).S2; RawData.(r).(cn).S3];
        if size(combined_s1_s2, 1) >= min_trials_threshold
            GroupData.(pf).(cn).S1_S2_Combined = [GroupData.(pf).(cn).S1_S2_Combined; mean(combined_s1_s2, 1, 'omitnan')];
        end
    end
end

%% --- 5. Generate Target Phenotype Figures ---
fprintf('Generating Target Response Plots...\n');
consec_threshold = 8;

%% ========================================================================
%  PLOT SET 1: CONFLICT RESPONSES — PHENOTYPE VS PHENOTYPE (BY STATE/OUTCOME)
%  ========================================================================

% A. State 1 (Risk-Taking Mindset) — Response leading to Pellet Delivery
createComparisonPlot(GroupData.Tolerant.Conf_Rew_Resp.S1, GroupData.Averse.Conf_Rew_Resp.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Response Blast: State 1 -> Pellet Outcome', time_window, p_val, consec_threshold, y_lims);

% B. State 1 (Risk-Taking Mindset) — Response leading to Shock Delivery
createComparisonPlot(GroupData.Tolerant.Conf_Pun_Resp.S1, GroupData.Averse.Conf_Pun_Resp.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Response Blast: State 1 -> Shock Outcome', time_window, p_val, consec_threshold, y_lims);

% A. State 1 
createComparisonPlot(GroupData.Tolerant.Rew_Resp.S1, GroupData.Averse.Rew_Resp.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'rewDS: State 1 -> Pellet Outcome', time_window, p_val, consec_threshold, y_lims);

% B. State 1 
createComparisonPlot(GroupData.Tolerant.Pun_Resp.S1, GroupData.Averse.Pun_Resp.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'punDS: State 1 -> Shock Outcome', time_window, p_val, consec_threshold, y_lims);


% A. State 2 
createComparisonPlot(GroupData.Tolerant.Rew_Resp.S2, GroupData.Averse.Rew_Resp.S2, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'rewDS: State 2 -> Pellet Outcome', time_window, p_val, consec_threshold, y_lims);

% B. State 2 
createComparisonPlot(GroupData.Tolerant.Pun_Resp.S2, GroupData.Averse.Pun_Resp.S2, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'punDS: State 2 -> Shock Outcome', time_window, p_val, consec_threshold, y_lims);

% % C. State 2 (Risk-Averse Mindset) — Response leading to Pellet Delivery
% createComparisonPlot(GroupData.Tolerant.Conf_Rew_Resp.S2, GroupData.Averse.Conf_Rew_Resp.S2, ...
%     'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
%     'Response Blast: State 2 -> Pellet Outcome', time_window, p_val, consec_threshold, y_lims);

% % D. State 2 (Risk-Averse Mindset) — Response leading to Shock Delivery
% createComparisonPlot(GroupData.Tolerant.Conf_Pun_Resp.S2, GroupData.Averse.Conf_Pun_Resp.S2, ...
%     'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
%     'Response Blast: State 2 -> Shock Outcome', time_window, p_val, consec_threshold, y_lims);

%% ========================================================================
%  PLOT SET 2: POOLED ACTIVE MINDSETS (S1 + S2 +S3)
%  ========================================================================

% Risk-Tolerant Group: Do their brains process receiving a reward vs shock differently?
createComparisonPlot(GroupData.Tolerant.Conf_Rew_Resp.S1_S2_Combined, GroupData.Tolerant.Conf_Pun_Resp.S1_S2_Combined, ...
    'Pellet Outcome', 'Shock Outcome', c_tolerant, c_tolerant*0.5, c_perm, ...
    'Risk-Tolerant Phenotype: S1+S2+S3 Combined (Pellet vs Shock)', time_window, p_val, consec_threshold, y_lims);

% Risk-Averse Group: Do their brains process receiving a reward vs shock differently?
createComparisonPlot(GroupData.Averse.Conf_Rew_Resp.S1_S2_Combined, GroupData.Averse.Conf_Pun_Resp.S1_S2_Combined, ...
    'Pellet Outcome', 'Shock Outcome', c_averse, c_averse*0.5, c_perm, ...
    'Risk-Averse Phenotype: S1+S2+S3 Combined (Pellet vs Shock)', time_window, p_val, consec_threshold, y_lims);


createComparisonPlot(GroupData.Tolerant.Conf_Rew_Resp.S1_S2_Combined, GroupData.Averse.Conf_Rew_Resp.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_tolerant, c_tolerant*0.5, c_perm, ...
    'Conflict Reward: S1+S2+S3 Combined (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);


createComparisonPlot(GroupData.Tolerant.Conf_Pun_Resp.S1_S2_Combined, GroupData.Averse.Conf_Pun_Resp.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_averse, c_averse*0.5, c_perm, ...
    'Conflict Shock: S1+S2+S3 Combined (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);

createComparisonPlot(GroupData.Tolerant.Pun_Resp.S1_S2_Combined, GroupData.Averse.Pun_Resp.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_averse, c_averse*0.5, c_perm, ...
    'PunDS: S1+S2+S3 Combined (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);

createComparisonPlot(GroupData.Tolerant.Rew_Resp.S1_S2_Combined, GroupData.Averse.Rew_Resp.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_averse, c_averse*0.5, c_perm, ...
    'RewDS: S1+S2+S3 Combined (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);

fprintf('✅ All phenotypic response plots generated successfully.\n');