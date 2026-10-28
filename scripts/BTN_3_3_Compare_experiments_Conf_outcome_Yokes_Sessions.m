%% Combined Analysis: Operant vs Pavlovian (Outcome Analysis)
%% UPDATED: Subject Means, Yoked Session Mapping, & Function Plotting
clear all

% --- 1. Configuration & Setup ---
condition = 'Conf Late';
s = char(condition);
min_trials = 5; % Minimum trials required per rat for inclusion
crop_pre  = 15;   % s before the press to keep
crop_post = 15;   % s after the press to keep

% --- Load Mapping for Yoked Sessions ---
% Load the session map table (Assumes file is in current directory)
sess_map = readtable('C:\Photometry\Conflict_04\Raw data\Conflict_02_sessions_Conf_4_Included_ONLY.csv', 'TextType', 'string');

% Define Target Conflict 4 Sessions based on condition
if strcmp(condition, 'Conf Early')
    target_c4_sessions = ["C01", "C02", "C03", "C04", "C05"];
else
    target_c4_sessions = ["C01", "C02", "C03", "C04", "C05","C06", "C07", "C08", "C09", "C10"];
end
% Filter the map: Keep only rows corresponding to the target Conf 4 sessions
sess_map_filtered = sess_map(ismember(sess_map.Session, target_c4_sessions), :);

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data\with_resp_traces';
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Conf_(10-45)\with_resp_traces';
rats_pavlovian = {'R02','R05','R06','R07','R08','R09','R12','R13','R14'};
if strcmp(condition,'Conf Early')
    sessions_pavlovian = {'C01','C02','C03','C04','C05'};
else
    sessions_pavlovian = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10'}; 
end

% --- Initialize Data Structures ---
cond_list = {'rewDS_RewOut', 'punDS_PunOut', 'Conf_RewOut', 'Conf_PunOut'};

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

    if contains(filename, rats_operant)
        load(fullfile(path_operant, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z_resp;

        % --- Crop to [-crop_pre, +crop_post] s around the press ---
        t_resp = sesdat.traces_resp_time;
        i0 = find(abs(t_resp) < 1e-9, 1);                        % sample at the press
        c0 = i0 - ceil(crop_pre  * sesdat.conversion);
        c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
        trace_cols = 4 + (c0 : c1);                              % +4 skips the header columns

        % --- Dynamic Session Check (Yoking) ---
        col_name = ['Conf_2_', rat];
        if ismember(col_name, sess_map_filtered.Properties.VariableNames)
            allowed_sessions = sess_map_filtered.(col_name);
            if ismember(session, allowed_sessions)
                fprintf('  -> Op Adding %s - %s\n', rat, session);
                valid_rows = ~any(isnan(traces(:, trace_cols)), 2);

                is_rew_out = traces(:, 2) == 5;
                is_pun_out = traces(:, 2) == 6;
                is_rew_trial = traces(:, 4) == 1;
                is_pun_trial = traces(:, 4) == 2;
                is_conf_trial = traces(:, 4) == 3;

                OpRatData.(rat).rewDS_RewOut = [OpRatData.(rat).rewDS_RewOut; traces(valid_rows & is_rew_out & is_rew_trial, trace_cols)];
                OpRatData.(rat).punDS_PunOut = [OpRatData.(rat).punDS_PunOut; traces(valid_rows & is_pun_out & is_pun_trial, trace_cols)];
                OpRatData.(rat).Conf_RewOut  = [OpRatData.(rat).Conf_RewOut;  traces(valid_rows & is_rew_out & is_conf_trial, trace_cols)];
                OpRatData.(rat).Conf_PunOut  = [OpRatData.(rat).Conf_PunOut;  traces(valid_rows & is_pun_out & is_conf_trial, trace_cols)];
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

        fprintf('  -> Pav Adding %s - %s\n', rat, session);
        valid_rows = ~any(isnan(traces(:, trace_cols)), 2);

        is_rew_out = traces(:, 2) == 5;
        is_pun_out = traces(:, 2) == 6;
        is_rew_trial = traces(:, 4) == 1;
        is_pun_trial = traces(:, 4) == 2;
        is_conf_trial = traces(:, 4) == 3;

        PavRatData.(rat).rewDS_RewOut = [PavRatData.(rat).rewDS_RewOut; traces(valid_rows & is_rew_out & is_rew_trial, trace_cols)];
        PavRatData.(rat).punDS_PunOut = [PavRatData.(rat).punDS_PunOut; traces(valid_rows & is_pun_out & is_pun_trial, trace_cols)];
        PavRatData.(rat).Conf_RewOut  = [PavRatData.(rat).Conf_RewOut;  traces(valid_rows & is_rew_out & is_conf_trial, trace_cols)];
        PavRatData.(rat).Conf_PunOut  = [PavRatData.(rat).Conf_PunOut;  traces(valid_rows & is_pun_out & is_conf_trial, trace_cols)];
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
    OpGroupData.(cn)  = OpGroupData.(cn)(:,  end-min_cols+1:end);
    PavGroupData.(cn) = PavGroupData.(cn)(:, end-min_cols+1:end);
    end
end

% Establish base time vector (-15 to +15)
all_lengths = structfun(@(x) size(x, 2), OpGroupData);
max_valid_cols = max(all_lengths);
if max_valid_cols > 0
    time = linspace(-crop_pre, crop_post, max_valid_cols);
else
    error('No data found meeting the minimum trial threshold in either dataset.');
end

%% 6. Generate Comparison Plots
fprintf('Generating plots...\n');

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 8]; 

colors.pav_rew = [0.48, 0.75, 0.00];
colors.pav_pun = [0.93, 0.07, 0.59];
colors.pav_conf = [0.08, 0.59, 0.93];
colors.op_rew = [0.12, 0.80, 0.01];
colors.op_pun = [0.87, 0.01, 0.12];
colors.op_conf = [0.01, 0.11, 0.86];
colors.black = [0, 0, 0];

% --- PLOT 1: REWARD OUTCOME (Operant vs Pavlovian) ---
sigwindows_1 = createComparisonPlot(OpGroupData.rewDS_RewOut, PavGroupData.rewDS_RewOut, ...
    ['Operant rewDS Reward '], ['Pavlovian rewDS Reward '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Reward Outcome in rewDS : Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 2: PUNISHMENT OUTCOME (Operant vs Pavlovian) ---
sigwindows_2 = createComparisonPlot(OpGroupData.punDS_PunOut, PavGroupData.punDS_PunOut, ...
    ['Operant punDS Shock '], ['Pavlovian punDS Shock '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Shock Outcome in punDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 3: CONFLICT Reward OUTCOME (Operant vs Pavlovian) ---
sigwindows_3 = createComparisonPlot(OpGroupData.Conf_RewOut, PavGroupData.Conf_RewOut, ...
    ['Operant Conflict Reward '], ['Pavlovian Conflict Reward '], ...
    colors.op_conf, colors.pav_conf, colors.black, ...
    ['Reward Outcome in Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 4: CONFLICT Shock OUTCOME (Operant vs Pavlovian) ---
sigwindows_4 = createComparisonPlot(OpGroupData.Conf_PunOut, PavGroupData.Conf_PunOut, ...
    ['Operant Conflict Shock '], ['Pavlovian conflict Shock '], ...
    colors.op_conf, colors.pav_conf, colors.black, ...
    ['Shock Outcome in Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');