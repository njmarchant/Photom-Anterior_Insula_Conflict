%% HMM Model Integration: Response-Aligned (-15 to +15) for Alcohol Challenge
%  Goal: Separate RESPONSE traces (events 5 & 6) by Cue x State x Outcome.
%  Alignment: Reconstructs Trial TS from Response TS to find Excel State and Cue.
%  Excludes the first 15 mins of acute sedation.
clear all; close all; clc;

%% --- 1. Configuration & Setup ---
% Paths 
path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)\with_resp_traces';
path_csv   = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Conflict_02_Alc_tests_UPDATED_v2_with_Probabilities.csv';

% Analysis Parameters
crop_pre  = 15;   % s before the press to keep
crop_post = 15;   % s after the press to keep
p_val = 0.05;
y_lims = [-2 8]; 
consec_threshold = 8;

% Threshold Setting: Min trials per state to include rat in average
min_trials_threshold = 5; 
exclude_first_15_mins = true; % Toggle to ignore the absorption spike (Timestamp < 900)

% Publication Target Colors (Matching your exact hex triad vectors)
c_saline  = [0.00, 0.45, 0.74];  % Blue for Saline
c_alcohol = [0.85, 0.33, 0.10];  % Red/Orange for Alcohol High
rgb_state1 = [176/255, 179/255, 0/255];  % #B0B300 (Yellow/Orange)
rgb_state3 = [0/255, 176/255, 179/255];  % #00B0B3 (Blue/Teal)
c_perm    = [0.5, 0.5, 0.5];     % Gray for permutation windows

%% --- 2. Load and Clean Excel/CSV Data ---
fprintf('Loading CSV Data...\n');
try
    T = readtable(path_csv, 'TextType', 'string');
catch ME
    error('Failed to load CSV file. Check path.\nError: %s', ME.message);
end

% --- The Cleaning Block (Ensures perfect ID tracking) ---
clean_rats = strings(height(T), 1);
for i = 1:height(T)
    val = regexprep(string(T.Rat(i)), '\D', ''); % Extract only numeric digits
    if ~isempty(val) && strlength(val) > 0
        num_val = str2double(val);
        if num_val < 10
            clean_rats(i) = sprintf('R0%d', num_val);
        else
            clean_rats(i) = sprintf('R%d', num_val); 
        end
    else
        clean_rats(i) = string(T.Rat(i)); 
    end
end
T.Rat = clean_rats;
T.Session_Type = strtrim(string(T.Session_Type)); % Trims invisible trailing spaces
T.Date = strtrim(string(T.Date));
fprintf('✅ CSV loaded and cleaned. Rows: %d\n', height(T));

%% --- 3. Data Extraction & Reverse Alignment ---
fprintf('Processing Files & Reconstructing Timestamps...\n');
files = dir(fullfile(path_data, '*.mat'));

cond_names = {'Rew_Resp', 'Pun_Resp', 'Conf_Rew_Resp', 'Conf_Pun_Resp'};
sessions_to_compare = {'Saline', 'Alcohol_Low', 'Alcohol_High'};
states_to_analyze = [1, 2, 3];

RawData = struct(); 
time_window = [];   % Populated from the first valid file
n_cols_ref  = [];   % Number of samples every file must match
matches_found = 0;
failed_alignments = 0;

