%% Combined Analysis: Operant vs Pavlovian Reward
%% Merges logic from Conflict_02 (Script 2) and Conflict_04 (Script 1)
%% UPDATED: Vectorized Extraction & Function-Based Plotting

clear all

% --- 1. Configuration & Setup ---

% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(10-45)';
% R18 and R21 should be removed based on inspection of the daily traces
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};
sessions_operant = {'R01','R02','R03','R04','R05'}; 
% sessions_operant = {'R03','R04','R05'}; 

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Rew_(10-40)';
% Conf 04 Rats (Excluded R02, R09 'R01',)
% Terminated Rats: ,'R10','R11'

rats_pavlovian = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'};
sessions_pavlovian = {'R01','R02','R03'};


% Containers
Operant_Trial_Respond = [];
Pavlovian_Trial_Respond = [];
Operant_Trial_Omit = [];
Pavlovian_Trial_Omit = [];

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
    traces = sesdat.traces_z;
    
    if ismember(rat, rats_operant) && any(strcmp(session, sessions_operant))
        fprintf('  -> Adding %s - %s\n', rat, session);
        
        valid_rows = ~isnan(traces(:, 5));
        is_rew_cond = traces(:, 2) == 1;
        is_response  = traces(:, 4) == 1;
        is_omit      = traces(:, 4) == 0;
        
        % Append
        Operant_Trial_Respond = [Operant_Trial_Respond; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        Operant_Trial_Omit = [Operant_Trial_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:323)];
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
        fprintf('  -> Adding %s - %s\n', rat, session);
        valid_rows  = ~isnan(traces(:, 5));
        is_rew_cond = traces(:, 2) == 1;
        is_response  = traces(:, 4) == 1;
        is_omit      = traces(:, 4) == 0;
               
        % Append
        Pavlovian_Trial_Respond = [Pavlovian_Trial_Respond; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        Pavlovian_Trial_Omit = [Pavlovian_Trial_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:323)];
    end
end
fprintf('✅ Data extraction complete.\n');

%% 4. Plotting Configuration

% Verify Dimensions match
% If they don't match, we truncate to the smaller size or throw error.
cols_op = size(Operant_Trial_Respond, 2);
cols_pav = size(Pavlovian_Trial_Respond, 2);

if cols_op ~= cols_pav
    warning('Data dimensions mismatch! Operant: %d cols, Pavlovian: %d cols. Truncating to minimum.', cols_op, cols_pav);
    min_cols = min(cols_op, cols_pav);
    Operant_Trial_Respond = Operant_Trial_Respond(:, 1:min_cols);
    Pavlovian_Trial_Respond = Pavlovian_Trial_Respond(:, 1:min_cols);
end

% Colors
colors.operant_green = [0.10, 0.60, 0.00]; 
colors.pavlovian_blue = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

% Time Vector
time = linspace(-10, 10, size(Operant_Trial_Respond, 2)); % Using range from Script 2 (Conflict 02)

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; 

%% 5. Generate Comparison Plot

fprintf('Generating comparison plot...\n');

createComparisonPlot(Operant_Trial_Respond, Pavlovian_Trial_Respond, ...
    ['Operant '], ...
    ['Pavlovian '], ...
    colors.operant_green, colors.pavlovian_blue, colors.black, ...
    'Reward Outcomes: Operant vs Pavlovian', ...
    time, p_val, thres, y_range);

fprintf('✅ Plot generated.\n');