%% Collate Z-Score Data Across All Rats and Sessions
% This script is designed for the 'reward_only' phase of the experiment.
% It collects all individual session files and produces two main outputs:
% 1. collated_zmean_table: A single table with every trial from every rat.
% 2. rat_summary_table: A table summarizing the mean z-scores and latency 
%    for each rat, calculated across ALL of their individual trials.

close all;
clear all;
close all;

%% ========================================================================
%  USER SETTINGS
%  ========================================================================
% 1. Set the path to the folder containing your processed .mat files
dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(10-45)';

% 2. Define where to save the final output file
outputFolder = fullfile(dataFolder, 'combined_v2');
outputFileName = 'collated_reward_only_phase_data.mat';
% ========================================================================


%% Section 1: Initialization and File Discovery
% -------------------------------------------------------------------------
% Initialize an empty table to hold all trial-by-trial data.
collated_zmean_table = table();

% Find all .mat files in the specified data folder.
filePath = fullfile(dataFolder);
filesAndFolders = dir(fullfile(filePath, '*.mat'));
files = filesAndFolders(~[filesAndFolders.isdir]);

% Check if any files were found and stop if not.
if isempty(files)
    error('No .mat files found in the specified dataFolder. Please check the path.');
end


%% Section 2: Data Collation Loop
% -------------------------------------------------------------------------
% Loop through each file, load its data, and append it to the master table.
disp(['Found ' num2str(length(files)) ' .mat files to process...']);
for i = 1:length(files)
    fprintf('Processing file %d of %d: %s\n', i, length(files), files(i).name);
    
    % Load the 'sesdat' structure from the current .mat file.
    load(fullfile(filePath, files(i).name), 'sesdat');
    
    % Check if the file contains the 'zmean_table' and if it's not empty.
    if isfield(sesdat, 'zmean_table') && ~isempty(sesdat.zmean_table)
        % Append the current session's table to the master collated table.
        collated_zmean_table = [collated_zmean_table; sesdat.zmean_table];
    end
end


%% Section 3: Generate Summary Statistics
% -------------------------------------------------------------------------
disp('All files processed. Now generating final summary from all collated trials...');
if ~isempty(collated_zmean_table)
    
    % Define which columns from the table should be averaged.
    %% MODIFIED: Added 'Latency' to the list of variables to summarize.
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    
    % Use groupsummary to calculate the mean for each variable, grouped by
    % Rat and Response type. This calculates the average across ALL trials.
    % The 'GroupCount' output will be the total number of trials per group.
    rat_summary_table = groupsummary(collated_zmean_table, {'Rat', 'Response'}, 'mean', vars_to_summarize);

    % Clean up the output column names (e.g., remove the default 'mean_' prefix).
    for k = 1:length(vars_to_summarize)
        rat_summary_table.Properties.VariableNames{['mean_' vars_to_summarize{k}]} = vars_to_summarize{k};
    end
    
else
    disp('No trial data was found to process.');
    rat_summary_table = table();
end


%% Section 4: Save Final Output
% -------------------------------------------------------------------------
% Create the output folder if it doesn't already exist.
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% Store both the detailed and summary tables in a single structure.
collatedData = struct();
collatedData.collated_zmean_table = collated_zmean_table;
collatedData.rat_summary_table = rat_summary_table;

% Save the structure to a .mat file.
save(fullfile(outputFolder, outputFileName), 'collatedData');

% Display a confirmation message to the user.
disp('----------------------------------------------------');
disp('Collation complete!');
fprintf('Final data saved to: %s\n', fullfile(outputFolder, outputFileName));
disp('The file contains a struct "collatedData" with two tables:');
disp('  1. collated_zmean_table: All trials from all rats.');
disp('  2. rat_summary_table: Mean z-scores and latency per rat for each response type.');
disp('----------------------------------------------------');