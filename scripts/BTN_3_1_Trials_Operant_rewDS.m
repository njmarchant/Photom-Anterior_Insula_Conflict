%% Updated to include Subject Means, Streamlined Indexing, and Function Plotting

%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_06\Raw data\Rew';
filePath = fullfile(tankfolder);

% Define Subjects and Sessions
% Rat = {'R01','R02','R03','R04','R05','R07','R08'};
Rat = {'R01','R03','R04','R05','R08'};
reward_sessions = {'R06','R07','R08','R04','R05'};

% Colours (RGB values / 255)
c_rewDS = [0.12, 0.80, 0.01];
c_punDS = [0.87, 0.01, 0.12];
c_conf = [0.01, 0.11, 0.86];
c_perm = [0.5, 0.5, 0.5]; 

%% 2. Initialize Data Structures
% Organize by Rat first to allow for subject averaging
RatData = struct();
for r = 1:length(Rat)
    RatData.(Rat{r}).Rew_Trial = [];
    RatData.(Rat{r}).Rew_Trial_Omit = [];
end

%% 3. Load and Extract Traces (Streamlined Vectorized Indexing)
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through experiment folder
    % Divide the file name into separate character vectors
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); 
    rat = names{7};
    session = names{4};
    
    % Check inclusion criteria
    if ismember(rat, Rat) && any(strcmp(session, reward_sessions))
        load(fullfile(filePath, files(i).name), 'sesdat');
        
        % STREAMLINED LOGICAL INDEXING (Replaces the slow row-by-row for-loop)
        % Create logical vectors for conditions
        valid_rows = ~isnan(sesdat.traces_z_10_45(:, 5)); % Ignore rows with NaN in trace data
        is_rew_cue = sesdat.traces_zs_10_45(:, 2) == 1;    % Col 2 = 1 (Reward Cue)
        is_resp    = sesdat.traces_zs_10_45(:, 4) == 1;    % Col 4 = 1 (Responded)
        is_omit    = sesdat.traces_zs_10_45(:, 4) == 0;    % Col 4 = 0 (Omitted)
        
        % Extract Responded Trials
        idx_resp = valid_rows & is_rew_cue & is_resp;
        RatData.(rat).Rew_Trial = [RatData.(rat).Rew_Trial; sesdat.traces_zs_10_45(idx_resp, 5:323)];
        
        % Extract Omitted Trials
        idx_omit = valid_rows & is_rew_cue & is_omit;
        RatData.(rat).Rew_Trial_Omit = [RatData.(rat).Rew_Trial_Omit; sesdat.traces_zs_10_45(idx_omit, 5:323)];
    end
end

%% 4. Calculate Subject Means (One Mean Per Rat)
fprintf('Calculating Subject Means...\n');
GroupData = struct();
GroupData.Rew_Trial = [];
GroupData.Rew_Trial_Omit = [];

subjects = fieldnames(RatData);
for i = 1:length(subjects)
    ratID = subjects{i};
    
    % Mean for Responded Trials
    if ~isempty(RatData.(ratID).Rew_Trial)
        subj_mean_resp = mean(RatData.(ratID).Rew_Trial, 1, 'omitnan');
        GroupData.Rew_Trial = [GroupData.Rew_Trial; subj_mean_resp];
    end
    
    % Mean for Omitted Trials
    if ~isempty(RatData.(ratID).Rew_Trial_Omit)
        subj_mean_omit = mean(RatData.(ratID).Rew_Trial_Omit, 1, 'omitnan');
        GroupData.Rew_Trial_Omit = [GroupData.Rew_Trial_Omit; subj_mean_omit];
    end
end

%% 5. Plotting via Function Call
fprintf('Generating Plots...\n');
% Plotting Parameters

p_val = 0.05;
thres = 8;
% Define time vector dynamically based on the width of the extracted traces
if ~isempty(GroupData.Rew_Trial)
    time_press = linspace(-10, 10, size(GroupData.Rew_Trial, 2));
else
    error('No Rsponded trials met the minimum criteria. Check extraction parameters.');
end

if ~isempty(GroupData.Rew_Trial_Omit)
    time_omit = linspace(-10, 10, size(GroupData.Rew_Trial_Omit, 2));
else
    error('No Omit trials met the minimum criteria. Check extraction parameters.');
end

% Create comparison plot: Responded vs Omitted
y_lims = [-2 5]; % Adjust based on your expected z-scores
sig_windows_1 = createComparisonPlot(...
    GroupData.Rew_Trial, GroupData.Rew_Trial_Omit, ...
    'rewDS Responded', 'rewDS Omitted', ...
    c_rewDS, c_punDS, c_perm, ...
    'rewDS Trials in Reward phase', time_press, p_val, thres, y_lims);



fprintf('Script Complete.\n');