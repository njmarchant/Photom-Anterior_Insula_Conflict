%% NM updated for Conflict experiment 
%% UPDATED: Vectorized Extraction, Subject Means, & Function-Based Plotting
clear all
tankfolder = 'C:\Photometry\Conflict_04\Raw data\Conf_(10-45)';
condition = 'Conf Late';
filePath = fullfile(tankfolder);

% --- Session and Rat Definitions (Kept from Old Script) ---
if strcmp(condition,'Conf Early')
    included_sessions = {'C01','C02','C03','C04','C05'}; 
else
    included_sessions = {'C06','C07','C08','C09','C10'};
end
s = char(condition);

% Conf 04 Rats (Excluded R02, R09 'R01',)
% Terminated Rats: ,'R10','R11'
Rat = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'};

% --- Analysis Parameters ---
min_trials = 3; % Minimum trials required per rat for inclusion
p_val = 0.01;
thres = 8;
y_range = [-2, 6]; % Adjust this based on your Z-score range

% --- Initialize Containers for Subject Grouping ---
cond_list = {'Rew_Trial', 'Rew_Trial_Omit', 'Pun_Trial', 'Pun_Trial_Omit', ...
             'Conf_Trial', 'Conf_Trial_Omit', 'Rew_Trial_ALL', 'Pun_Trial_ALL', 'Conf_Trial_ALL'};
RatData = struct();
for r = 1:length(Rat)
    for c = 1:length(cond_list)
        RatData.(Rat{r}).(cond_list{c}) = [];
    end
end

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
        
        % --- Vectorized Method ---
        % Create logical masks for the conditions
        valid_rows = ~isnan(traces(:, 5));
        
        is_rew_block = traces(:, 2) == 1;
        is_pun_block = traces(:, 2) == 2;
        is_conf_block = traces(:, 2) == 3;
        is_response  = traces(:, 4) >= 1;
        is_omit      = traces(:, 4) == 0;
        
        % 1. Reward Trials (Responded)
        idx_rew_resp = valid_rows & is_rew_block & is_response;
        RatData.(rat).Rew_Trial = [RatData.(rat).Rew_Trial; traces(idx_rew_resp, 5:323)];
        
        % 2. Reward Omissions
        idx_rew_omit = valid_rows & is_rew_block & is_omit;
        RatData.(rat).Rew_Trial_Omit = [RatData.(rat).Rew_Trial_Omit; traces(idx_rew_omit, 5:323)];
        
        % 3. Punishment Trials (Responded)
        idx_pun_resp = valid_rows & is_pun_block & is_response;
        RatData.(rat).Pun_Trial = [RatData.(rat).Pun_Trial; traces(idx_pun_resp, 5:323)];
        
        % 4. Punishment Omissions
        idx_pun_omit = valid_rows & is_pun_block & is_omit;
        RatData.(rat).Pun_Trial_Omit = [RatData.(rat).Pun_Trial_Omit; traces(idx_pun_omit, 5:323)];
        
        % 5. Conf Trials (Responded)
        idx_conf_resp = valid_rows & is_conf_block & is_response;
        RatData.(rat).Conf_Trial = [RatData.(rat).Conf_Trial; traces(idx_conf_resp, 5:323)];
        
        % 6. Conflict Omissions
        idx_conf_omit = valid_rows & is_conf_block & is_omit;
        RatData.(rat).Conf_Trial_Omit = [RatData.(rat).Conf_Trial_Omit; traces(idx_conf_omit, 5:323)];
        
        % 7. Reward ALL
        idx_rew_all = valid_rows & is_rew_block;
        RatData.(rat).Rew_Trial_ALL = [RatData.(rat).Rew_Trial_ALL; traces(idx_rew_all, 5:323)];
        
        % 8. Punishment ALL
        idx_pun_all = valid_rows & is_pun_block;
        RatData.(rat).Pun_Trial_ALL = [RatData.(rat).Pun_Trial_ALL; traces(idx_pun_all, 5:323)];
        
        % 9. Conflict ALL
        idx_conf_all = valid_rows & is_conf_block;
        RatData.(rat).Conf_Trial_ALL = [RatData.(rat).Conf_Trial_ALL; traces(idx_conf_all, 5:323)];
    end