for i = 1:length(files)
    filename = files(i).name;
    try, load(fullfile(path_data, filename), 'sesdat'); catch, continue; end
    
    rat = strrep(string(sesdat.rat), "'", ""); 
    session = strtrim(string(sesdat.ses));
    
    if isfield(sesdat, 'date')
        d1 = strtrim(string(sesdat.date));
    else
        continue; % Skip files without structural dates
    end
    
    if ~ismember(session, sessions_to_compare), continue; end
    
    % Core response-aligned traces array
    traces = sesdat.traces_z_resp;

    % --- Crop to [-crop_pre, +crop_post] s around the press ---
    t_resp = sesdat.traces_resp_time;
    i0 = find(abs(t_resp) < 1e-9, 1);                          % sample at the press
    c0 = i0 - ceil(crop_pre  * sesdat.conversion);
    c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
    trace_cols = 4 + (c0 : c1);                                % +4 skips the header columns

    % All files must have the same number of samples after the crop
    if isempty(n_cols_ref)
        n_cols_ref  = numel(trace_cols);
        time_window = t_resp(c0:c1);                           % exact time axis from the data
    elseif numel(trace_cols) ~= n_cols_ref
        fprintf('  SKIP %s: %d samples after crop (expected %d)\n', ...
            filename, numel(trace_cols), n_cols_ref);
        continue;
    end
    
    % Initialize structural fields dynamically per animal
    if ~isfield(RawData, rat)
        for c = 1:length(cond_names)
            for s = states_to_analyze
                for sn = 1:length(sessions_to_compare)
                    sess_safe = sessions_to_compare{sn};
                    RawData.(rat).(cond_names{c}).(sprintf('S%d', s)).(sess_safe) = [];
                end
            end
        end
    end
    
    % Filter for RESPONSES ONLY (Column 2 == 5 [Pellet Press] or 6 [Shock Press])
    % and drop responses with NaN anywhere in the cropped window
    valid_mask = ismember(traces(:, 2), [5, 6]) & ~any(isnan(traces(:, trace_cols)), 2); 
    valid_traces = traces(valid_mask, :);
    if isempty(valid_traces), continue; end
    
    % Locate matching CSV rows based on unique Rat, Treatment, and Date
    excel_mask = strcmp(T.Rat, rat) & strcmp(T.Session_Type, session) & strcmp(T.Date, d1);
    session_data = T(excel_mask, :);
    if isempty(session_data), continue; end
    
    % Loop through each extracted response trace segment
    for trace_idx = 1:size(valid_traces, 1)
        resp_ts = valid_traces(trace_idx, 1); 
        outcome = valid_traces(trace_idx, 2); 
        latency = valid_traces(trace_idx, 3); 
        
        % --- REVERSE ALIGNMENT MATH ---
        expected_trial_ts = resp_ts - 10 - latency;
        
        % Safety Gate: Apply clock time filter to exclude the sedation block
        if exclude_first_15_mins && expected_trial_ts <= 900
            continue; 
        end
        
        % Match to the nearest trial row inside the spreadsheet
        ts_diffs = abs(session_data.Timestamp - expected_trial_ts);
        [min_diff, row_idx] = min(ts_diffs);
        
        if isempty(min_diff) || min_diff > 0.15
            failed_alignments = failed_alignments + 1;
            continue; 
        end
        matches_found = matches_found + 1;
        
        % Fetch Latent State Assignment
        state_num = session_data.Inferred_State(row_idx);
        if iscell(state_num), state_num = state_num{1}; end
        if isstring(state_num) || ischar(state_num), state_num = str2double(state_num); end
        if isnan(state_num) || isempty(state_num), continue; end
        state_num = round(state_num); 
        
        % Fetch Cue Gating Context
        cue_str = lower(string(session_data.Cue(row_idx)));
        cond_field = '';
        
        if contains(cue_str, 'reward')
            cond_field = 'Rew_Resp';
        elseif contains(cue_str, 'punish')
            cond_field = 'Pun_Resp';
        elseif contains(cue_str, 'conflict')
            if outcome == 5
                cond_field = 'Conf_Rew_Resp';
            elseif outcome == 6
                cond_field = 'Conf_Pun_Resp'; 
            end
        end
        
        % Append clean trace data directly to target structural arrays
        if ~isempty(cond_field) && ismember(state_num, states_to_analyze)
            data_seg = valid_traces(trace_idx, trace_cols);
            state_label = sprintf('S%d', state_num);
            RawData.(rat).(cond_field).(state_label).(session) = ...
                [RawData.(rat).(cond_field).(state_label).(session); data_seg];
        end
    end
end

fprintf('\nAlignment Results:\n');
fprintf('  ✅ Successfully aligned: %d responses\n', matches_found);
fprintf('  ❌ Failed alignments: %d responses\n', failed_alignments);

%% --- 4. Subject Means & Thresholding QC ---
fprintf('\n--- CALCULATING SUBJECT MEANS (COLLAPSING SESSIONS) ---\n');
GroupData = struct();
for c = 1:length(cond_names)
    for s = states_to_analyze
        for sn = 1:length(sessions_to_compare)
            GroupData.(cond_names{c}).(sprintf('S%d', s)).(sessions_to_compare{sn}) = [];
        end
    end
end

