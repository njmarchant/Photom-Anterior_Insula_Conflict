%% Combined Analysis: Operant vs Pavlovian (Outcome Analysis)
%% UPDATED: Subject Means, Yoked Session Mapping (CSV), Function Plotting, -15 to +15 crop
clear all

% --- 1. Configuration & Setup ---
condition = 'Pun Late';
s = char(condition);
min_trials = 3;   % Minimum trials required per rat for inclusion
crop_pre   = 15;  % s before the press to keep
crop_post  = 15;  % s after the press to keep

% --- Load Mapping for Yoked Sessions ---
% Load the session map table (Assumes file is in current directory)
sess_map = readtable('C:\Photometry\Conflict_04\Raw data\Conflict_02_sessions_Conf_4_Included_ONLY.csv', 'TextType', 'string');

% Define Target Punishment Sessions based on condition
if strcmp(condition, 'Pun Early')
    target_p4_sessions = ["P01", "P02", "P03"];
    sessions_pavlovian = {'P01', 'P02', 'P03'}; % Aligned for Pavlovian extraction
else
    target_p4_sessions = ["P04", "P05", "P06", "P07"];
    sessions_pavlovian = {'P04', 'P05', 'P06', 'P07'};
end

% Filter the map: Keep only rows corresponding to the target Pun sessions
sess_map_filtered = sess_map(ismember(sess_map.Session, target_p4_sessions), :);

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(10-45)\with_resp_traces';
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Pun_(10-45)\with_resp_traces';
rats_pavlovian = {'R02','R05','R06','R07','R08','R09','R12','R13','R14'};

% --- Initialize Data Structures ---
cond_list = {'RewOut', 'PunOut'};

OpRatData = struct();
PavRatData = struct();

for r = 1:length(rats_operant)
    for c = 1:length(cond_list) OpRatData.(rats_operant{r}).(cond_list{c}) = []; end
end

for r = 1:length(rats_pavlovian)
    for c = 1:length(cond_list) PavRatData.(rats_pavlovian{r}).(cond_list{c}) = []; end
end

%% 2. Extraction: Operant Data (Folder 1)
fprintf('------------------------------------------------\n');
fprintf('Processing Operant Data (Folder 1)...\n');
filesAndFolders = dir(fullfile(path_operant));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

n_cols_op = [];   % Number of samples every Operant file must match

