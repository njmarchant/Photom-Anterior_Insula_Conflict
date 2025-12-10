%% Combined Analysis: Operant vs Pavlovian (Outcome Analysis)
%% UPDATED: Extracts Outcomes (5=Rew, 6=Shock) and plots -25s to +15s

clear all

% --- 1. Configuration & Setup ---
condition = 'Conf Late';
s=char(condition);
% Dataset 1: Operant (Conflict 02)
path_operant = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-45)';
% R18 and R21 should be removed based on inspection of the daily traces
rats_operant = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};
if strcmp(condition,'Conf Early')
    sessions_operant = {'C01','C02','C03','C04','C05'}; 
else
    sessions_operant = {'C12','C13','C14','C15'};  
end

% Dataset 2: Pavlovian (Conflict 04)
path_pavlovian = 'C:\Photometry\Conflict_04\Conf_(10-40)';
% Conf 04 Rats (Excluded R02, R09 'R01',)
% Terminated Rats: ,'R10','R11'

rats_pavlovian = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'};
if strcmp(condition,'Conf Early')
    sessions_pavlovian = {'C01','C02','C03','C04','C05'};
else
    sessions_pavlovian = {'C06','C07','C08','C09','C10'}; 
end

% Containers
Trial_Operant_RewDS_Resp = [];
Trial_Operant_PunDS_Resp = [];
Trial_Operant_Conf_Resp = [];
Trial_Pavlovian_RewDS_Resp = [];
Trial_Pavlovian_PunDS_Resp = [];
Trial_Pavlovian_Conf_Resp = [];

Trial_Operant_RewDS_Omit = [];
Trial_Operant_PunDS_Omit = [];
Trial_Operant_Conf_Omit = [];
Trial_Pavlovian_RewDS_Omit = [];
Trial_Pavlovian_PunDS_Omit = [];
Trial_Pavlovian_Conf_Omit = [];

Trial_Operant_Conf_ALL = [];
Trial_Pavlovian_Conf_ALL = [];

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
        valid_rows = ~isnan(traces(:, 5));
        is_rew_cond = traces(:, 2) == 1;
        is_pun_cond = traces(:, 2) == 2;
        is_conf_cond = traces(:, 2) == 3; 
        is_response  = traces(:, 4) >= 1;
        is_omit      = traces(:, 4) == 0;

        % Append
        Trial_Operant_RewDS_Resp = [Trial_Operant_RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        Trial_Operant_PunDS_Resp = [Trial_Operant_PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
        Trial_Operant_Conf_Resp = [Trial_Operant_Conf_Resp; traces(valid_rows & is_conf_cond & is_response, 5:323)];
        Trial_Operant_RewDS_Omit = [Trial_Operant_RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:323)];
        Trial_Operant_PunDS_Omit = [Trial_Operant_PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:323)];
        Trial_Operant_Conf_Omit = [Trial_Operant_Conf_Omit; traces(valid_rows & is_conf_cond & is_omit, 5:323)];
        Trial_Operant_Conf_ALL = [Trial_Operant_Conf_ALL; traces(valid_rows & is_conf_cond , 5:323)];
    end
end
fprintf('  -> Operant: %d Responded rewDS, %d Responded punDS, %d Responded Conf, %d Omitted rewDS, %d Omitted punDS, %d Omitted Conf, found.\n', size(Trial_Operant_RewDS_Resp,1), size(Trial_Operant_PunDS_Resp,1), size(Trial_Operant_Conf_Resp,1), size(Trial_Operant_RewDS_Omit,1), size(Trial_Operant_PunDS_Omit,1), size(Trial_Operant_Conf_Omit,1));

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
        valid_rows = ~isnan(traces(:, 5));
        is_rew_cond = traces(:, 2) == 1;
        is_pun_cond = traces(:, 2) == 2;
        is_conf_cond = traces(:, 2) == 3;
        is_response  = traces(:, 4) >= 1;
        is_omit      = traces(:, 4) == 0;
                
        % Append
        Trial_Pavlovian_RewDS_Resp = [Trial_Pavlovian_RewDS_Resp; traces(valid_rows & is_rew_cond & is_response, 5:323)];
        Trial_Pavlovian_PunDS_Resp = [Trial_Pavlovian_PunDS_Resp; traces(valid_rows & is_pun_cond & is_response, 5:323)];
        Trial_Pavlovian_Conf_Resp = [Trial_Pavlovian_Conf_Resp; traces(valid_rows & is_conf_cond & is_response, 5:323)];
        Trial_Pavlovian_RewDS_Omit = [Trial_Pavlovian_RewDS_Omit; traces(valid_rows & is_rew_cond & is_omit, 5:323)];
        Trial_Pavlovian_PunDS_Omit = [Trial_Pavlovian_PunDS_Omit; traces(valid_rows & is_pun_cond & is_omit, 5:323)];
        Trial_Pavlovian_Conf_Omit = [Trial_Pavlovian_Conf_Omit; traces(valid_rows & is_conf_cond & is_omit, 5:323)];
        Trial_Pavlovian_Conf_ALL = [Trial_Pavlovian_Conf_ALL; traces(valid_rows & is_conf_cond, 5:323)];
    end
end
fprintf('  -> Pavlovian: %d Responded rewDS, %d Responded punDS, %d Responded Conf, %d Omitted rewDS, %d Omitted punDS, %d Omitted conf found.\n', size(Trial_Pavlovian_RewDS_Resp,1), size(Trial_Pavlovian_PunDS_Resp,1), size(Trial_Pavlovian_Conf_Resp,1), size(Trial_Pavlovian_RewDS_Omit,1), size(Trial_Pavlovian_PunDS_Omit,1), size(Trial_Pavlovian_Conf_Omit,1));
fprintf('✅ Data extraction complete.\n');

