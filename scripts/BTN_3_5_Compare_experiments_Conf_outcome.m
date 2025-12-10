%% Combined Analysis: Operant vs Pavlovian (Outcome Analysis)
%% UPDATED: Extracts Outcomes (5=Rew, 6=Shock) and plots -25s to +15s

clear all

% --- 1. Configuration & Setup ---
condition = 'Conf Early';
s=char(condition);
% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(25-15)';
% R18 and R21 should be removed based on inspection of the daily traces
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};
if strcmp(condition,'Conf Early')
    sessions_operant = {'C01','C02','C03','C04','C05'}; 
else
    sessions_operant = {'C12','C13','C14','C15'};  
end

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Raw data\Conf_(25-15)';

% Conf 04 Rats (Excluded R02, R09 'R01',)
% Terminated Rats: ,'R10','R11'

rats_pavlovian = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'};
if strcmp(condition,'Conf Early')
    sessions_pavlovian = {'C01','C02','C03','C04','C05'};
else
    sessions_pavlovian = {'C06','C07','C08','C09','C10'}; 
end
% Containers
Traces_Operant_rewDS_RewOutcome = [];
Traces_Operant_punDS_PunOutcome = [];
Traces_Pavlovian_rewDS_RewOutcome = [];
Traces_Pavlovian_punDS_PunOutcome = [];

Traces_Operant_Conf_Rew_Outcome = [];
Traces_Operant_Conf_Pun_Outcome = [];
Traces_Pavlovian_Conf_Rew_Outcome = [];
Traces_Pavlovian_Conf_Pun_Outcome = [];


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
        
        % --- Define Masks (Outcomes) ---
        % 5 = Reward Outcome
        % 6 = Shock Outcome
        is_rew_out = traces(:, 2) == 5; 
        is_pun_out = traces(:, 2) == 6;
        is_rew_trial = traces(:, 4) == 1;
        is_pun_trial = traces(:, 4) == 2;
        is_conf_trial = traces(:, 4) == 3;

        
        % Append
        Traces_Operant_rewDS_RewOutcome = [Traces_Operant_rewDS_RewOutcome; traces(valid_rows & is_rew_out & is_rew_trial, 5:end)];
        Traces_Operant_punDS_PunOutcome = [Traces_Operant_punDS_PunOutcome; traces(valid_rows & is_pun_out & is_pun_trial, 5:end)];

        Traces_Operant_Conf_Rew_Outcome = [Traces_Operant_Conf_Rew_Outcome; traces(valid_rows & is_rew_out & is_conf_trial, 5:end)];
        Traces_Operant_Conf_Pun_Outcome = [Traces_Operant_Conf_Pun_Outcome; traces(valid_rows & is_pun_out & is_conf_trial, 5:end)];
    end
end
fprintf('  -> Operant: %d Rew Outcomes, %d Pun Outcomes found.\n', size(Traces_Operant_rewDS_RewOutcome,1), size(Traces_Operant_punDS_PunOutcome,1));

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
        
        % --- Define Masks (Outcomes) ---
        is_rew_out = traces(:, 2) == 5;
        is_pun_out = traces(:, 2) == 6;
        is_rew_trial = traces(:, 4) == 1;
        is_pun_trial = traces(:, 4) == 2;
        is_conf_trial = traces(:, 4) == 3;
        
        
        % Append
        Traces_Pavlovian_rewDS_RewOutcome = [Traces_Pavlovian_rewDS_RewOutcome; traces(valid_rows & is_rew_out & is_rew_trial, 5:end)];
        Traces_Pavlovian_punDS_PunOutcome = [Traces_Pavlovian_punDS_PunOutcome; traces(valid_rows & is_pun_out & is_pun_trial, 5:end)];

        Traces_Pavlovian_Conf_Rew_Outcome = [Traces_Pavlovian_Conf_Rew_Outcome; traces(valid_rows & is_rew_out & is_conf_trial, 5:end)];
        Traces_Pavlovian_Conf_Pun_Outcome = [Traces_Pavlovian_Conf_Pun_Outcome; traces(valid_rows & is_pun_out & is_conf_trial, 5:end)];
    end
end
fprintf('  -> Pavlovian: %d Rew Outcomes, %d Pun Outcomes found.\n', size(Traces_Pavlovian_rewDS_RewOutcome,1), size(Traces_Pavlovian_punDS_PunOutcome,1));
fprintf('✅ Data extraction complete.\n');

%% 4. Plotting Configuration

