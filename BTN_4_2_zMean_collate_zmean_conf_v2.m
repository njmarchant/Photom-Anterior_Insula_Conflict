%% Collate Z-Score Data for Conflict Phase (Early vs. Late)
% This script sorts session data into 'early' and 'late' phases.
% It produces a detailed table with specific response outcomes AND a summary
% table where different response types are combined for averaging.

close all;
clear all;
close all;

%% ========================================================================
%  USER SETTINGS & RULES
%  ========================================================================
% 1. Set the path to the folder containing your processed .mat files
dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-45)';

% 2. Define where to save the final output files
outputFolder = fullfile(dataFolder, 'combined_v2');
outputFileName_Early = 'collated_conflict_EARLY_phase_data.mat';
outputFileName_Late = 'collated_conflict_LATE_phase_data.mat';

% 3. Define the rules for sorting sessions into phases
% -- Session IDs for each phase --
% General Rules
conf_early_sessions = {'C01','C02','C03','C04','C05'};
conf_late_sessions = {'C11','C12','C13','C14','C15'};
% Exception for Rat R11
R11_conf_late_sessions = {'C08','C07','C06','C05'};
% ========================================================================

%% Initialization for Both Phases
collated_early_table = table();
collated_late_table = table();

%% Find and Loop Through All Data Files
filePath = fullfile(dataFolder);
filesAndFolders = dir(fullfile(filePath, '*.mat')); % Look only for .mat files
files = filesAndFolders(~[filesAndFolders.isdir]);

if isempty(files)
    error('No .mat files found in the specified dataFolder. Please check the path.');
end

disp(['Found ' num2str(length(files)) ' .mat files to process...']);

for i = 1:length(files)
    fprintf('Processing file %d of %d: %s...', i, length(files), files(i).name);
    
    % Load the session data
    load(fullfile(filePath, files(i).name), 'sesdat');
    
    % --- Decision Logic: Assign session to a phase ---
    current_rat = sesdat.rat;
    current_session = sesdat.ses;
    phase_assignment = 'unassigned'; % Default
    
    % Check for the special case (R11) first
    if strcmp(current_rat, 'R11')
        if ismember(current_session, R11_conf_late_sessions)
            phase_assignment = 'late';
        elseif ismember(current_session, conf_early_sessions)
            phase_assignment = 'early';
        end
    else % Apply general rules for all other rats
        if ismember(current_session, conf_early_sessions)
            phase_assignment = 'early';
        elseif ismember(current_session, conf_late_sessions)
            phase_assignment = 'late';
        end
    end
    
    % --- Collate the data based on the assignment ---
    if isfield(sesdat, 'zmean_table') && ~isempty(sesdat.zmean_table)
        switch phase_assignment
            case 'early'
                collated_early_table = [collated_early_table; sesdat.zmean_table];
                fprintf(' Assigned to EARLY phase.\n');
            case 'late'
                collated_late_table = [collated_late_table; sesdat.zmean_table];
                fprintf(' Assigned to LATE phase.\n');
            otherwise
                fprintf(' WARNING: Not assigned to any phase.\n');
        end
    else
        fprintf(' WARNING: zmean_table not found or empty.\n');
    end
end

disp('All files processed. Now generating final summaries...');

%% Process and Save EARLY Phase Data
if ~isempty(collated_early_table)
    %% Temporarily group all response types for summary calculation
    % Create a temporary table for grouping
    summary_grouping_table_early = collated_early_table;
    % Find all rows that are a type of response (not an omission)
    is_any_response = ismember(summary_grouping_table_early.Response, {'Response', 'Response-Pellet', 'Response-Shock'});
    % Relabel them to a single 'Response' category in the temporary table
    summary_grouping_table_early.Response(is_any_response) = {'Response'};
    
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    % Use the temporary table for the summary calculation
    summary_early = groupsummary(summary_grouping_table_early, {'Rat', 'TrialType', 'Response'}, 'mean', vars_to_summarize);
    
    for k = 1:length(vars_to_summarize)
        summary_early.Properties.VariableNames{['mean_' vars_to_summarize{k}]} = vars_to_summarize{k};
    end
    
    collatedData_early = struct();
    collatedData_early.collated_zmean_table = collated_early_table;
    collatedData_early.rat_summary_table = summary_early;
    
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    save(fullfile(outputFolder, outputFileName_Early), 'collatedData_early');
    fprintf('EARLY phase data saved to: %s\n', fullfile(outputFolder, outputFileName_Early));
else
    disp('No data was assigned to the EARLY phase.');
end

%% Process and Save LATE Phase Data
if ~isempty(collated_late_table)
    %% Temporarily group all response types for summary calculation
    % Create a temporary table for grouping
    summary_grouping_table_late = collated_late_table;
    % Find all rows that are a type of response (not an omission)
    is_any_response = ismember(summary_grouping_table_late.Response, {'Response', 'Response-Pellet', 'Response-Shock'});
    % Relabel them to a single 'Response' category in the temporary table
    summary_grouping_table_late.Response(is_any_response) = {'Response'};
    
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    % Use the temporary table for the summary calculation
    summary_late = groupsummary(summary_grouping_table_late, {'Rat', 'TrialType', 'Response'}, 'mean', vars_to_summarize);
    
    for k = 1:length(vars_to_summarize)
        summary_late.Properties.VariableNames{['mean_' vars_to_summarize{k}]} = vars_to_summarize{k};
    end

    collatedData_late = struct();
    collatedData_late.collated_zmean_table = collated_late_table;
    collatedData_late.rat_summary_table = summary_late;
    
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    save(fullfile(outputFolder, outputFileName_Late), 'collatedData_late');
    fprintf('LATE phase data saved to: %s\n', fullfile(outputFolder, outputFileName_Late));
else
    disp('No data was assigned to the LATE phase.');
end

disp('----------------------------------------------------');
disp('Collation complete!');
disp('----------------------------------------------------');