for i = 1:length(files)
    filename = files(i).name;
    
    % FILTER LOGIC: Check filename against rat list BEFORE loading
    if contains(filename, rats_operant)
        load(fullfile(path_operant, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z_resp;

        % --- Crop to [-crop_pre, +crop_post] s around the press ---
        t_resp = sesdat.traces_resp_time;
        i0 = find(abs(t_resp) < 1e-9, 1);                          % sample at the press
        c0 = i0 - ceil(crop_pre  * sesdat.conversion);
        c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
        trace_cols = 4 + (c0 : c1);                                % +4 skips the header columns

        if isempty(n_cols_op)
            n_cols_op = numel(trace_cols);
        elseif numel(trace_cols) ~= n_cols_op
            fprintf('  SKIP %s: %d samples after crop (expected %d)\n', filename, numel(trace_cols), n_cols_op);
            continue;
        end
        
        % --- Dynamic Session Check (Yoking) ---
        % Construct the column name for this rat in the CSV
        col_name = ['Conf_2_', rat]; % <--- CHANGE 'Pun_2_' IF YOUR CSV HEADER IS DIFFERENT
        
        if ismember(col_name, sess_map_filtered.Properties.VariableNames)
            allowed_sessions = sess_map_filtered.(col_name);
            
            if ismember(session, allowed_sessions)
                fprintf('  -> Op Adding %s - %s\n', rat, session);
                valid_rows = ~any(isnan(traces(:, trace_cols)), 2);
                
                % --- Define Masks (Outcomes) ---
                % 5 = Reward Outcome, 6 = Shock Outcome
                is_rew_out = traces(:, 2) == 5; 
                is_pun_out = traces(:, 2) == 6;
                
                % Append to Subject Struct
                OpRatData.(rat).RewOut = [OpRatData.(rat).RewOut; traces(valid_rows & is_rew_out, trace_cols)];
                OpRatData.(rat).PunOut = [OpRatData.(rat).PunOut; traces(valid_rows & is_pun_out, trace_cols)];
            end
        end
    end
end

%% 3. Extraction: Pavlovian Data (Folder 2)
fprintf('------------------------------------------------\n');
fprintf('Processing Pavlovian Data (Folder 2)...\n');
filesAndFolders = dir(fullfile(path_pavlovian));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

n_cols_pav = [];   % Number of samples every Pavlovian file must match

for i = 1:length(files)
    filename = files(i).name;
    
    % FILTER LOGIC: Check filename against lists BEFORE loading
    if contains(filename, rats_pavlovian) && contains(filename, sessions_pavlovian)
        load(fullfile(path_pavlovian, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z_resp;

        % --- Same crop as the Operant data ---
        t_resp = sesdat.traces_resp_time;
        i0 = find(abs(t_resp) < 1e-9, 1);
        c0 = i0 - ceil(crop_pre  * sesdat.conversion);
        c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
        trace_cols = 4 + (c0 : c1);

        if isempty(n_cols_pav)
            n_cols_pav = numel(trace_cols);
        elseif numel(trace_cols) ~= n_cols_pav
            fprintf('  SKIP %s: %d samples after crop (expected %d)\n', filename, numel(trace_cols), n_cols_pav);
            continue;
        end
        
        fprintf('  -> Pav Adding %s - %s\n', rat, session);
        valid_rows = ~any(isnan(traces(:, trace_cols)), 2);
        
        % --- Define Masks (Outcomes) ---
        is_rew_out = traces(:, 2) == 5;
        is_pun_out = traces(:, 2) == 6;
        
        % Append to Subject Struct
        PavRatData.(rat).RewOut = [PavRatData.(rat).RewOut; traces(valid_rows & is_rew_out, trace_cols)];
        PavRatData.(rat).PunOut = [PavRatData.(rat).PunOut; traces(valid_rows & is_pun_out, trace_cols)];
    end
end
fprintf('✅ Data extraction complete.\n');

%% 4. Calculate Subject Means
fprintf('Calculating Subject Means (Min trials = %d)...\n', min_trials);

OpGroupData = struct();
PavGroupData = struct();
for c = 1:length(cond_list)
    OpGroupData.(cond_list{c}) = [];
    PavGroupData.(cond_list{c}) = [];
end

% Operant Means
for i = 1:length(rats_operant)
    ratID = rats_operant{i};
    for c = 1:length(cond_list)
        cn = cond_list{c};
        traces_sub = OpRatData.(ratID).(cn);
        if size(traces_sub, 1) >= min_trials
            OpGroupData.(cn) = [OpGroupData.(cn); mean(traces_sub, 1, 'omitnan')];
        end
    end
end

% Pavlovian Means
for i = 1:length(rats_pavlovian)
    ratID = rats_pavlovian{i};
    for c = 1:length(cond_list)
        cn = cond_list{c};
        traces_sub = PavRatData.(ratID).(cn);
        if size(traces_sub, 1) >= min_trials
            PavGroupData.(cn) = [PavGroupData.(cn); mean(traces_sub, 1, 'omitnan')];
        end
    end
end

%% 5. Plotting Configuration & Dimension Alignment
fprintf('Aligning dimensions and preparing plots...\n');

% Both datasets are cropped to the same window ending at +crop_post, so lengths should match.
% If they differ (e.g. different sampling rates), keep the LAST min_cols columns
% so that the right-hand edge (+crop_post) stays aligned.
for c = 1:length(cond_list)
    cn = cond_list{c};
    cols_op = size(OpGroupData.(cn), 2);
    cols_pav = size(PavGroupData.(cn), 2);
    
    if cols_op > 0 && cols_pav > 0 && cols_op ~= cols_pav
        warning('Column mismatch for %s (Op %d vs Pav %d): trimming from the start.', cn, cols_op, cols_pav);
        min_cols = min(cols_op, cols_pav);
        OpGroupData.(cn)  = OpGroupData.(cn)(:,  end-min_cols+1:end);
        PavGroupData.(cn) = PavGroupData.(cn)(:, end-min_cols+1:end);
    end
end

% Establish base time vector (-crop_pre to +crop_post)
all_lengths = structfun(@(x) size(x, 2), OpGroupData);
max_valid_cols = max(all_lengths);
if max_valid_cols > 0
    time = linspace(-crop_pre, crop_post, max_valid_cols);
else
    error('No data found meeting the minimum trial threshold in either dataset.');
end

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; 

%% 6. Generate Comparison Plots
fprintf('Generating plots...\n');

% --- PLOT 1: REWARD OUTCOME (Operant vs Pavlovian) ---
colors.pav_rew = [0.48, 0.75, 0.00];
colors.pav_pun = [0.93, 0.07, 0.59];
colors.pav_conf = [0.08, 0.59, 0.93];
colors.op_rew = [0.12, 0.80, 0.01];
colors.op_pun = [0.87, 0.01, 0.12];
colors.op_conf = [0.01, 0.11, 0.86];
colors.black = [0, 0, 0];
title_rew = strcat('Reward Outcome: Operant vs Pavlovian (', s, ')');

sigwindows_1 = createComparisonPlot(OpGroupData.RewOut, PavGroupData.RewOut, ...
    ['Operant Reward '], ['Pavlovian Reward '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    title_rew, ...
    time, p_val, thres, y_range);

% --- PLOT 2: PUNISHMENT OUTCOME (Operant vs Pavlovian) ---
colors.op_pun = [1.00, 0.45, 0.00];
colors.pav_pun = [1.0, 0, 0];
title_pun = strcat('Shock Outcome: Operant vs Pavlovian (', s, ')');

sigwindows_2 = createComparisonPlot(OpGroupData.PunOut, PavGroupData.PunOut, ...
    ['Operant Shock '], ['Pavlovian Shock '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    title_pun, ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');