%% 4. Plotting Configuration

% Check/Truncate Dimensions
cols_op = size(Trial_Operant_RewDS_Resp, 2);
cols_pav = size(Trial_Pavlovian_RewDS_Resp, 2);

% Handle case where one might be empty or sizes differ slightly
if cols_op > 0 && cols_pav > 0 && cols_op ~= cols_pav
    min_cols = min(cols_op, cols_pav);
    Trial_Operant_RewDS_Resp = Trial_Operant_RewDS_Resp(:, 1:min_cols);
    Trial_Operant_PunDS_Resp = Trial_Operant_PunDS_Resp(:, 1:min_cols);
    Trial_Operant_Conf_Resp = Trial_Operant_Conf_Resp(:, 1:min_cols);
    Trial_Pavlovian_RewDS_Resp = Trial_Pavlovian_RewDS_Resp(:, 1:min_cols);
    Trial_Pavlovian_PunDS_Resp = Trial_Pavlovian_PunDS_Resp(:, 1:min_cols);
    Trial_Pavlovian_Conf_Resp = Trial_Pavlovian_Conf_Resp(:, 1:min_cols);
    Trial_Operant_RewDS_Omit = Trial_Operant_RewDS_Omit(:, 1:min_cols);
    Trial_Operant_PunDS_Omit = Trial_Operant_PunDS_Omit(:, 1:min_cols);
    Trial_Operant_Conf_Omit = Trial_Operant_Conf_Omit(:, 1:min_cols);
    Trial_Pavlovian_RewDS_Omit = Trial_Pavlovian_RewDS_Omit(:, 1:min_cols);
    Trial_Pavlovian_PunDS_Omit = Trial_Pavlovian_PunDS_Omit(:, 1:min_cols);
    Trial_Pavlovian_Conf_Omit = Trial_Pavlovian_Conf_Omit(:, 1:min_cols);
    fprintf('  ! Dimensions adjusted to %d columns.\n', min_cols);
elseif cols_op > 0
    min_cols = cols_op;
elseif cols_pav > 0
    min_cols = cols_pav;
else
    error('No data found in either dataset.');
end

% Time Vector 
time = linspace(-10, 10, min_cols);

% Stats Params
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; 

%% 5. Generate Comparison Plots

fprintf('Generating plots...\n');

% --- PLOT 1: Responded rewDS (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)
colors.op_rew = [0.10, 0.60, 0.00]; 
colors.pav_rew = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

createComparisonPlot(Trial_Operant_RewDS_Resp, Trial_Pavlovian_RewDS_Resp, ...
    ['Operant (rewDS) '], ...
    ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Responded rewDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 2: Responded punDS (Operant vs Pavlovian) ---
% Colors: Orange (Operant) vs Red (Pavlovian)
colors.op_pun = [1.00, 0.45, 0.00];
colors.pav_pun = [1.0, 0, 0];

createComparisonPlot(Trial_Operant_PunDS_Resp, Trial_Pavlovian_PunDS_Resp, ...
    ['Operant (punDS)'], ...
    ['Pavlovian (punDS)'], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Responded punDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 3: Omitted rewDS (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)
colors.op_rew = [0.10, 0.60, 0.00]; 
colors.pav_rew = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

createComparisonPlot(Trial_Operant_RewDS_Omit, Trial_Pavlovian_RewDS_Omit, ...
    ['Operant (rewDS) '], ...
    ['Pavlovian (rewDS) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Omitted rewDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 4: Omitted punDS (Operant vs Pavlovian) ---
% Colors: Orange (Operant) vs Red (Pavlovian)
colors.op_pun = [1.00, 0.45, 0.00];
colors.pav_pun = [1.0, 0, 0];

createComparisonPlot(Trial_Operant_PunDS_Omit, Trial_Pavlovian_PunDS_Omit, ...
    ['Operant punDS '], ...
    ['Pavlovian punDS '], ...
    colors.op_pun, colors.pav_pun, colors.black, ...
    ['Omitted punDS: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 5: Responded Conf (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)
colors.op_rew = [0.10, 0.60, 0.00]; 
colors.pav_rew = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

createComparisonPlot(Trial_Operant_Conf_Resp, Trial_Pavlovian_Conf_Resp, ...
    ['Operant (conf) '], ...
    ['Pavlovian (conf) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Responded Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 6: Omitted Conf (Operant vs Pavlovian) ---
% Colors: Green (Operant) vs Blue (Pavlovian)
colors.op_rew = [0.10, 0.60, 0.00]; 
colors.pav_rew = [0.00, 0.26, 1.00];
colors.black = [0, 0, 0];

createComparisonPlot(Trial_Operant_Conf_Omit, Trial_Pavlovian_Conf_Omit, ...
    ['Operant (conf) '], ...
    ['Pavlovian (conf) '], ...
    colors.op_rew, colors.pav_rew, colors.black, ...
    ['Omitted Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

% --- PLOT 7: Conf ALL (Operant vs Pavlovian) ---
% Colors: Purple (Operant) vs Azure (Pavlovian)
colors.op_rew = [0.36,0.32,0.64]; 
colors.pav_rew = [0.00,0.62,1.00];
colors.yellow = [1.00,0.88,0.00];

createComparisonPlot(Trial_Operant_Conf_ALL, Trial_Pavlovian_Conf_ALL, ...
    ['Operant (conf ALL) '], ...
    ['Pavlovian (conf ALL) '], ...
    colors.op_rew, colors.pav_rew, colors.yellow, ...
    ['ALL Conflict: Operant vs Pavlovian (',s,')'], ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');