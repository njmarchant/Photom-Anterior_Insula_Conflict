%% Nathan Marchant, modified by request
% Written for Pavlovian conflict task
% Includes: plot individual subject traces for each cue type.
% UPDATED: Now plots 4 conditions (Rew/Pun x Responded/Omitted)

% --- Initialization ---
clear all;
% close all; 

% Define the folder to iterate through
tankfolder = 'C:\Photometry\Conflict_04\Rew_(25-15)';
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

% Define the phase you want to analyze
SESSION_TO_ANALYZE = {'R01', 'R02','R03'}; 

fprintf('Loading data from folder: %s\n', tankfolder);
% fprintf('Processing for phase: %s\n', SESSION_TO_ANALYZE);

% --- Data Extraction and Processing per Subject ---
% Define subjects
% subjects = {'R01','R02','R05','R06','R07','R08','R09','R12','R13','R14'}; 
subjects = {'R10','R11'}; 
% subjects = {'R01','R02','R05'}; 
% subjects = {'R06','R07','R08'}; 
% subjects = {'R09','R12','R13','R14'}; 
numSubjects = length(subjects);

% Initialize a struct array to hold data for each subject
% UPDATED: Added fields for Punishment (punDS)
subjectData = repmat(struct('rat', '', ...
    'rewDS_C', [], 'rewDS_O', [], ...
    'punDS_C', [], 'punDS_O', []), numSubjects, 1);

% Pre-fill rat IDs
for i = 1:numSubjects
    subjectData(i).rat = subjects{i};
end

% ASSUMPTION: Trace starts at column 5
TRACE_START_COL = 5;

% Loop through each file in the folder
for i = 1:length(files) 
    fprintf('Processing file: %s\n', files(i).name);
    load(fullfile(filePath,  [files(i).name])) 
    
    % Check if 'sesdat' was loaded
    if ~exist('sesdat', 'var')
        fprintf('Warning: Skipping file %s. No "sesdat" variable found.\n', files(i).name);
        continue;
    end
    
    % Check if the current file matches the desired phase
    if isfield(sesdat, 'ses') && ismember(sesdat.ses, SESSION_TO_ANALYZE)
        % Find the index corresponding to the current subject
        subjectIdx = find(strcmp(subjects, sesdat.rat));
        
        if ~isempty(subjectIdx)
            % Process trials from sesdat.traces_z
            if isfield(sesdat, 'traces_z')
                trialData = sesdat.traces_z;
                
                if isempty(trialData)
                    clear sesdat; 
                    continue;
                end
                
                % Check columns
                if size(trialData, 2) < TRACE_START_COL
                    fprintf('Warning: Skipping file %s. Not enough columns.\n', files(i).name);
                    clear sesdat; 
                    continue;
                end
                
                numTrials = size(trialData, 1);
                
                % Loop through each trial (j)
                for j = 1:numTrials
                    trace = trialData(j, TRACE_START_COL:end);
                    
                    % --- UPDATED CONDITION LOGIC ---
                    % Column 2: 1 = Reward, 2 = Punishment
                    % Column 4: 1 = Responded, 0 = Omitted
                    
                    trialType = trialData(j, 2);
                    outcome   = trialData(j, 4);
                    
                    if trialType == 5 %&& outcome == 1
                        % Reward Responded
                        subjectData(subjectIdx).rewDS_C = [subjectData(subjectIdx).rewDS_C; trace];
                        
                    elseif trialType == 1 && outcome == 0
                        % Reward Omitted
                        subjectData(subjectIdx).rewDS_O = [subjectData(subjectIdx).rewDS_O; trace];
                        
                    elseif trialType == 6 %&& outcome == 1
                        % Punishment Responded
                        subjectData(subjectIdx).punDS_C = [subjectData(subjectIdx).punDS_C; trace];
                        
                    elseif trialType == 2 && outcome == 0
                        % Punishment Omitted
                        subjectData(subjectIdx).punDS_O = [subjectData(subjectIdx).punDS_O; trace];
                    end
                end
                
            else
                fprintf('Warning: Skipping file %s. "traces_z" not found.\n', files(i).name);
            end
        end 
    end 
    clear sesdat; 
end 

% --- Calculate Means ---
fprintf('Calculating means per subject...\n');
for i = 1:numSubjects
    % Reward
    if ~isempty(subjectData(i).rewDS_C); subjectData(i).rewDS_C_mean = mean(subjectData(i).rewDS_C, 1);
    else; subjectData(i).rewDS_C_mean = []; end
    
    if ~isempty(subjectData(i).rewDS_O); subjectData(i).rewDS_O_mean = mean(subjectData(i).rewDS_O, 1);
    else; subjectData(i).rewDS_O_mean = []; end
    
    % Punishment
    if ~isempty(subjectData(i).punDS_C); subjectData(i).punDS_C_mean = mean(subjectData(i).punDS_C, 1);
    else; subjectData(i).punDS_C_mean = []; end
    
    if ~isempty(subjectData(i).punDS_O); subjectData(i).punDS_O_mean = mean(subjectData(i).punDS_O, 1);
    else; subjectData(i).punDS_O_mean = []; end
end

% --- Plotting Setup ---
% Determine time vector length based on any available data
timePoints = 0;
for i = 1:numSubjects
    % Check all 4 fields to find a valid length
    if ~isempty(subjectData(i).rewDS_C_mean); timePoints = length(subjectData(i).rewDS_C_mean); break; 
    elseif ~isempty(subjectData(i).rewDS_O_mean); timePoints = length(subjectData(i).rewDS_O_mean); break;
    elseif ~isempty(subjectData(i).punDS_C_mean); timePoints = length(subjectData(i).punDS_C_mean); break;
    elseif ~isempty(subjectData(i).punDS_O_mean); timePoints = length(subjectData(i).punDS_O_mean); break;
    end
end

if timePoints == 0
    error('No valid data found in any condition to create plots.'); 
end

time = linspace(-25, 15, timePoints);
plotColors = lines(numSubjects); % Assign distinct color per rat

%% Plot 1: rewDS Responded (Original)
figure('Name', 'rewDS Responded');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C_mean)
        plot(time, subjectData(i).rewDS_C_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
title(['rewDS Responded (Col2=1, Col4=1)']);
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

%% Plot 2: rewDS Omitted (Original)
figure('Name', 'rewDS Omitted');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_O_mean)
        plot(time, subjectData(i).rewDS_O_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
title(['rewDS Omitted (Col2=1, Col4=0)']);
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

%% Plot 3: punDS Responded (NEW)
figure('Name', 'punDS Responded');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).punDS_C_mean)
        plot(time, subjectData(i).punDS_C_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
title(['punDS Responded (Col2=2, Col4=1)']);
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

%% Plot 4: punDS Omitted (NEW)
figure('Name', 'punDS Omitted');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).punDS_O_mean)
        plot(time, subjectData(i).punDS_O_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
title(['punDS Omitted (Col2=2, Col4=0)']);
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

fprintf('Done. 4 plots generated.\n');