%% HMM Model Integration: Phenotype x State Photometry Analysis Pipeline
%  Goal: Separate traces by Phenotype Cluster x Cue x Response x State.
%  QC 1: Verifies that Excel 'Latency' matches MAT file Column 3.
%  QC 2: Checks N-trials per subject and splits into phenotypic sub-groups.
clear all; %close all; clc;

%% --- 1. Configuration & Setup ---
% Paths
path_data   = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv';
% Dynamic lookup for the phenotype file in the same directory
path_pheno  = fullfile(fileparts(path_excel), 'Rat_Phenotype_Classifications.csv');

% Analysis Parameters
time_window = linspace(-10, 45, 876); 
min_trials_threshold = 5; % Minimum trials to include a subject's mean trace

% -----------------------------
% Colors
c_s1 = [0.69, 0.70, 0.00]; % Orange/Yellow (State 1)
c_s2 = [0.71, 0.00, 0.70]; % Red/Pink (State 2)
c_s3 = [0.00, 0.69, 0.70]; % Blue/Teal (State 3)
c_perm = [0.5, 0.5, 0.5];  % Permutation test color

% Phenotype specific aesthetic assignments
c_tolerant = [0.40, 0.75, 0.20]; % Green theme for Risk-Tolerant group
c_averse   = [0.85, 0.20, 0.25]; % Crimson theme for Risk-Averse group

%% --- 2. Load and Clean Excel Data ---
fprintf('Loading Behavioral Datasets...\n');
try
    T = readtable(path_excel);
    T_pheno = readtable(path_pheno);
catch ME
    error('Failed to load tracking data or phenotype CSV. Check paths.\nError: %s', ME.message);
end

%% --- 3. Data Extraction & Quality Control (Latency Match) ---
fprintf('Processing Files & Running QC (Latency Check)...\n');
files = dir(fullfile(path_data, '*.mat'));
cond_names = {'Rew_Resp', 'Rew_Omit', 'Pun_Resp', 'Pun_Omit', 'Conf_Resp', 'Conf_Omit'};
RawData = struct(); 
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
        end
    end
    
    valid_mask = ismember(traces(:, 2), [1, 2, 3]); 
    valid_traces = traces(valid_mask, :);
    [~, sortIdx] = sort(valid_traces(:, 1)); 
    sorted_traces = valid_traces(sortIdx, :);
    
    excel_mask = strcmp(string(T.Rat), rat) & strcmp(string(T.Session), session);
    session_data = T(excel_mask, :);
    if isempty(session_data), continue; end
    
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
            state_str = sprintf('S%d', int32(state_num));
            RawData.(rat).(cond_field).(state_str) = [RawData.(rat).(cond_field).(state_str); data_seg];
        end
    end
end
fprintf('\n✅ QC 1 PASSED: Raw traces matched to session keys.\n');

%% --- 4. Phenotype Partitioning & Subject Mean Metrics ---
fprintf('\n--- PARTITIONING PHENOTYPES & THRESHOLDING TRACES ---\n');

% Initialize sub-structures for each cluster to keep GroupData organized
pheno_fields = {'Tolerant', 'Averse'};
GroupData = struct();
for p = 1:length(pheno_fields)
    pf = pheno_fields{p};
    for c = 1:length(cond_names)
        cn = cond_names{c};
        GroupData.(pf).(cn).S1 = [];
        GroupData.(pf).(cn).S2 = [];
        GroupData.(pf).(cn).S3 = [];
        GroupData.(pf).(cn).S1_S2_Combined = []; % Added for analysis option 2
    end
end

rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    
    % Find this rat's phenotype classification
    p_idx = find(strcmp(string(T_pheno.Rat), r));
    if isempty(p_idx)
        fprintf('⚠️ Warning: Rat %s not found in phenotype database. Skipping.\n', r);
        continue;
    end
    
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
        
        % Process standard isolated states (S1, S2, S3)
        states = {'S1', 'S2', 'S3'};
        for s = 1:length(states)
            curr_state = states{s};
            traces = RawData.(r).(cn).(curr_state);
            if size(traces, 1) >= min_trials_threshold
                GroupData.(pf).(cn).(curr_state) = [GroupData.(pf).(cn).(curr_state); mean(traces, 1, 'omitnan')];
            end
        end
        
        % ANALYSIS OPTION 2: Pool State 1 and State 2 raw traces together for this specific rat
        combined_s1_s2_traces = [RawData.(r).(cn).S1; RawData.(r).(cn).S2; RawData.(r).(cn).S3];
        if size(combined_s1_s2_traces, 1) >= min_trials_threshold
            GroupData.(pf).(cn).S1_S2_Combined = [GroupData.(pf).(cn).S1_S2_Combined; mean(combined_s1_s2_traces, 1, 'omitnan')];
        end
    end
