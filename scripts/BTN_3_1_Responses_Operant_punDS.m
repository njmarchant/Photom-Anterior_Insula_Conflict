%% Updated Script 2: Reward vs Punishment Responses with Subject Means
%% Includes Subject Means and Minimum Trial Threshold
%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_06\Raw data\Pun';
filePath = fullfile(tankfolder);

% Define Condition
condition = 'Pun Early'; 
s = char(condition);

% Define baseline groupings cleanly up front so initialization never crashes
% Rat = {'R01','R02','R03','R04','R05','R07','R08'};
Rat = {'R01','R03','R04','R05','R08'};

if strcmp(condition,'Pun Early')
    % included_sessions = {'P06','P07','P08','P09'};
    included_sessions = {'P09','P10'};
else
    included_sessions = {'P08','P09','P10'};

end


% Analysis Parameters
min_trials = 1;  % Minimum number of trials required per rat to be included

% Colours (RGB / 255) from Script 3
c_rewDS = [0.12, 0.80, 0.01]; % green
c_punDS = [0.87, 0.01, 0.12]; % red
c_perm = [0.5, 0.5, 0.5];

%% 2. Initialize Data Structures
% Organize by Rat first to allow for subject averaging
RatData = struct();
for r = 1:length(Rat)
    RatData.(Rat{r}).Rew_Resp = [];
    RatData.(Rat{r}).Pun_Resp = [];
end

%% 3. Load and Extract Traces
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through experiment folder
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); % divide file name into separate elements
    rat = names{7};
    session = names{4};
    
    % Track if session matches rules
    isValidSession = false;
    
    if strcmp(condition, 'Pun Early')
        if ismember(rat, Rat) && any(strcmp(session, included_sessions))
            isValidSession = true;
        end
    else
        if ismember(rat, Rat) && any(strcmp(session, included_sessions))
            isValidSession = true;
        end
    end
    
    % Extract data contextually if validation passes
    if isValidSession
        load(fullfile(filePath, files(i).name), 'sesdat');
        fprintf('Processing file: Rat %s Session %s \n', rat, session);
        for j = 1:size(sesdat.traces_zs_25_15, 1)
            if isnan(sesdat.traces_zs_25_15(j,5))
                % Skip row
            elseif sesdat.traces_zs_25_15(j, 2) == 5
                RatData.(rat).Rew_Resp = [RatData.(rat).Rew_Resp; sesdat.traces_zs_25_15(j, 5:end)];
            elseif sesdat.traces_zs_25_15(j, 2) == 6
                RatData.(rat).Pun_Resp = [RatData.(rat).Pun_Resp; sesdat.traces_zs_25_15(j, 5:end)];
            end
        end
    end
end
%% 4. Calculate Subject Means with Minimum Trial Constraint
fprintf('Calculating Subject Means (Minimum %d trials required)...\n', min_trials);
GroupData = struct();
GroupData.Rew_Resp = [];
GroupData.Pun_Resp = [];

for i = 1:length(Rat)
    ratID = Rat{i};
    
    % Reward Traces
    traces_rew = RatData.(ratID).Rew_Resp;
    if size(traces_rew, 1) >= min_trials
        GroupData.Rew_Resp = [GroupData.Rew_Resp; mean(traces_rew, 1, 'omitnan')];
    end
    
    % Punishment Traces
    traces_pun = RatData.(ratID).Pun_Resp;
    if size(traces_pun, 1) >= min_trials
        GroupData.Pun_Resp = [GroupData.Pun_Resp; mean(traces_pun, 1, 'omitnan')];
    end
end

%% 5. Plotting via Function Call
fprintf('Generating Plots...\n');
if ~isempty(GroupData.Rew_Resp) && ~isempty(GroupData.Pun_Resp)
    time = linspace(-25, 15, size(GroupData.Rew_Resp, 2));
else
    error('One or more datasets had no subjects meeting the minimum trial criteria.');
end

% Plot parameters
p_val = 0.05;
thres = 8;
y_limits = []; % Leave empty for auto-scaling
plot_title = ['Lever presses - ', s];

% Execute streamlined plot call comparing Reward vs Punishment Subject Means
sig_windows = createComparisonPlot(...
    GroupData.Rew_Resp, GroupData.Pun_Resp, ...
    'rewDS lever press', 'punDS lever press', ...
    c_rewDS, c_punDS, c_perm, ...
    plot_title, time, p_val, thres, y_limits);

disp('Significant Time Windows:');
disp(sig_windows);
fprintf('Script Complete.\n');