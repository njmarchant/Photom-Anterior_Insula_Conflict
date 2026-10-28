%% Nathan Marchant, modified by request
% Written for Pavlovian conflict task
% Includes: plot individual subject traces for each cue type.
% UPDATED: Now plots 4 conditions for trials, 2 conditions for responses.
% UPDATED: Selects specific trace windows and behavioral logic based on analysis type.

% --- Initialization ---
clear all;
% close all; 

% --- Set your Analysis Type ---
analysis_type = 'response'; % Change this to 'trial' or 'response'

% Determine the target trace field, plotting times, and logic based on type
if strcmpi(analysis_type, 'trial')
    target_trace_field = 'traces_zs_10_45';
    time_start = -10;
    time_end = 45;
elseif strcmpi(analysis_type, 'response')
    target_trace_field = 'traces_zs_25_15';
    time_start = -25;
    time_end = 15;
else
    error('Invalid analysis_type specified. Please enter ''trial'' or ''response''.');
end

% Define the folder to iterate through
tankfolder = 'C:\Photometry\Conflict_06\Raw data\Pun';
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

% Define the phase you want to analyze
% SESSION_TO_ANALYZE = {'P06','P07', 'P08','P09','P10'}; 
SESSION_TO_ANALYZE = {'P09','P10'}; 
% SESSION_TO_ANALYZE = {'R06','R07','R08'};% 'R01','R02','R03','R04',
% SESSION_TO_ANALYZE = {'C01','C02','C03','C04','C05'}; 

fprintf('Loading data from folder: %s\n', tankfolder);
fprintf('Extracting trace field: %s for %s analysis.\n', target_trace_field, analysis_type);

% --- Data Extraction and Processing per Subject ---
% subjects = {'C01','C03','C04','C10','C15'};
subjects = {'R01','R02','R03','R04','R05','R07','R08'};
% subjects = {'R16','R20','R17','R18','R19'};
numSubjects = length(subjects);

% Initialize a struct array to hold data for each subject
subjectData = repmat(struct('rat', '', ...
    'rewDS_C', [], 'rewDS_O', [], ...
    'punDS_C', [], 'punDS_O', [], ...
    'rewDS_C_cue', []), numSubjects, 1);
    
% Pre-fill rat IDs
for i = 1:numSubjects
    subjectData(i).rat = subjects{i};
end

% ASSUMPTION: Trace starts at column 5
TRACE_START_COL = 5;

% Loop through each file in the folder
for i = 1:length(files) 
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors
    rat = names {7};
    session = names {4};
    if ismember(rat,subjects) && ismember(session, SESSION_TO_ANALYZE)
        fprintf('Processing file: %s\n', files(i).name);
        load(fullfile(filePath,  [files(i).name])) 
        
        if ~exist('sesdat', 'var')
            fprintf('Warning: Skipping file %s. No "sesdat" variable found.\n', files(i).name);
            continue;
        end
        subjectIdx = find(strcmp(subjects, sesdat.rat));
        
        if ~isempty(subjectIdx)
            if isfield(sesdat, target_trace_field)
                trialData = sesdat.(target_trace_field); 
                
                if isempty(trialData)
                    clear sesdat; 
                    continue;
                end
                
                if size(trialData, 2) < TRACE_START_COL
                    fprintf('Warning: Skipping file %s. Not enough columns.\n', files(i).name);
                    clear sesdat; 
                    continue;
                end
                
                numTrials = size(trialData, 1);
                
                % --- UPDATED BEHAVIORAL LOGIC LOOP ---
                for j = 1:numTrials
                    trace = trialData(j, TRACE_START_COL:end);
                    trace_cue = trialData(j, TRACE_START_COL:319);

                    trialType = trialData(j, 2);
                    outcome   = trialData(j, 4);
                    
                    if strcmpi(analysis_type, 'trial')
                        % Trial Logic
                        if trialType == 1 && outcome == 1
                            subjectData(subjectIdx).rewDS_C = [subjectData(subjectIdx).rewDS_C; trace];
                        elseif trialType == 1 && outcome == 0
                            subjectData(subjectIdx).rewDS_O = [subjectData(subjectIdx).rewDS_O; trace];
                        elseif trialType == 2 && outcome == 1
                            subjectData(subjectIdx).punDS_C = [subjectData(subjectIdx).punDS_C; trace];
                        elseif trialType == 2 && outcome == 0
                            subjectData(subjectIdx).punDS_O = [subjectData(subjectIdx).punDS_O; trace];
                        end
                        
                    elseif strcmpi(analysis_type, 'response')
                        % Response Logic (No omissions)
                        if trialType == 5 
                            subjectData(subjectIdx).rewDS_C = [subjectData(subjectIdx).rewDS_C; trace];
                        elseif trialType == 6 
                            subjectData(subjectIdx).punDS_C = [subjectData(subjectIdx).punDS_C; trace];
                        end
                    end
                end
                
            else
                fprintf('Warning: Skipping file %s. "%s" not found.\n', files(i).name, target_trace_field);
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
timePoints = 0;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C_mean); timePoints = length(subjectData(i).rewDS_C_mean); break; 
    elseif ~isempty(subjectData(i).rewDS_O_mean); timePoints = length(subjectData(i).rewDS_O_mean); break;
    elseif ~isempty(subjectData(i).punDS_C_mean); timePoints = length(subjectData(i).punDS_C_mean); break;
    elseif ~isempty(subjectData(i).punDS_O_mean); timePoints = length(subjectData(i).punDS_O_mean); break;
    end