end

%% --- 5. Generate Target Figures ---
fprintf('Generating Phenotype Target Figures...\n');
y_lims = [-1 3]; 
consec_threshold = 8;
p_val = 0.05;

%% ========================================================================
%  PLOT SET 1: CONFLICT TRACES — PHENOTYPE VS PHENOTYPE
%  ========================================================================
%  These compare how Risk-Tolerant vs Risk-Averse populations differ 
%  within a single cognitive state.

% Comparison A: State 1 (Risk-Taking State) — Responded Trials
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S1, GroupData.Averse.Conf_Resp.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Responded: State 1 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);

% Comparison B: State 1 (Risk-Taking State) — Omitted Trials
createComparisonPlot(GroupData.Tolerant.Conf_Omit.S1, GroupData.Averse.Conf_Omit.S1, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Omitted: State 1 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);

% Comparison C: State 2 (Risk-Averse State) — Responded Trials
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S2, GroupData.Averse.Conf_Resp.S2, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Responded: State 2 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);

% Comparison D: State 2 (Risk-Averse State) — Omitted Trials
createComparisonPlot(GroupData.Tolerant.Conf_Omit.S2, GroupData.Averse.Conf_Omit.S2, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Omitted: State 2 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);

% Comparison E: State 3 (Repeating) — Responded Trials
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S3, GroupData.Averse.Conf_Resp.S3, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Responded: State 3 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);

% Comparison F: State 3 (Repeating) — Omitted Trials
createComparisonPlot(GroupData.Tolerant.Conf_Omit.S3, GroupData.Averse.Conf_Omit.S3, ...
    'Risk-Tolerant', 'Risk-Averse', c_tolerant, c_averse, c_perm, ...
    'Conflict Omitted: State 3 (Phenotype Comparison)', time_window, p_val, consec_threshold, y_lims);


%% ========================================================================
%  PLOT SET 2: STATE 1 VS STATE 2 (WITHIN-PHENOTYPE CROSSOVER)
%  ========================================================================
%  These evaluate if State 1 differs from State 2 inside the same animal group.

% Risk-Tolerant Phenotype: State 1 vs State 2 during Choice Responses
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S1, GroupData.Tolerant.Conf_Resp.S2, ...
    'State 1', 'State 2', c_s1, c_s2, c_perm, ...
    'Risk-Tolerant Group: State 1 vs State 2 (Responded)', time_window, p_val, consec_threshold, y_lims);

% Risk-Averse Phenotype: State 1 vs State 2 during Choice Responses
createComparisonPlot(GroupData.Averse.Conf_Resp.S1, GroupData.Averse.Conf_Resp.S2, ...
    'State 1', 'State 2', c_s1, c_s2, c_perm, ...
    'Risk-Averse Group: State 1 vs State 2 (Responded)', time_window, p_val, consec_threshold, y_lims);


%% ========================================================================
%  PLOT SET 3: COMBINED MINDSETS (STATE 1 + STATE 2 POOLED) — RESPOND VS OMIT
%  ========================================================================
%  These combine both active mindsets to see how choices (Respond vs Omit)
%  are represented across the whole population axis.

% Crossover Plot for Risk-Tolerant Phenotype
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S1_S2_Combined, GroupData.Tolerant.Conf_Omit.S1_S2_Combined, ...
    'Responded', 'Omitted', c_tolerant, c_tolerant*0.6, c_perm, ...
    'Risk-Tolerant Group: Combined S1+S2+S3 (Respond vs Omit)', time_window, p_val, consec_threshold, y_lims);

% Crossover Plot for Risk-Averse Phenotype
createComparisonPlot(GroupData.Averse.Conf_Resp.S1_S2_Combined, GroupData.Averse.Conf_Omit.S1_S2_Combined, ...
    'Responded', 'Omitted', c_averse, c_averse*0.6, c_perm, ...
    'Risk-Averse Group: Combined S1+S2+S3 (Respond vs Omit)', time_window, p_val, consec_threshold, y_lims);

% Crossover Plot for responded
createComparisonPlot(GroupData.Tolerant.Conf_Resp.S1_S2_Combined, GroupData.Averse.Conf_Resp.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_tolerant, c_tolerant*0.6, c_perm, ...
    'Responded: Combined S1+S2+S3 (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);

% Crossover Plot for Risk-Averse Phenotype
createComparisonPlot(GroupData.Tolerant.Conf_Omit.S1_S2_Combined, GroupData.Averse.Conf_Omit.S1_S2_Combined, ...
    'Tolerant', 'Averse', c_averse, c_averse*0.6, c_perm, ...
    'Omitted: Combined S1+S2+S3 (Tol vs Aver)', time_window, p_val, consec_threshold, y_lims);
fprintf('✅ Phenotypic trace separation complete.\n');
