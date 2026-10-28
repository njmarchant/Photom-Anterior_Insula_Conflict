%% Combined Analysis: Operant vs Pavlovian (Trial Analysis)
%% UPDATED: Subject Means, Yoked Session Mapping (CSV), & Function Plotting
clear all

% --- 1. Configuration & Setup ---
condition = 'Pun Late';
s = char(condition);
min_trials = 2; % Minimum trials required per rat for inclusion

% --- Load Mapping for Yoked Sessions ---
% Load the session map table (Assumes file is in current directory)
sess_map = readtable('C:\Photometry\Conflict_04\Raw data\Conflict_02_sessions_Conf_4_Included_ONLY.csv', 'TextType', 'string');

% Define Target Punishment Sessions based on condition
if strcmp(condition, 'Pun Early')
    target_p4_sessions = ["P01", "P02", "P03"];
    sessions_pavlovian = {'P01', 'P02', 'P03'};
else
    target_p4_sessions = ["P04", "P05", "P06", "P07"];
    sessions_pavlovian = {'P04', 'P05', 'P06', 'P07'};
end

% Filter the map: Keep only rows corresponding to the target Pun sessions
sess_map_filtered = sess_map(ismember(sess_map.Session, target_p4_sessions), :);

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(10-45)';
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Pun_(10-45)';
rats_pavlovian = {'R02','R05','R06','R07','R08','R09','R12','R13','R14'};

% --- Initialize Data Structures ---
cond_list = {'RewDS_Resp', 'PunDS_Resp', 'RewDS_Omit', 'PunDS_Omit'};

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

for i = 1:length(files)
    filename = files(i).name;
    
    % FILTER LOGIC: Check filename against rat list BEFORE loading
    if contains(filename, rats_operant)
        load(fullfile(path_operant, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z;
        
        % --- Dynamic Session Check (Yoking) ---
        % Construct the column name for this rat in the CSV
        col_name = ['Conf_2_', rat]; 
        
        if ismember(col_name, sess_map_filtered.Properties.VariableNames)
            allowed_sessions = sess_map_filtered.(col_name);
            
            if ismember(session, allowed_sessions)
                fprintf('  -> Op Adding %s - %s\n', rat, session);
                valid_rows = ~isnan(traces(:, 5));
                
                % --- Define Masks (Trials) ---
                is_rew_cond = traces(:, 2) == 1;
                is_pun_cond = traces(:, 2) == 2;
                is_response = traces(:, 4) == 1;
                is_omit     = traces(:, 4) == 0;
                
                % Append to Subject Struct (Extracting 5:323 to match -10 to +10s window)
                OpRatData.(rat).RewDS_Resp = [OpRatData.(rat).RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
                OpRatData.(rat).PunDS_Resp = [OpRatData.(rat).PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
                OpRatData.(rat).RewDS_Omit = [OpRatData.(rat).RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:end)];
                OpRatData.(rat).PunDS_Omit = [OpRatData.(rat).PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:end)];
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

for i = 1:length(files)
    filename = files(i).name;
    
    % FILTER LOGIC: Check filename against lists BEFORE loading
    if contains(filename, rats_pavlovian) && contains(filename, sessions_pavlovian)
        load(fullfile(path_pavlovian, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z;
        
        fprintf('  -> Pav Adding %s - %s\n', rat, session);
        valid_rows  = ~isnan(traces(:, 5));
        
        % --- Define Masks (Trials) ---
        is_rew_cond = traces(:, 2) == 1;
        is_pun_cond = traces(:, 2) == 2;
        is_response = traces(:, 4) == 1;
        is_omit     = traces(:, 4) == 0;
                
        % Append to Subject Struct (Extracting 5:323)
        PavRatData.(rat).RewDS_Resp = [PavRatData.(rat).RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        PavRatData.(rat).PunDS_Resp = [PavRatData.(rat).PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
        PavRatData.(rat).RewDS_Omit = [PavRatData.(rat).RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:end)];
        PavRatData.(rat).PunDS_Omit = [PavRatData.(rat).PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:end)];
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

% Safely align columns in case trace lengths differ slightly between experiments
for c = 1:length(cond_list)
    cn = cond_list{c};
    cols_op = size(OpGroupData.(cn), 2);
    cols_pav = size(PavGroupData.(cn), 2);
    
    if cols_op > 0 && cols_pav > 0 && cols_op ~= cols_pav
        min_cols = min(cols_op, cols_pav);
        OpGroupData.(cn) = OpGroupData.(cn)(:, 1:min_cols);
        PavGroupData.(cn) = PavGroupData.(cn)(:, 1:min_cols);
    end
end

% Establish base time vector (-10 to +10)
all_lengths = structfun(@(x) size(x, 2), OpGroupData);
max_valid_cols = max(all_lengths);
if max_valid_cols > 0
    time_R = linspace(-10, 10, size(OpGroupData.RewDS_Resp, 2));
    time_O = linspace(-10, 45, size(OpGroupData.PunDS_Omit, 2));
else
    error('No data found meeting the minimum trial threshold in either dataset.');
end

% Stats Params
p_val = 0.05;
thres = 8;
y_range = [-2, 4]; 

%% 6. Generate Comparison Plots
fprintf('Generating plots...\n');

% --- PLOT 1: Responded rewDS (Operant vs Pavlovian) ---
colors.pav_rew = [0.48, 0.75, 0.00];
colors.pav_pun = [0.93, 0.07, 0.59];
colors.pav_conf = [0.08, 0.59, 0.93];
colors.op_rew = [0.12, 0.80, 0.01];
colors.op_pun = [0.87, 0.01, 0.12];
colors.op_conf = [0.01, 0.11, 0.86]

colors.black = [0, 0, 0];
sig_windows_1 = createComparisonPlot(OpGroupData.RewDS_Resp, PavGroupData.RewDS_Resp, ...
    ['Operant (rewDS) '], ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    [s,' - Responded rewDS: Operant vs Pavlovian'], ...
    time_R, p_val, thres, y_range);

% --- PLOT 2: Responded punDS (Operant vs Pavlovian) ---

sig_windows_2 = createComparisonPlot(OpGroupData.PunDS_Resp, PavGroupData.PunDS_Resp, ...
    ['Operant (punDS)'], ['Pavlovian (punDS)'], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    [s,' - Responded punDS: Operant vs Pavlovian'], ...
    time_R, p_val, thres, y_range);

% --- PLOT 3: Omitted rewDS (Operant vs Pavlovian) ---
sig_windows_3 = createComparisonPlot(OpGroupData.RewDS_Omit, PavGroupData.RewDS_Omit, ...
    ['Operant (rewDS) '], ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    [s,' - Omitted rewDS: Operant vs Pavlovian'], ...
    time_O, p_val, thres, y_range);

% --- PLOT 4: Omitted punDS (Operant vs Pavlovian) ---
sig_windows_4 = createComparisonPlot(OpGroupData.PunDS_Omit, PavGroupData.PunDS_Omit, ...
    ['Operant punDS '], ['Pavlovian punDS '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    [s,' - Omitted punDS: Operant vs Pavlovian'], ...
    time_O, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');