end

if timePoints == 0
    error('No valid data found in any condition to create plots.'); 
end

time = linspace(time_start, time_end, timePoints);
plotColors = lines(numSubjects); 

%% Plot 1: Reward Responded / Response
figure('Name', 'Reward Trace');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).rewDS_C_mean)
        plot(time, subjectData(i).rewDS_C_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
if strcmpi(analysis_type, 'trial')
    title('rewDS Responded (Col2=1, Col4=1) - TRIAL');
else
    title('Reward Response (Col2=5) - RESPONSE');
end
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

%% Plot 3: Punishment Responded / Response
figure('Name', 'Punishment Trace');
hold on;
for i = 1:numSubjects
    if ~isempty(subjectData(i).punDS_C_mean)
        plot(time, subjectData(i).punDS_C_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
    end
end
if strcmpi(analysis_type, 'trial')
    title('punDS Responded (Col2=2, Col4=1) - TRIAL');
else
    title('Punishment Response (Col2=6) - RESPONSE');
end
xlabel('Time (s)'); ylabel('Z-score');
line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
legend(subjects, 'Location', 'best');
hold off;

%% Plot 2 & 4: Omissions (TRIAL ONLY)
if strcmpi(analysis_type, 'trial')
    % Plot 2: rewDS Omitted
    figure('Name', 'rewDS Omitted');
    hold on;
    for i = 1:numSubjects
        if ~isempty(subjectData(i).rewDS_O_mean)
            plot(time, subjectData(i).rewDS_O_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
        end
    end
    title('rewDS Omitted (Col2=1, Col4=0) - TRIAL');
    xlabel('Time (s)'); ylabel('Z-score');
    line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
    legend(subjects, 'Location', 'best');
    hold off;

    % Plot 4: punDS Omitted 
    figure('Name', 'punDS Omitted');
    hold on;
    for i = 1:numSubjects
        if ~isempty(subjectData(i).punDS_O_mean)
            plot(time, subjectData(i).punDS_O_mean, 'Color', plotColors(i,:), 'LineWidth', 1.5);
        end
    end
    title('punDS Omitted (Col2=2, Col4=0) - TRIAL');
    xlabel('Time (s)'); ylabel('Z-score');
    line([0, 0], ylim, 'Color', 'k', 'LineStyle', '--');
    legend(subjects, 'Location', 'best');
    hold off;

  
end

fprintf('Done. Plots generated based on %s analysis.\n', analysis_type);