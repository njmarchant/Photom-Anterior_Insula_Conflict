%% Combined Analysis: Operant vs Pavlovian (Subject Means)
%% UPDATED: Groups by subject, calculates means, and aligns datasets
clear all

% --- 1. Configuration & Setup ---
condition = 'Conf Late';
s = char(condition);
min_trials = 3; % Minimum trials required per rat for inclusion

% --- Load Mapping for Yoked Sessions ---
% Load the session map table (Assumes file is in current directory)
sess_map = readtable('C:\Photometry\Conflict_04\Raw data\Conflict_02_sessions_Conf_4_Included_ONLY.csv', 'TextType', 'string');

% Define Target Conflict 4 Sessions based on condition
if strcmp(condition, 'Conf Early')
    target_c4_sessions = ["C01", "C02", "C03", "C04", "C05"];
else
    target_c4_sessions = ["C06", "C07", "C08", "C09", "C10"];
end
% Filter the map: Keep only rows corresponding to the target Conf 4 sessions
sess_map_filtered = sess_map(ismember(sess_map.Session, target_c4_sessions), :);

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Conf_(10-45)';
rats_pavlovian = {'R02','R05','R06','R07','R08','R09','R12','R13','R14'};
if strcmp(condition,'Conf Early')
    sessions_pavlovian = {'C01','C02','C03','C04','C05'};
else
    sessions_pavlovian = {'C06','C07','C08','C09','C10'}; 
end

% --- Initialize Data Structures ---
cond_list = {'RewDS_Resp', 'PunDS_Resp', 'Conf_Resp', ...
             'RewDS_Omit', 'PunDS_Omit', 'Conf_Omit', 'Conf_ALL'};

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
    load(fullfile(path_operant, files(i).name), 'sesdat');
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z_10_45;
    
    if ismember(rat, rats_operant)
        % Dynamic Session Check (Yoking)
        col_name = ['Conf_2_', rat];
        
        if ismember(col_name, sess_map_filtered.Properties.VariableNames)
            allowed_sessions = sess_map_filtered.(col_name);
            
            if ismember(session, allowed_sessions)
                fprintf('  -> Op Adding %s - %s\n', rat, session);
                
                valid_rows   = ~isnan(traces(:, 5));
                is_rew_cond  = traces(:, 2) == 1;
                is_pun_cond  = traces(:, 2) == 2;
                is_conf_cond = traces(:, 2) == 3; 
                is_response  = traces(:, 4) >= 1;
                is_omit      = traces(:, 4) == 0;
                
                % Append to Rat-specific arrays
                OpRatData.(rat).RewDS_Resp = [OpRatData.(rat).RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
                OpRatData.(rat).PunDS_Resp = [OpRatData.(rat).PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
                OpRatData.(rat).Conf_Resp  = [OpRatData.(rat).Conf_Resp;  traces(valid_rows & is_conf_cond & is_response, 5:323)];
                
                OpRatData.(rat).RewDS_Omit = [OpRatData.(rat).RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:end)];
                OpRatData.(rat).PunDS_Omit = [OpRatData.(rat).PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:end)];
                OpRatData.(rat).Conf_Omit  = [OpRatData.(rat).Conf_Omit;  traces(valid_rows & is_conf_cond & is_omit, 5:end)];
                
                OpRatData.(rat).Conf_ALL   = [OpRatData.(rat).Conf_ALL;   traces(valid_rows & is_conf_cond, 5:323)];
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
    load(fullfile(path_pavlovian, files(i).name), 'sesdat');
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z;
    
    if ismember(rat, rats_pavlovian) && any(strcmp(session, sessions_pavlovian))
        fprintf('  -> Pav Adding %s - %s\n', rat, session);
        
        valid_rows   = ~isnan(traces(:, 5));
        is_rew_cond  = traces(:, 2) == 1;
        is_pun_cond  = traces(:, 2) == 2;
        is_conf_cond = traces(:, 2) == 3;
        is_response  = traces(:, 4) >= 1;
        is_omit      = traces(:, 4) == 0;
                
        % Append
        PavRatData.(rat).RewDS_Resp = [PavRatData.(rat).RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        PavRatData.(rat).PunDS_Resp = [PavRatData.(rat).PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
        PavRatData.(rat).Conf_Resp  = [PavRatData.(rat).Conf_Resp;  traces(valid_rows & is_conf_cond & is_response, 5:323)];
        
        PavRatData.(rat).RewDS_Omit = [PavRatData.(rat).RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:end)];
        PavRatData.(rat).PunDS_Omit = [PavRatData.(rat).PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:end)];
        PavRatData.(rat).Conf_Omit  = [PavRatData.(rat).Conf_Omit;  traces(valid_rows & is_conf_cond & is_omit, 5:end)];
        
        PavRatData.(rat).Conf_ALL   = [PavRatData.(rat).Conf_ALL;   traces(valid_rows & is_conf_cond, 5:323)];
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

