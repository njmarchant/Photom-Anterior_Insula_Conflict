%% Collate Z-Score Data for Conflict Phase (Combined by Session)
% This script aggregates all conflict sessions into a single output file.
% It produces a detailed table with specific response outcomes AND a summary
% table where different response types are combined and grouped by Session.
close all;
clear all;

%% ========================================================================
%  USER SETTINGS
%  ========================================================================
% 1. Set the path to the folder containing your processed .mat files
dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';

% 2. Define where to save the final output files
outputFolder = fullfile(dataFolder, 'combined_2026');
outputFileName_mat = 'collated_conflict_data.mat';
outputFileName_csv = 'collated_2026_conflict_data_raw.csv';
outputFileName_summary_csv = 'collated_2026_conflict_data_summary.csv';
% ========================================================================

%% Initialization
collated_table = table();

%% Find and Loop Through All Data Files
filePath = fullfile(dataFolder);
filesAndFolders = dir(fullfile(filePath, '*.mat')); % Look only for .mat files
files = filesAndFolders(~[filesAndFolders.isdir]);

if isempty(files)
    error('No .mat files found in the specified dataFolder. Please check the path.');
end
disp(['Found ' num2str(length(files)) ' .mat files to process...']);

for i = 1:length(files)
    fprintf('Processing file %d of %d: %s...\n', i, length(files), files(i).name);
    
    % Load the session data
    load(fullfile(filePath, files(i).name), 'sesdat');
    
    % --- Collate the data ---
    if isfield(sesdat, 'zmean_table') && ~isempty(sesdat.zmean_table)
        tmp_table = sesdat.zmean_table;
        
        % Ensure the Session column exists in the table
        if ~ismember('Session', tmp_table.Properties.VariableNames)
            tmp_table.Session = repmat(string(sesdat.ses), height(tmp_table), 1);
        end
        
        % Append to our master table
        collated_table = [collated_table; tmp_table];
    else
        fprintf(' WARNING: zmean_table not found or empty in this file.\n');
    end
end
disp('All files processed. Now generating final summaries...');

%% Process and Save Combined Data
if ~isempty(collated_table)
    
    % =====================================================================
    % Add binary 'Outcome' column (1 = Response, 0 = Omission)
    % =====================================================================
    % Initialize column with zeros
    collated_table.Outcome = zeros(height(collated_table), 1);
    
    % Find all rows that contain some variation of a Response 
    resp_strings = string(collated_table.Response);
    is_any_response = ismember(resp_strings, ["Response", "Response-Pellet", "Response-Shock"]);
    
    % Set Outcome to 1 for those rows
    collated_table.Outcome(is_any_response) = 1;

    % =====================================================================
    % Force grouping variables to categorical arrays
    % =====================================================================
    collated_table.Rat = categorical(collated_table.Rat);
    collated_table.Session = categorical(collated_table.Session);
    collated_table.Cue = categorical(collated_table.Cue);
    collated_table.Response = categorical(collated_table.Response);
    
    % Define the specific metric columns we want to average
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    
    % Generate the summary grouped by Rat, Session, Cue, Response, AND Outcome
    summary_table = groupsummary(collated_table, {'Rat', 'Session', 'Cue', 'Outcome', 'Response'}, 'mean', vars_to_summarize);
    
    % MATLAB groupsummary automatically prepends 'mean_' to the output columns.
    % This loop renames them back to their original names for cleaner downstream use.
    for k = 1:length(vars_to_summarize)
        summary_table.Properties.VariableNames{['mean_' vars_to_summarize{k}]} = vars_to_summarize{k};
    end
    
    % Package for saving in .mat
    collatedData = struct();
    collatedData.collated_zmean_table = collated_table;
    collatedData.rat_summary_table = summary_table;
    
    % Create output directory
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    
    % 1. Save the MATLAB .mat workspace file
    save(fullfile(outputFolder, outputFileName_mat), 'collatedData');
    
    % 2. Save the RAW trial-by-trial table to CSV
    writetable(collated_table, fullfile(outputFolder, outputFileName_csv));
    
    % 3. Save the AVERAGED summary table to CSV
    writetable(summary_table, fullfile(outputFolder, outputFileName_summary_csv));
    
    fprintf('Data successfully combined and saved to: %s\n', outputFolder);
else
    disp('No data was extracted. Check if the files contained zmean_tables.');
end

disp('----------------------------------------------------');
disp('Collation & CSV Export complete!');
disp('----------------------------------------------------');