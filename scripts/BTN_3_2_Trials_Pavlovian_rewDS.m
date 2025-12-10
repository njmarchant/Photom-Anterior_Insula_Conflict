%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% UPDATED: Vectorized Extraction & Function-Based Plotting

clear all
tankfolder = 'C:\Photometry\Conflict_04\Raw data\Rew_(10-45)';
condition = 'Reward';
filePath = fullfile(tankfolder);
included_sessions = {'R01', 'R02','R03'};
% --- Initialize Containers ---
Rew_Trial = [];
Rew_Trial_Omit = [];
Rew_Trial_ALL = [];

% --- Session and Rat Definitions (Kept from Old Script) ---
s = char(condition);

% Conf 04 Rats (Excluded R02, R09)
Rat = {'R01','R05','R06','R07','R08','R10','R11','R12','R13','R14'};

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

%% 1. Vectorized Data Extraction
fprintf('Starting data extraction...\n');

for i = 1:length(files) 
    % Load data
    load(fullfile(filePath,  [files(i).name]), 'sesdat');
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z; % Extract for cleaner code
    
    % Check if this specific Rat and Session are in our include list
    if ismember(rat, Rat) && any(strcmp(session, included_sessions))
        fprintf('Processing %s - %s\n', rat, session);
        
        % --- New Vectorized Method ---
        % Create logical masks for the conditions
        % Column 2: 1 = Reward Block, 2 = Punishment Block
        % Column 4: 1 = Responded, 0 = Omitted
        % Column 5: Ensure not NaN
        
        valid_rows = ~isnan(traces(:, 5));
        
        is_rew_block = traces(:, 2) == 1;
        is_response  = traces(:, 4) == 1;
        is_omit      = traces(:, 4) == 0;
        
        % Apply masks and append to master matrices (assuming data starts at col 5)
        % Note: Using 5:end to match "size(Rew_Trial, 2)" logic later, 
        % or you can hardcode 5:323 if consistent.
        
        % 1. Reward Trials (Responded)
        Rew_Trial = [Rew_Trial; traces(valid_rows & is_rew_block & is_response, 5:323)];
        
        % 2. Reward Omissions
        Rew_Trial_Omit = [Rew_Trial_Omit; traces(valid_rows & is_rew_block & is_omit, 5:323)];

        % 3. Reward ALL
        Rew_Trial_ALL = [Rew_Trial_ALL; traces(valid_rows & is_rew_block, 5:323)];        
        
    end
end
fprintf('✅ Data extraction complete.\n');

%% 2. Plotting Configuration
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

% ___________ Dimensions ______________
% Assuming traces are consistent length, create time vector from -10 to 40
if ~isempty(Rew_Trial)
    time = linspace(-10, 10, size(Rew_Trial, 2));
else
    error('No data found for the selected rats/sessions.');
end

% ___________ Stats Parameters ______________
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; % Adjust this based on your Z-score range

%% 3. Generate Plots 
% We replace the 1 blocks with calls to your helper function.

fprintf('Generating plots...\n');

% % --- Plot 1: Reward Trials (Responded vs Omitted) ---
% % Matches "Plot Reward" section
% createComparisonPlot(Rew_Trial, Rew_Trial_Omit, ...
%     ['rewDS Trial - responded '], ...
%     ['rewDS Trial - omitted '], ...
%     colors.green, colors.light_green, colors.yellow, ...
%     ['rewDS Trials - ', s], ...
%     time, p_val, thres, y_range);

% --- Plot 2: Reward Trials (ALL trials) ---

% % Matches "Plot Reward" section
createComparisonPlot(Rew_Trial_ALL, Rew_Trial_Omit, ...
    ['rewDS Trial - ALL '], ...
    ['rewDS Trial - omitted '], ...
    colors.green, colors.light_green, colors.yellow, ...
    ['rewDS Trials - ', s], ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');