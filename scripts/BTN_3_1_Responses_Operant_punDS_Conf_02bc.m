%% Updated Script 2: Reward vs Punishment Responses with Subject Means
%% Includes Subject Means, Minimum Trial Threshold and trace cropping
%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(10-45)\with_resp_traces';
filePath = fullfile(tankfolder);

% Define Condition
condition = 'Pun Late'; 
s = char(condition);

% Define baseline groupings cleanly up front so initialization never crashes
all_possible_rats = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};
conf_02b_Rat = {'R09','R10','R13','R14','R16'};

if strcmp(condition,'Pun Early')
    included_sessions = {'P01','P02', 'P03'};
    Rat = all_possible_rats; % ALL rats included for Pun Early
else
    % Pun Late session mappings
    included_sessions = {'P08','P09','P10'};
    Rat = {'R12','R15','R17','R19','R20','R22','R23', 'R24'};
    conf_02b_pun_late = {'P13','P14','P15'};
    R11_pun_late = {'P04','P05','P06'};
end

% Create a master list of all unique rats to initialize the data structure safely
all_rats = unique(all_possible_rats);

% Analysis Parameters
min_trials = 5;   % Minimum number of trials required per rat to be included
crop_pre   = 15;  % s before the press to keep
crop_post  = 15;  % s after the press to keep

% Colours (RGB / 255) from Script 3
c_rewDS = [0.12, 0.80, 0.01]; % green
c_punDS = [0.87, 0.01, 0.12]; % red
c_perm = [0.5, 0.5, 0.5];

%% 2. Initialize Data Structures
% Organize by Rat first to allow for subject averaging
RatData = struct();
for r = 1:length(all_rats)
    RatData.(all_rats{r}).Rew_Resp = [];
    RatData.(all_rats{r}).Pun_Resp = [];
end

time_window = [];   % Populated from the first valid file
n_cols_ref  = [];   % Number of samples every file must match

%% 3. Load and Extract Traces
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through experiment folder
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); % divide file name into separate elements
    rat = names{8};
    session = names{7};
    
    % Track if session matches rules
    isValidSession = false;
    
    if strcmp(condition, 'Pun Early')
        % --- PUN EARLY LOGIC ---
        % Check all rats against P01, P02, P03
        if ismember(rat, Rat) && any(strcmp(session, included_sessions))
            isValidSession = true;
        end
    else
        % --- PUN LATE LOGIC ---
        % Splits up standard rats, conf_02b rats, and R11 into their respective target sessions
        if ismember(rat, Rat) && any(strcmp(session, included_sessions))
            isValidSession = true;
        elseif ismember(rat, conf_02b_Rat) && any(strcmp(session, conf_02b_pun_late))
            isValidSession = true;
        elseif strcmp(rat, 'R11') && any(strcmp(session, R11_pun_late))
            isValidSession = true;
        end
    end
    
    % Extract data contextually if validation passes
    if isValidSession
        load(fullfile(filePath, files(i).name), 'sesdat');
        fprintf('Processing file: Rat %s Session %s \n', rat, session);
        traces = sesdat.traces_z_resp;

        % --- Crop to [-crop_pre, +crop_post] s around the press ---
        t_resp = sesdat.traces_resp_time;
        i0 = find(abs(t_resp) < 1e-9, 1);                          % sample at the press
        c0 = i0 - ceil(crop_pre  * sesdat.conversion);
        c1 = min(i0 + ceil(crop_post * sesdat.conversion), numel(t_resp));
        trace_cols = 4 + (c0 : c1);                                % +4 skips the header columns

        % All files must have the same number of samples after the crop
        if isempty(n_cols_ref)
            n_cols_ref  = numel(trace_cols);
            time_window = t_resp(c0:c1);                           % exact time axis from the data
        elseif numel(trace_cols) ~= n_cols_ref
            fprintf('  SKIP %s: %d samples after crop (expected %d)\n', ...
                files(i).name, numel(trace_cols), n_cols_ref);
            continue;
        end

        for j = 1:size(traces, 1)
            if any(isnan(traces(j, trace_cols)))
                % Skip row
            elseif traces(j, 2) == 5
                RatData.(rat).Rew_Resp = [RatData.(rat).Rew_Resp; traces(j, trace_cols)];
            elseif traces(j, 2) == 6
                RatData.(rat).Pun_Resp = [RatData.(rat).Pun_Resp; traces(j, trace_cols)];
            end
        end
    end
end

%% 4. Calculate Subject Means with Minimum Trial Constraint
fprintf('Calculating Subject Means (Minimum %d trials required)...\n', min_trials);
GroupData = struct();
GroupData.Rew_Resp = [];
GroupData.Pun_Resp = [];

for i = 1:length(all_rats)
    ratID = all_rats{i};
    
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
    time = time_window;   % -crop_pre to +crop_post, taken from traces_resp_time
else
    error('One or more datasets had no subjects meeting the minimum trial criteria.');
end

% Plot parameters
p_val = 0.05;
thres = 8;
y_limits = [-1 7]; % Leave empty for auto-scaling
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