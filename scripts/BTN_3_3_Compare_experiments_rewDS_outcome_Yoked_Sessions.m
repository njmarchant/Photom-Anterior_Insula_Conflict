%% Combined Analysis: Operant vs Pavlovian Reward
%% Merges logic from Conflict_02 (Script 2) and Conflict_04 (Script 1)
%% UPDATED: Subject Means, Vectorized Extraction & Function-Based Plotting
clear all

% --- 1. Configuration & Setup ---
min_trials = 3; % Minimum trials required per rat for inclusion

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(25-15)';
rats_operant = {'R10','R13','R14','R15','R16','R19','R20','R22','R23'};
% sessions_operant = {'R01','R02','R03','P04','R05'}; % From 'rew_all' in Script 2
sessions_operant = {'R03','P04','R05'}; % From 'rew_all' in Script 2

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Rew_(25-15)';
rats_pavlovian = {'R02','R05','R06','R07','R08','R09','R12','R13','R14'};
sessions_pavlovian = {'R01','R02','R03','R04'}; 

% --- Initialize Data Structures ---
OpRatData = struct();
PavRatData = struct();

for r = 1:length(rats_operant)
    OpRatData.(rats_operant{r}).Traces = [];
end

for r = 1:length(rats_pavlovian)
    PavRatData.(rats_pavlovian{r}).Traces = [];
end

%% 2. Extraction: Operant Data (Folder 1)
fprintf('------------------------------------------------\n');
fprintf('Processing Operant Data (Folder 1)...\n');
filesAndFolders = dir(fullfile(path_operant));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files)
    filename = files(i).name;
    
    % Check filename against rat list BEFORE loading to save time
    if contains(filename, rats_operant)
        load(fullfile(path_operant, filename), 'sesdat');
        rat = sesdat.rat;
        session = sesdat.ses;
        traces = sesdat.traces_z;
        
        if ismember(rat, rats_operant) && any(strcmp(session, sessions_operant))
            fprintf('  -> Op Adding %s - %s\n', rat, session);
            
            valid_rows = ~isnan(traces(:, 5));
            is_rew_cond = traces(:, 2) == 5;
            
            % Append to Subject Struct
            OpRatData.(rat).Traces = [OpRatData.(rat).Traces; traces(valid_rows & is_rew_cond, 5:end)];
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
            is_rew_cond = traces(:, 2) == 5;
                   
            % Append to Subject Struct
            PavRatData.(rat).Traces = [PavRatData.(rat).Traces; traces(valid_rows & is_rew_cond, 5:end)];
        end
    end
end
fprintf('✅ Data extraction complete.\n');

%% 4. Calculate Subject Means
fprintf('Calculating Subject Means (Min trials = %d)...\n', min_trials);

Traces_Operant = [];
Traces_Pavlovian = [];

% Operant Means
for i = 1:length(rats_operant)
    ratID = rats_operant{i};
    traces_sub = OpRatData.(ratID).Traces;
    if size(traces_sub, 1) >= min_trials
        Traces_Operant = [Traces_Operant; mean(traces_sub, 1, 'omitnan')];
    end
end

% Pavlovian Means
for i = 1:length(rats_pavlovian)
    ratID = rats_pavlovian{i};
    traces_sub = PavRatData.(ratID).Traces;
    if size(traces_sub, 1) >= min_trials
        Traces_Pavlovian = [Traces_Pavlovian; mean(traces_sub, 1, 'omitnan')];
    end
end

%% 5. Plotting Configuration & Dimension Alignment
fprintf('Aligning dimensions and preparing plots...\n');

% Verify Dimensions match. If they don't, truncate to the minimum.
cols_op = size(Traces_Operant, 2);
cols_pav = size(Traces_Pavlovian, 2);
if cols_op > 0 && cols_pav > 0 && cols_op ~= cols_pav
    warning('Data dimensions mismatch! Operant: %d cols, Pavlovian: %d cols. Truncating to minimum.', cols_op, cols_pav);
    min_cols = min(cols_op, cols_pav);
    Traces_Operant = Traces_Operant(:, 1:min_cols);
    Traces_Pavlovian = Traces_Pavlovian(:, 1:min_cols);
end

% Establish base time vector (-25 to +15)
if cols_op > 0 || cols_pav > 0
    max_valid_cols = max(size(Traces_Operant, 2), size(Traces_Pavlovian, 2));
    time = linspace(-25, 15, max_valid_cols);
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

%% 6. Generate Comparison Plot
fprintf('Generating comparison plot...\n');

createComparisonPlot(Traces_Operant, Traces_Pavlovian, ...
    ['Operant Reward'], ['Pavlovian Reward'], ...
    colors.operant_green, colors.pavlovian_blue, colors.black, ...
    'Reward Outcomes: Operant vs Pavlovian', ...
    time, p_val, thres, y_range);

fprintf('✅ Plot generated.\n');