end
fprintf('✅ Data extraction complete.\n');

%% 2. Calculate Subject Means
fprintf('Calculating subject means (Min trials = %d)...\n', min_trials);
GroupData = struct();
for c = 1:length(cond_list)
    GroupData.(cond_list{c}) = [];
end

for i = 1:length(Rat)
    ratID = Rat{i};
    for c = 1:length(cond_list)
        cn = cond_list{c};
        traces_subset = RatData.(ratID).(cn);
        
        % Average the trials for this specific rat if they meet the threshold
        if size(traces_subset, 1) >= min_trials
            GroupData.(cn) = [GroupData.(cn); mean(traces_subset, 1, 'omitnan')];
        end
    end
end

%% 3. Plotting Configuration
% ___________ Colours ______________
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
colors.black = [0,0,0]; 

% ___________ Dimensions ______________
if ~isempty(GroupData.Rew_Trial)
    time = linspace(-10, 10, size(GroupData.Rew_Trial, 2));
else
    error('No data found for the selected rats/sessions meeting the minimum trial threshold.');
end

%% 4. Generate Plots 
fprintf('Generating plots from subject means...\n');

% --- Plot 1: Reward Trials (Responded vs Omitted) ---
createComparisonPlot(GroupData.Rew_Trial, GroupData.Rew_Trial_Omit, ...
    ['rewDS Trial - responded'], ['rewDS Trial - omitted '], ...
    colors.green, colors.light_green, colors.black, ...
    ['rewDS Trials - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 2: Punish Trials (Responded vs Omitted) ---
createComparisonPlot(GroupData.Pun_Trial, GroupData.Pun_Trial_Omit, ...
    ['punDS Trial - responded '], ['punDS Trial - omitted '], ...
    colors.red, colors.pink, colors.black, ...
    ['punDS Trials - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 3: Conflict Trials (Responded vs Omitted) ---
createComparisonPlot(GroupData.Conf_Trial, GroupData.Conf_Trial_Omit, ...
    ['Conflict Trial - responded '], ['Conflict Trial - omitted '], ...
    colors.blue, colors.azure, colors.yellow, ...
    ['Conflict Trials - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 4: Completed Trials (Reward vs Punish) ---
createComparisonPlot(GroupData.Rew_Trial, GroupData.Pun_Trial, ...
    ['rewDS Trial - responded '], ['punDS Trial - responded '], ...
    colors.green, colors.red, colors.black, ...
    ['Completed trials - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 5: Omitted Trials (Reward vs Punish) ---
createComparisonPlot(GroupData.Rew_Trial_Omit, GroupData.Pun_Trial_Omit, ...
    ['rewDS Trial - omitted '], ['punDS Trial - omitted '], ...
    colors.azure, colors.pink, colors.black, ...
    ['Omissions - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 6: ALL Trials (Reward vs Punish) ---
createComparisonPlot(GroupData.Rew_Trial_ALL, GroupData.Pun_Trial_ALL, ...
    ['rewDS Trial - ALL '], ['punDS Trial - ALL '], ...
    colors.green, colors.red, colors.yellow, ...
    ['ALL - ', s], ...
    time, p_val, thres, y_range);

% --- Plot 7: ALL Trials 3-way (Reward vs Punish vs Conflict) ---
createComparisonPlot_3way(GroupData.Rew_Trial_ALL, GroupData.Pun_Trial_ALL, GroupData.Conf_Trial_ALL, ...
    ['rewDS Trial - ALL '], ['punDS Trial - ALL '], ['Conf Trial - ALL '], ...
    colors.green, colors.red, colors.blue, colors.yellow, ...
    ['ALL 3way - ', s], ...
    time, p_val, thres, y_range);

fprintf('✅ All plots generated.\n');