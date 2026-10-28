%% Combined Analysis: Operant vs Pavlovian Reward
%% Merges logic from Conflict_02 (Script 2) and Conflict_04 (Script 1)
%% UPDATED: Subject Means, Vectorized Extraction & Function-Based Plotting
clear all

% --- 1. Configuration & Setup ---
min_trials = 3; % Minimum trials required per rat for inclusion

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(10-45)';
% R18 and R21 should be removed based on inspection of the daily traces
rats_operant = {'R10','R13','R14','R15','R16','R19','R20','R22','R23'};
sessions_operant = {'R01','R02','R03','R04','R05'}; 

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Rew_(10-45)';
% Conf 04 Rats 
% Terminated Rats: ,'R10','R11'
% Excluded 'R01',
rats_pavlovian = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'};
sessions_pavlovian = {'R01','R02','R03'};

% --- Initialize Data Structures ---
cond_list = {'Trial_Respond', 'Trial_Omit'};

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
        
        if ismember(rat, rats_operant) && any(strcmp(session, sessions_operant))
            fprintf('  -> Op Adding %s - %s\n', rat, session);
            
            valid_rows = ~isnan(traces(:, 5));
            is_rew_cond = traces(:, 2) == 1;
            is_response  = traces(:, 4) == 1;
            is_omit      = traces(:, 4) == 0;
            
            % Append to Subject Struct (Extracting 5:323)
            OpRatData.(rat).Trial_Respond = [OpRatData.(rat).Trial_Respond; traces(valid_rows & is_rew_cond & is_response, 5:323)];
            OpRatData.(rat).Trial_Omit    = [OpRatData.(rat).Trial_Omit;    traces(valid_rows & is_rew_cond & is_omit, 5:323)];
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
    
    if contains(filename, rats_pavlovian)
        load(fullfile(path_pavlovian, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z;
        
        if ismember(rat, rats_pavlovian) && any(strcmp(session, sessions_pavlovian))
            fprintf('  -> Pav Adding %s - %s\n', rat, session);
            
            valid_rows  = ~isnan(traces(:, 5));
            is_rew_cond = traces(:, 2) == 1;
            is_response  = traces(:, 4) == 1;
            is_omit      = traces(:, 4) == 0;
                   
            % Append to Subject Struct (Extracting 5:323)
            PavRatData.(rat).Trial_Respond = [PavRatData.(rat).Trial_Respond; traces(valid_rows & is_rew_cond & is_response, 5:323)];
            PavRatData.(rat).Trial_Omit    = [PavRatData.(rat).Trial_Omit;    traces(valid_rows & is_rew_cond & is_omit, 5:323)];
        end
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
    time = linspace(-10, 10, max_valid_cols);
else
    error('No data found meeting the minimum trial threshold in either dataset.');
end

% Colors
colors.operant_green = [0.10, 0.60, 0.00]; 
colors.pavlovian_blue = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; 

%% 6. Generate Comparison Plots
fprintf('Generating comparison plots...\n');

% --- PLOT 1: Responded Trials ---
createComparisonPlot(OpGroupData.Trial_Respond, PavGroupData.Trial_Respond, ...
    ['Operant Responded'], ['Pavlovian Responded'], ...
    colors.operant_green, colors.pavlovian_blue, colors.black, ...
    'Reward Trials (Responded): Operant vs Pavlovian', ...
    time, p_val, thres, y_range);

% --- PLOT 2: Omitted Trials ---
% (Added since omitted trials were extracted in the original script but never plotted)
colors.operant_light_green = [0.00, 0.50, 0.50];
colors.pavlovian_azure = [0.00, 0.62, 1.00];

createComparisonPlot(OpGroupData.Trial_Omit, PavGroupData.Trial_Omit, ...
    ['Operant Omitted'], ['Pavlovian Omitted'], ...
    colors.operant_light_green, colors.pavlovian_azure, colors.black, ...
    'Reward Trials (Omitted): Operant vs Pavlovian', ...
    time, p_val, thres, y_range);

fprintf('✅ Plots generated.\n');