rats = fieldnames(RawData);
for k = 1:length(rats)
    r = rats{k};
    for c = 1:length(cond_names)
        cn = cond_names{c};
        for s = states_to_analyze
            sl = sprintf('S%d', s);
            for sn = 1:length(sessions_to_compare)
                sess = sessions_to_compare{sn};
                
                traces = RawData.(r).(cn).(sl).(sess);
                n_trials = size(traces, 1);
                
                % Enforce minimum trial count to exclude sparse data noise
                if n_trials >= min_trials_threshold
                    avg_trace = mean(traces, 1, 'omitnan');
                    GroupData.(cn).(sl).(sess) = [GroupData.(cn).(sl).(sess); avg_trace];
                end
            end
        end
    end
end
fprintf('✅ Group arrays compiled successfully.\n');

%% --- 5. Generate Response Comparison Plots ---
% We run 2-way comparison plots to ensure absolute robustness against 
% missing data constraints (avoiding State 2 crashes).

% =========================================================================
% PLOT TYPE A: Saline vs Alcohol High per Strategy Group (States 1 and 3)
% =========================================================================
fprintf('\n--- Generating Plot Type A: Saline vs Alcohol High ---\n');
plots_typeA = 0;
stats = struct();
for c = 1:length(cond_names)
    cn = cond_names{c};
    for s = [1, 3] % Focus purely on States 1 and 3 to handle State 2 dropout safely
        sl = sprintf('S%d', s);
        
        data_sal = GroupData.(cn).(sl).Saline;
        data_alc = GroupData.(cn).(sl).Alcohol_High;
        
        % Ensure both cells pass the minimum subject requirement for permutation tests
        if size(data_sal, 1) >= 3 && size(data_alc, 1) >= 3
            
            % Generate descriptive labels
            title_label = strrep(cn, '_', ' ');
            title_label = strrep(title_label, 'Rew Resp', 'Reward Press');
            title_label = strrep(title_label, 'Pun Resp', 'Punish Press');
            title_label = strrep(title_label, 'Conf Rew Resp', 'Conflict Press (Pellet)');
            title_label = strrep(title_label, 'Conf Pun Resp', 'Conflict Press (Shock)');
            state_title = sprintf('State %d', s);
            
            fig_title = sprintf('%s - %s [Saline vs Alc High]', title_label, state_title);
            field_name = sprintf('sig_%s_State%d', cn, s);
            % Call the 2-way comparison plotting engine
            stats.(field_name) = createComparisonPlot(data_sal, data_alc, 'Saline', 'Alcohol High', ...
                c_saline, c_alcohol, c_perm, fig_title, time_window, p_val, consec_threshold, y_lims);
                
            plots_typeA = plots_typeA + 1;
        end
    end
end

% =========================================================================
% PLOT TYPE B: Strategy 1 vs Strategy 3 Cross-Comparison WITHIN Alcohol High
% =========================================================================
fprintf('\n--- Generating Plot Type B: State 1 vs State 3 Within Alcohol High ---\n');
plots_typeB = 0;

for c = 1:length(cond_names)
    cn = cond_names{c};
    
    % Extract Alcohol High traces for active goal-directed vs autopilot choices
    traces_s1_alc = GroupData.(cn).S1.Alcohol_High;
    traces_s3_alc = GroupData.(cn).S3.Alcohol_High;
    
    if size(traces_s1_alc, 1) >= 3 && size(traces_s3_alc, 1) >= 3
        
        title_label = strrep(cn, '_', ' ');
        title_label = strrep(title_label, 'Rew Resp', 'Reward Press');
        title_label = strrep(title_label, 'Pun Resp', 'Punish Press');
        title_label = strrep(title_label, 'Conf Rew Resp', 'Conflict Press (Pellet)');
        title_label = strrep(title_label, 'Conf Pun Resp', 'Conflict Press (Shock)');
        
        fig_title = sprintf('%s: State 1 vs State 3 [Alcohol High Only]', title_label);
        
        % Call 2-way plot using exact publication color schemes
        createComparisonPlot(traces_s1_alc, traces_s3_alc, 'State 1 (Risk-Taking)', 'State 3 (Repeating)', ...
            rgb_state1, rgb_state3, c_perm, fig_title, time_window, p_val, consec_threshold, y_lims);
            
        plots_typeB = plots_typeB + 1;
    end
end

fprintf('\n✅ Execution finished. Figures generated: Type A = %d, Type B = %d\n', plots_typeA, plots_typeB);