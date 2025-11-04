%% Collate Z-Score Data for Punishment Phase (Early vs. Late)
% This script sorts session data into 'early' and 'late' phases based on
% predefined rules for different groups of rats. It then produces two
% separate output files, one for each phase.

close all;
clear all;
close all;

%% ========================================================================
%  USER SETTINGS & RULES
%  ========================================================================
% 1. Set the path to the folder containing your processed .mat files
dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(25-15)';

% 2. Define where to save the final output files
outputFolder = fullfile(dataFolder, 'collated_output_punish');
outputFileName_Early = 'collated_punish_EARLY_phase_data.mat';
outputFileName_Late = 'collated_punish_LATE_phase_data.mat';

% 3. Define the rules for sorting rats/sessions into phases
% -- Groups of Rats --
conf_02b_Rat = {'R09','R10','R13','R14','R16'};

% -- Session IDs for each phase --
% General Rules
pun_early_sessions = {'P01','P02','P03','P04','P05'};
pun_late_sessions = {'P06','P07','P08','P09','P10'};
% Exceptions
conf_02b_pun_late_sessions = {'P11','P12','P13','P14','P15'};
R11_pun_late_sessions = {'P04','P05','P06'};
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
    
    % Check for special cases first
    if strcmp(current_rat, 'R11')
        if ismember(current_session, R11_pun_late_sessions)
            phase_assignment = 'late';
        end
    elseif ismember(current_rat, conf_02b_Rat)
        if ismember(current_session, conf_02b_pun_late_sessions)
            phase_assignment = 'late';
        end
    end
    
    % If no special case was met, apply general rules
    if strcmp(phase_assignment, 'unassigned')
        if ismember(current_session, pun_early_sessions)
            phase_assignment = 'early';
        elseif ismember(current_session, pun_late_sessions)
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
    %% MODIFIED: Added 'Latency' to the list of variables to average
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    
    summary_early = groupsummary(collated_early_table, {'Rat', 'TrialType', 'Response'}, 'mean', vars_to_summarize);
    
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
    %% MODIFIED: Added 'Latency' to the list of variables to average
    vars_to_summarize = {'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    
    summary_late = groupsummary(collated_late_table, {'Rat', 'TrialType', 'Response'}, 'mean', vars_to_summarize);
    
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