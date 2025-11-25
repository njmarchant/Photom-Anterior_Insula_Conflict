%% Nathan Marchant, modified by request
% Written for Pavlovian conflict task
% Includes: plot individual subject traces for each cue type.
% --- Initialization ---
clear all;
close all; % Good practice to close figures
% Define the folder to iterate through
tankfolder = 'C:\Photometry\Conflict_04\Rew';
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
% Define the phase you want to analyze
PHASE_TO_ANALYZE = 'Rew'; % <--- SET YOUR DESIRED PHASE HERE ('Reward', 'Conflict', 'Discrimination')
fprintf('Loading data from folder: %s\n', tankfolder);
fprintf('Processing for phase: %s\n', PHASE_TO_ANALYZE);
% --- Data Extraction and Processing per Subject ---
% Define subjects
subjects = {'R01','R02','R05','R06','R07','R08','R09','R10'}; % Hardcoded list from example
numSubjects = length(subjects);
% Initialize a struct array to hold data for each subject
% This creates a structure where each element corresponds to one subject.
subjectData = repmat(struct('rat', '', 'rewDS_C', [], 'rewDS_O', []), numSubjects, 1);
% Pre-fill rat IDs
for i = 1:numSubjects
    subjectData(i).rat = subjects{i};
end
% ASSUMPTION: Define the column where trace data (dF/F) begins
% We assume columns 1-4 are for metadata/flags, and the trace starts at 5.
% --- If your trace starts at a different column, CHANGE THIS VALUE ---
TRACE_START_COL = 5;
% Loop through each file in the folder
for i = 1:length(files) %iterate through experiment folder
    fprintf('Processing file: %s\n', files(i).name);
    load(fullfile(filePath,  [files(i).name])) % This should load 'sesdat'
    
    % Check if 'sesdat' was loaded
    if ~exist('sesdat', 'var')
        fprintf('Warning: Skipping file %s. No "sesdat" variable found.\n', files(i).name);
        clear sesdat; % Clear in case it's a partial load
        continue;
    end
    
    % --- NEW LOGIC: Process this file's 'sesdat' ---
    
    % Check if the current file matches the desired phase
    if isfield(sesdat, 'phase') && strcmp(sesdat.phase, PHASE_TO_ANALYZE)
        % Find the index corresponding to the current subject
        subjectIdx = find(strcmp(subjects, sesdat.rat));
        
        if ~isempty(subjectIdx)
            % Process trials from sesdat.traces_z
            if isfield(sesdat, 'traces_z')
                trialData = sesdat.traces_z;
                
                % Skip if no data for this session
                if isempty(trialData)
                    clear sesdat; % Clear for next loop
                    continue;
                end
                
                % Check if data has enough columns to contain trace data
                if size(trialData, 2) < TRACE_START_COL
                    fprintf('Warning: Skipping file %s for rat %s. Not enough columns in traces_z.\n', files(i).name, sesdat.rat);
                    clear sesdat; % Clear for next loop
                    continue;
                end
                
                numTrials = size(trialData, 1);
                
                % Loop through each trial (j) in this session
                for j = 1:numTrials
                    % Get the trace data for this trial
                    % Assumes trace data starts from TRACE_START_COL
                    trace = trialData(j, TRACE_START_COL:end);
                    
                    % Check conditions based on columns 2 and 4
                    % rewDS_C: col 2 == 1 AND col 4 == 1
                    is_rewDS_C = (trialData(j, 2) == 1) && (trialData(j, 4) == 1);
                    % rewDS_O: col 2 == 1 AND col 4 == 0
                    is_rewDS_O = (trialData(j, 2) == 1) && (trialData(j, 4) == 0);
                    
                    % Append the trace to the correct condition field
                    if is_rewDS_C
                        subjectData(subjectIdx).rewDS_C = [subjectData(subjectIdx).rewDS_C; trace];
                    elseif is_rewDS_O
                        subjectData(subjectIdx).rewDS_O = [subjectData(subjectIdx).rewDS_O; trace];
                    end
                end
                
            else
                % Add a warning if the expected data field isn't there
                fprintf('Warning: Skipping file %s for rat %s. Field "traces_z" not found.\n', files(i).name, sesdat.rat);
            end
            % --- End of trial processing ---
            
        end % if ~isempty(subjectIdx)
    end % if strcmp(sesdat.phase, PHASE_TO_ANALYZE)
    
    clear sesdat; % Clear for the next loop iteration
end % End of file loop
% Calculate the mean trace for each subject for each cue type
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C)
        subjectData(i).rewDS_C_mean = mean(subjectData(i).rewDS_C, 1);
    else
        subjectData(i).rewDS_C_mean = []; % Handle cases where a subject has no data
    end
    
    if ~isempty(subjectData(i).rewDS_O)
        subjectData(i).rewDS_O_mean = mean(subjectData(i).rewDS_O, 1);
    else
        subjectData(i).rewDS_O_mean = [];
    end
end
% --- Plotting ---
% Define time vector (assumes all data has the same number of time points)
timePoints = 0;
% Find a valid data trace to determine the number of time points
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C_mean)
        timePoints = length(subjectData(i).rewDS_C_mean);
        break; % Found a valid trace, so we can exit the loop
    elseif ~isempty(subjectData(i).rewDS_O_mean)
        timePoints = length(subjectData(i).rewDS_O_mean);
        break; % Check the other condition just in case
    end
end
if timePoints == 0; error('No valid data found to create plots.'); end;
time = linspace(-10, 40, timePoints);
% Define a set of distinct colors for the plots
plotColors = lines(numSubjects);
%% Plot 1: rewDS_C Individual Traces
figure('Name', 'rewDS_C per Subject');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C_mean)
        plot(time, subjectData(i).rewDS_C_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
hold off;
% Add reference lines for cue and outcome
ax = gca;
yLimits = ax.YLim;
line([0, 0], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line([20, 20], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line(ax.XLim, [0, 0], 'Color', 'k', 'LineStyle', '-');
% Add labels and title
title(['rewDS\_C Responses by Subject - ' PHASE_TO_ANALYZE ' Phase']);
xlabel('Time from Cue Onset (s)');
ylabel('dF/F (Z-score)');
legend(subjects, 'Location', 'northwest');
grid on;
%% Plot 2: rewDS_O Individual Traces
figure('Name', 'rewDS_O per Subject');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_O_mean)
        plot(time, subjectData(i).rewDS_O_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
hold off;
% Add reference lines
ax = gca;
yLimits = ax.YLim;
line([0, 0], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line([20, 20], yLimits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line(ax.XLim, [0, 0], 'Color', 'k', 'LineStyle', '-');
% Add labels and title
title(['rewDS\_O Responses by Subject - ' PHASE_TO_ANALYZE ' Phase']);
xlabel('Time from Cue Onset (s)');
ylabel('dF/F (Z-score)');
legend(subjects, 'Location', 'northwest');
grid on;