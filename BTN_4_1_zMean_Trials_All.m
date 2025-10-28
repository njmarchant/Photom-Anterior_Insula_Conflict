%% Nathan Marchant July 2024 (Updated by Google's Gemini)
% This script creates a detailed table with specific response outcomes AND a
% summary table that combines all response types into a single category.

close all;
clear all;
close all;

%% ========================================================================
%  USER SETTING: Define the phase of the experiment here
%  Options are: 'reward_only', 'reward_punish', 'conflict'
%  ========================================================================
experimentPhase = 'conflict'; %<-- SET THIS VARIABLE

% Define where the data is located
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-45)';

% Load individual session data
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]);
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) % Iterate through each session file
    load(fullfile(filePath, [files(i).name]));
    
    % Get variables from the loaded file
    data = sesdat.traces_z(:, 5:end);
    times = sesdat.traces_z(:, 1:4);
    r = sesdat.rat;
    sex = sesdat.sex;
    s1 = sesdat.ses;
    h = sesdat.hemi;
 
    % Define time, baseline, and analysis windows
    time = linspace(-10, 45, size(data, 2));
    lims1 = (time >= -5) & (time <= 0);     % Baseline: pre-cues
    lims2 = (time >= 0) & (time <= 5);      % First 5s of cues
    lims3 = (time >= 5) & (time <= 10);     % Second 5s of cues
    lims4 = (time >= 0) & (time <= 10);     % Full 10s cue period
    lims5 = (time >= 10) & (time <= 40);    % 30s lever period
    
    zdata = [times, data];
    
    % --- Unified Trial Processing for Detailed Table ---
    
    trial_indices = ismember(zdata(:,2), [1, 2, 3]);
    all_trials = zdata(trial_indices, :);
    
    if ~isempty(all_trials)
        num_trials = size(all_trials, 1);
        trial_type_col = cell(num_trials, 1);
        trial_type_col(all_trials(:,2) == 1) = {'rewDS'};
        trial_type_col(all_trials(:,2) == 2) = {'punDS'};
        trial_type_col(all_trials(:,2) == 3) = {'conflict'};
        
        % Create the specific response labels for the detailed table
        response_type_col = cell(num_trials, 1);
        response_type_col(all_trials(:,4) == 0) = {'Omission'};
        response_type_col(all_trials(:,4) == 1) = {'Response'};
        response_type_col(all_trials(:,4) == 2) = {'Response-Pellet'};
        response_type_col(all_trials(:,4) == 3) = {'Response-Shock'};

        latency_col = all_trials(:, 3);
        latency_col(all_trials(:,4) == 0) = NaN;
        z_scores_all = all_trials(:, 5:end);
        zmean_BL = mean(z_scores_all(:, lims1), 2);
        zmean_Cue5s = mean(z_scores_all(:, lims2), 2);
        zmean_Cue10s = mean(z_scores_all(:, lims3), 2);
        zmean_CueFull = mean(z_scores_all(:, lims4), 2);
        zmean_Lever = mean(z_scores_all(:, lims5), 2);
        results_table = table(...
            all_trials(:, 1), trial_type_col, response_type_col, latency_col, ...
            zmean_BL, zmean_Cue5s, zmean_Cue10s, zmean_CueFull, zmean_Lever, ...
            'VariableNames', {'Timestamp', 'TrialType', 'Response', 'Latency', ...
            'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'});
        sorted_table = sortrows(results_table, 'Timestamp');
        sequential_trial_numbers = (1:height(sorted_table))';
        sorted_table = addvars(sorted_table, sequential_trial_numbers, 'Before', 'Timestamp', 'NewVariableNames', 'Trial');
        sorted_table.Rat = repmat({r}, num_trials, 1);
        sorted_table.Sex = repmat({sex}, num_trials, 1);
        sorted_table.Hemi = repmat({h}, num_trials, 1);
        sorted_table.Session = repmat({s1}, num_trials, 1);
        sorted_table = sorted_table(:, {'Rat', 'Sex', 'Hemi', 'Session', 'Trial', 'Timestamp', 'TrialType', 'Response', 'Latency', 'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'});
    else
        sorted_table = table();
    end
    
    %% MODIFIED: Reverted summary pre-allocation to the 6-row 'conflict' version
    
    % 1. Define the structure of the summary table based on experimentPhase
    vars_to_summarize = {'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever'};
    switch experimentPhase
        case 'reward_only'
            trialTypes = {'rewDS'; 'rewDS'};
            responses = {'Response'; 'Omission'};
        case 'reward_punish'
            trialTypes = repelem({'rewDS'; 'punDS'}, 2, 1);
            responses = repmat({'Response'; 'Omission'}, 2, 1);
        case 'conflict'
            trialTypes = repelem({'rewDS'; 'punDS'; 'conflict'}, 2, 1);
            responses = repmat({'Response'; 'Omission'}, 3, 1);
        otherwise
            error('Invalid experimentPhase specified. Use ''reward_only'', ''reward_punish'', or ''conflict''.');
    end
    
    % 2. Create the empty template table with NaN values
    label_table = table(trialTypes, responses, 'VariableNames', {'TrialType', 'Response'});
    num_rows = height(label_table);
    numeric_data = [zeros(num_rows, 1), nan(num_rows, length(vars_to_summarize))];
    numeric_table = array2table(numeric_data, 'VariableNames', [{'GroupCount'}, vars_to_summarize]);
    summary_template = [label_table, numeric_table];

    % 3. Calculate the actual summary from the existing data
    if ~isempty(sorted_table)
        %% MODIFIED: Temporarily group all response types for summary calculation
        % Create a temporary, simplified response column for grouping
        summary_grouping_table = sorted_table;
        is_any_response = ismember(summary_grouping_table.Response, {'Response', 'Response-Pellet', 'Response-Shock'});
        summary_grouping_table.Response(is_any_response) = {'Response'};
        
        actual_summary = groupsummary(summary_grouping_table, {'TrialType', 'Response'}, 'mean', vars_to_summarize);
        
        % 4. Fill the template with the actual data where it exists
        for k = 1:height(summary_template)
            current_trial_type = summary_template.TrialType{k};
            current_response = summary_template.Response{k};
            
            match_idx = strcmp(actual_summary.TrialType, current_trial_type) & strcmp(actual_summary.Response, current_response);
            
            if any(match_idx)
                summary_template.GroupCount(k) = actual_summary.GroupCount(match_idx);
                for v = 1:length(vars_to_summarize)
                    var_name = vars_to_summarize{v};
                    mean_var_name = ['mean_' var_name];
                    summary_template.(var_name)(k) = actual_summary.(mean_var_name)(match_idx);
                end
            end
        end
    end
    
    zmean_summary_table = summary_template;

    % --- Save Both Tables ---
    if isfield(sesdat, 'zmean')
       sesdat = rmfield(sesdat,'zmean');
    end
    sesdat.zmean_table = sorted_table;
    sesdat.zmean_summary_table = zmean_summary_table;
    
    save(fullfile(filePath, [files(i).name(1:end-4) '.mat']), 'sesdat');
end

disp('Processing complete!');