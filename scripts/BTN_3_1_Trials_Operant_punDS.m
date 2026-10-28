%% Updated Script: Omitted Trials (Punishment vs Reward)
%% Includes Subject Means, Streamlined Indexing, and Minimum Trial Threshold

%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_06\Raw data\Pun';
filePath = fullfile(tankfolder);

% Define Condition
condition = 'Pun Early';
s = char(condition);

if strcmp(condition,'Pun Early')
    % included_sessions = {'P06','P07','P08','P09'};
    included_sessions = {'P09','P10'};
else
    included_sessions = {'P08','P09','P10'};
end

% Rat groupings and their specific session requirements
Rat = {'R01','R02','R03','R04','R05','R07','R08'};
% Rat = {'R01','R03','R04','R05','R08'};

% Analysis Parameters
min_trials = 1;  % <--- NEW: Minimum number of trials required per rat to be included


% Colours (RGB / 255)
c_rewDS = [0.12, 0.80, 0.01];
c_punDS = [0.87, 0.01, 0.12];
c_conf = [0.01, 0.11, 0.86];
c_perm = [0.5, 0.5, 0.5];

%% 2. Initialize Data Structures
% Organize by Rat first to allow for subject averaging
RatData = struct();
for r = 1:length(Rat)
    RatData.(Rat{r}).Rew_Trial_Press = [];
    RatData.(Rat{r}).Pun_Trial_Press = [];
    RatData.(Rat{r}).Rew_Trial_Omit = [];
    RatData.(Rat{r}).Pun_Trial_Omit = [];
end

%% 3. Load and Extract Traces (Streamlined Vectorized Indexing)
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through experiment folder
    load(fullfile(filePath, files(i).name), 'sesdat');
    rat = sesdat.rat;
    session = sesdat.ses;
    
    % Check if this specific Rat + Session combination is valid based on your rules
    isValidSession = false;
    if ismember(rat, Rat) && any(strcmp(session, included_sessions))
        isValidSession = true;
    end
    
    % If valid, extract data using vectorized logical indexing
    if isValidSession
        % Define condition logic
        valid_rows = ~isnan(sesdat.traces_z_10_45(:, 5)); % Ignore rows with NaN
        is_press   = sesdat.traces_zs_10_45(:, 4) == 1;    % Col 4 = 1 (Press)
        is_omit    = sesdat.traces_zs_10_45(:, 4) == 0;    % Col 4 = 0 (Omitted)
        is_rew     = sesdat.traces_zs_10_45(:, 2) == 1;    % Col 2 = 1 (Reward Cue)
        is_pun     = sesdat.traces_zs_10_45(:, 2) == 2;    % Col 2 = 2 (Punishment Cue)
        
        % Extract Press Reward Trials
        idx_rew_press = valid_rows & is_rew & is_press;
        RatData.(rat).Rew_Trial_Press = [RatData.(rat).Rew_Trial_Press; sesdat.traces_zs_10_45(idx_rew_press, 5:323)];

        % Extract Omitted Reward Trials
        idx_rew_omit = valid_rows & is_rew & is_omit;
        RatData.(rat).Rew_Trial_Omit = [RatData.(rat).Rew_Trial_Omit; sesdat.traces_zs_10_45(idx_rew_omit, 5:end)];
        
        % Extract Omitted Punishment Trials
        idx_pun_press = valid_rows & is_pun & is_press;
        RatData.(rat).Pun_Trial_Press = [RatData.(rat).Pun_Trial_Press; sesdat.traces_zs_10_45(idx_pun_press, 5:323)];

        % Extract Omitted Punishment Trials
        idx_pun_omit = valid_rows & is_pun & is_omit;
        RatData.(rat).Pun_Trial_Omit = [RatData.(rat).Pun_Trial_Omit; sesdat.traces_zs_10_45(idx_pun_omit, 5:end)];
    end
end

%% 4. Calculate Subject Means with Minimum Trial Constraint
fprintf('Calculating Subject Means (Minimum %d trials required)...\n', min_trials);
GroupData = struct();
GroupData.Rew_Trial_Press = [];
GroupData.Pun_Trial_Press = [];
GroupData.Rew_Trial_Omit = [];
GroupData.Pun_Trial_Omit = [];

for i = 1:length(Rat)
    ratID = Rat{i};
    
    % Reward Press
    traces_rew_press = RatData.(ratID).Rew_Trial_Press;
    if size(traces_rew_press, 1) >= min_trials
        GroupData.Rew_Trial_Press = [GroupData.Rew_Trial_Press; mean(traces_rew_press, 1, 'omitnan')];
    end
    
    % Punishment Press
    traces_pun_press = RatData.(ratID).Pun_Trial_Press;
    if size(traces_pun_press, 1) >= min_trials
        GroupData.Pun_Trial_Press = [GroupData.Pun_Trial_Press; mean(traces_pun_press, 1, 'omitnan')];
    end

    % Reward Omissions
    traces_rew_omit = RatData.(ratID).Rew_Trial_Omit;
    if size(traces_rew_omit, 1) >= min_trials
        GroupData.Rew_Trial_Omit = [GroupData.Rew_Trial_Omit; mean(traces_rew_omit, 1, 'omitnan')];
    end
    
    % Punishment Omissions
    traces_pun_omit = RatData.(ratID).Pun_Trial_Omit;
    if size(traces_pun_omit, 1) >= min_trials
        GroupData.Pun_Trial_Omit = [GroupData.Pun_Trial_Omit; mean(traces_pun_omit, 1, 'omitnan')];
    end
end

%% 5. Plotting via Function Call
fprintf('Generating Plots...\n');

% Define time vector dynamically based on the width of the extracted traces
if ~isempty(GroupData.Rew_Trial_Press)
    time_press = linspace(-10, 10, size(GroupData.Rew_Trial_Press, 2));
else
    error('No Rsponded trials met the minimum criteria. Check extraction parameters.');
end

if ~isempty(GroupData.Pun_Trial_Omit)
    time_omit = linspace(-10, 45, size(GroupData.Rew_Trial_Omit, 2));
else
    error('No Omit trials met the minimum criteria. Check extraction parameters.');
end

%stats
p_val = 0.05;
thres = 8;

% Create comparison plot: Pressed Reward vs Pressed Punishment
y_limits = [];   % Leave empty for auto-scaling, or set e.g. [-2 4]
plot_title = ['Responses - ', s];
sig_windows_1 = createComparisonPlot(...
    GroupData.Rew_Trial_Press, GroupData.Pun_Trial_Press, ...
    'rewDS Responded', 'punDS Responded', ...
    c_rewDS, c_punDS, c_perm, ...
    plot_title, time_press, p_val, thres, y_limits);

% Create comparison plot: Omitted Reward vs Omitted Punishment
y_limits = [-2 4];   % Leave empty for auto-scaling, or set e.g. [-2 4]
plot_title = ['Omissions - ', s];
sig_windows_2 = createComparisonPlot(...
    GroupData.Rew_Trial_Omit, GroupData.Pun_Trial_Omit, ...
    'rewDS Omitted', 'punDS Omitted', ...
     c_rewDS, c_punDS, c_perm, ...
    plot_title, time_omit, p_val, thres, y_limits);

% Print the significant windows table to the console
disp('Significant Time Windows:');
disp(sig_windows_1);
disp(sig_windows_2);

fprintf('Script Complete.\n');