% Establish base time vector
% Finds the maximum valid column length left over after truncation
all_lengths = structfun(@(x) size(x, 2), OpGroupData);
max_valid_cols = max(all_lengths);
if max_valid_cols > 0
     time_R = linspace(-10, 10, size(OpGroupData.RewDS_Resp, 2));
     time_O = linspace(-10, 45, size(OpGroupData.PunDS_Omit, 2));
else
    error('No data found meeting the minimum trial threshold in either dataset.');
end


%% 6. Generate Comparison Plots
fprintf('Generating plots...\n');
% Stats Params
p_val = 0.05;
thres = 8;
y_range = [-2, 4]; 

% --- PLOT 1: Responded rewDS (Operant vs Pavlovian) ---
colors.pav_rew = [0.48, 0.75, 0.00];
colors.pav_pun = [0.93, 0.07, 0.59];
colors.pav_conf = [0.08, 0.59, 0.93];
colors.op_rew = [0.12, 0.80, 0.01];
colors.op_pun = [0.87, 0.01, 0.12];
colors.op_conf = [0.01, 0.11, 0.86];
colors.black = [0, 0, 0];

sigwindows_1 = createComparisonPlot(OpGroupData.RewDS_Resp, PavGroupData.RewDS_Resp, ...
    ['Operant (rewDS) '], ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Responded rewDS: Operant vs Pavlovian (',s,')'], ...
    time_R, p_val, thres, y_range);

% --- PLOT 2: Responded punDS (Operant vs Pavlovian) ---

sigwindows_2 = createComparisonPlot(OpGroupData.PunDS_Resp, PavGroupData.PunDS_Resp, ...
    ['Operant (punDS)'], ['Pavlovian (punDS)'], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Responded punDS: Operant vs Pavlovian (',s,')'], ...
    time_R, p_val, thres, y_range);

% --- PLOT 3: Omitted rewDS (Operant vs Pavlovian) ---
sigwindows_3 = createComparisonPlot(OpGroupData.RewDS_Omit, PavGroupData.RewDS_Omit, ...
    ['Operant (rewDS) '], ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Omitted rewDS: Operant vs Pavlovian (',s,')'], ...
    time_O, p_val, thres, y_range);

% --- PLOT 4: Omitted punDS (Operant vs Pavlovian) ---
sigwindows_4 = createComparisonPlot(OpGroupData.PunDS_Omit, PavGroupData.PunDS_Omit, ...
    ['Operant punDS '], ['Pavlovian punDS '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Omitted punDS: Operant vs Pavlovian (',s,')'], ...
    time_O, p_val, thres, y_range);

% --- PLOT 5: Responded Conf (Operant vs Pavlovian) ---
sigwindows_5 = createComparisonPlot(OpGroupData.Conf_Resp, PavGroupData.Conf_Resp, ...
    ['Operant (conf) '], ['Pavlovian (conf) '], ...
    colors.op_conf, colors.pav_conf, colors.black, ...
    ['Responded Conflict: Operant vs Pavlovian (',s,')'], ...
    time_R, p_val, thres, y_range);

% --- PLOT 6: Omitted Conf (Operant vs Pavlovian) ---
sigwindows_6 = createComparisonPlot(OpGroupData.Conf_Omit, PavGroupData.Conf_Omit, ...
    ['Operant (conf) '], ['Pavlovian (conf) '], ...
    colors.op_conf, colors.pav_conf, colors.black, ...
    ['Omitted Conflict: Operant vs Pavlovian (',s,')'], ...
    time_O, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');