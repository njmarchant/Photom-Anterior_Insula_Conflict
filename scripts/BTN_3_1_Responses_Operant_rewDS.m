%% Updated Script 1: Reward Responses with Subject Means
%% Includes Subject Means, Minimum Trial Threshold and trace cropping
%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(10-45)\with_resp_traces';
filePath = fullfile(tankfolder);

% Define Subject Groupings & Session Rules
rew_all = {'R01','R02','R03','R04','R05'};
% R18 and R21 should be removed based on inspection of the daily traces
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};
% Rat = {'R01','R02','R03','R04','R05','R07','R08'};
% Rat = {'R01','R03','R04','R05','R08'};

% Create a master list of all unique rats to initialize the data structure
all_rats = unique(Rat);

% Analysis Parameters
min_trials = 5;   % Minimum number of trials required per rat to be included
crop_pre   = 15;  % s before the press to keep
crop_post  = 15;  % s after the press to keep

% Colours (RGB / 255) from Script 3
c_rewDS = [0.12, 0.80, 0.01]; % green matching script_3
c_perm = [0.5, 0.5, 0.5];

%% 2. Initialize Data Structures
RatData = struct();
for r = 1:length(all_rats)
    RatData.(all_rats{r}).Rew_Resp = [];
end

time_window = [];   % Populated from the first valid file
n_cols_ref  = [];   % Number of samples every file must match

%% 3. Load and Extract Traces
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]);
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through experiment folder
    load(fullfile(filePath, files(i).name), 'sesdat');
    rat = sesdat.rat;
    session = sesdat.ses;

    % Check if this specific Rat + Session combination is valid
    if ismember(rat, Rat) && any(strcmp(session, rew_all))

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

        % Loop to parse rows safely (ignoring NaNs in the cropped window, checking target code)
        for j = 1:size(traces, 1)
            if any(isnan(traces(j, trace_cols)))
                % Skip row
            elseif traces(j, 2) == 5
                RatData.(rat).Rew_Resp = [RatData.(rat).Rew_Resp; traces(j, trace_cols)];
            end
        end
    end
end

%% 4. Calculate Subject Means with Minimum Trial Constraint
fprintf('Calculating Subject Means (Minimum %d trials required)...\n', min_trials);
GroupData = struct();
GroupData.Rew_Resp = [];

for i = 1:length(all_rats)
    ratID = all_rats{i};
    traces_rew = RatData.(ratID).Rew_Resp;
    if size(traces_rew, 1) >= min_trials
        GroupData.Rew_Resp = [GroupData.Rew_Resp; mean(traces_rew, 1, 'omitnan')];
    end
end

%% 5. Plotting via Function Call
fprintf('Generating Plots...\n');
if ~isempty(GroupData.Rew_Resp)
    time = time_window;   % -crop_pre to +crop_post, taken from traces_resp_time
else
    error('No trials met the minimum criteria. Check extraction parameters.');
end

% Plot parameters
p_val = 0.05;
thres = 8;
y_limits = []; % Leave empty for auto-scaling, or set explicitly e.g., [-1 3]
plot_title = 'Reward phase, rewDS - Lever Press';

% Note: Since Script 1 only tracks one group (Reward), we pass it against itself
% or a baseline matrix as needed by your createComparisonPlot architecture.
sig_windows = createComparisonPlot(...
    GroupData.Rew_Resp, GroupData.Rew_Resp, ...
    'Reward completions', 'Reward completions (Ref)', ...
    c_rewDS, c_rewDS, c_perm, ...
    plot_title, time, p_val, thres, y_limits);

disp('Significant Time Windows:');
disp(sig_windows);
fprintf('Script Complete.\n');