% Check/Truncate Dimensions
cols_op = size(Traces_Operant_rewDS_RewOutcome, 2);
cols_pav = size(Traces_Pavlovian_rewDS_RewOutcome, 2);

% Handle case where one might be empty or sizes differ slightly
if cols_op > 0 && cols_pav > 0 && cols_op ~= cols_pav
    min_cols = min(cols_op, cols_pav);
    Traces_Operant_rewDS_RewOutcome = Traces_Operant_rewDS_RewOutcome(:, 1:min_cols);
    Traces_Operant_punDS_PunOutcome = Traces_Operant_punDS_PunOutcome(:, 1:min_cols);
    Traces_Pavlovian_rewDS_RewOutcome = Traces_Pavlovian_rewDS_RewOutcome(:, 1:min_cols);
    Traces_Pavlovian_punDS_PunOutcome = Traces_Pavlovian_punDS_PunOutcome(:, 1:min_cols);

    Traces_Operant_Conf_Rew_Outcome = Traces_Operant_Conf_Rew_Outcome(:, 1:min_cols);
    Traces_Operant_Conf_Pun_Outcome = Traces_Operant_Conf_Pun_Outcome(:, 1:min_cols); 
    Traces_Pavlovian_Conf_Rew_Outcome = Traces_Pavlovian_Conf_Rew_Outcome(:, 1:min_cols);
    Traces_Pavlovian_Conf_Pun_Outcome = Traces_Pavlovian_Conf_Pun_Outcome(:, 1:min_cols);

    
    fprintf('  ! Dimensions adjusted to %d columns.\n', min_cols);
elseif cols_op > 0
    min_cols = cols_op;
elseif cols_pav > 0
    min_cols = cols_pav;
else
    error('No data found in either dataset.');
end

% Time Vector (-25 to +15)
time = linspace(-25, 15, min_cols);

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 8]; 

% ___________ Colours (Kept from Old Script) ______________
colors.purp = [0.36,0.32,0.64];
colors.blue = [0.00,0.26,1.00];
colors.azure = [0.00,0.62,1.00];
colors.red = [1.0,0,0];
colors.pink = [1.00,0.50,0.50];
colors.orange = [1.00,0.45,0.00];
colors.light_orange = [1.00,0.87,0.60];
colors.green = [0.10,0.60,0.00];
colors.light_green = [0.00,0.50,0.50];
colors.yellow = [1.00,0.88,0.00];
colors.black = [0,0,0]; % Used for permutation markers

%% 5. Generate Comparison Plots

fprintf('Generating plots...\n');

% --- PLOT 1: REWARD OUTCOME (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)
colors.op_rew = [0.10, 0.60, 0.00]; 
colors.pav_rew = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

createComparisonPlot(Traces_Operant_rewDS_RewOutcome, Traces_Pavlovian_rewDS_RewOutcome, ...
    ['Operant rewDS Reward '], ...
    ['Pavlovian rewDS Reward '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Reward Outcome in rewDS : Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 2: PUNISHMENT OUTCOME (Operant vs Pavlovian) ---
% Colors: Orange (Operant) vs Red (Pavlovian)
colors.op_pun = [1.00, 0.45, 0.00];
colors.pav_pun = [1.0, 0, 0];

createComparisonPlot(Traces_Operant_punDS_PunOutcome, Traces_Pavlovian_punDS_PunOutcome, ...
    ['Operant punDS Shock '], ...
    ['Pavlovian punDS Shock '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Shock Outcome in punDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 3: CONFLICT Reward OUTCOME (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)


createComparisonPlot(Traces_Operant_Conf_Rew_Outcome, Traces_Pavlovian_Conf_Rew_Outcome, ...
    ['Operant Conflict Reward '], ...
    ['Pavlovian Conflict Reward '], ...
    colors.green, colors.light_green, colors.yellow, ...
    ['Reward Outcome in Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 4: CONFLICT Shock OUTCOME (Operant vs Pavlovian) ---
% Colors: Orange (Operant) vs Red (Pavlovian)
colors.op_pun = [1.00, 0.45, 0.00];
colors.pav_pun = [1.0, 0, 0];

createComparisonPlot(Traces_Operant_Conf_Pun_Outcome, Traces_Pavlovian_Conf_Pun_Outcome, ...
    ['Operant Conflict Shock '], ...
    ['Pavlovian conflict Shock '], ...
    colors.red, colors.pink, colors.yellow, ...
    ['Shock Outcome in Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');