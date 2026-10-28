%% Nathan Marchant July 2024 (Updated by Google's Gemini for HMM Python format)
% This script creates a detailed table with specific response outcomes AND a
% summary table that combines all response types into a single category.
close all;
clear all;

%% ========================================================================
%  USER SETTING: Define the phase of the experiment here
%  Options are: 'reward_only', 'reward_punish', 'conflict'
%  ========================================================================
experimentPhase = 'conflict'; %<-- SET THIS VARIABLE

% Define where the data is located
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';

% Load individual session data
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath, '*.mat')); % Safety: only look for .mat
files = filesAndFolders(~[filesAndFolders.isdir]);

for i = 1:length(files) % Iterate through each session file
    load(fullfile(filePath, [files(i).name]));
    
    % Get variables from the loaded file for the 10_45 epoch
    data_10_45 = sesdat.traces_z_10_45(:, 5:end);
    times_10_45 = sesdat.traces_z_10_45(:, 1:4);
    
    % --- NEW: Extract data for the 25_15 epoch ---
    if isfield(sesdat, 'traces_z_25_15')
        data_25_15 = sesdat.traces_z_25_15(:, 5:end);
        timestamps_25_15 = sesdat.traces_z_25_15(:, 1); 
    else
        % Fallback empty arrays in case the matrix is missing in a specific file
        data_25_15 = [];
        timestamps_25_15 = [];
    end
    
    % CLEAN RAT NAME STRINGS IMMEDIATELY (Removes extra quotes for Python)
    r = strrep(sesdat.rat, '''', ''); 
    
    s1 = sesdat.ses;
    h = sesdat.hemi;
    
    % Extract Intensity
    if isfield(sesdat, 'intensity')
        intensity_val = sesdat.intensity;
    else
        intensity_val = NaN; % Fallback to prevent crashes if a file is missing it
    end
 
    % Define time and analysis windows for 10_45 data
    time_10_45 = linspace(-10, 45, size(data_10_45, 2));
    lims1 = (time_10_45 >= -5) & (time_10_45 <= 0);     % Baseline: pre-cues
    lims2 = (time_10_45 >= 0) & (time_10_45 <= 5);      % First 5s of cues
    lims3 = (time_10_45 >= 5) & (time_10_45 <= 10);     % Second 5s of cues
    lims4 = (time_10_45 >= 0) & (time_10_45 <= 10);     % Full 10s cue period
    lims5 = (time_10_45 >= 10) & (time_10_45 <= 40);    % 30s lever period
    
    % --- NEW: Define time and analysis windows for 25_15 data ---
    if ~isempty(data_25_15)
        time_25_15 = linspace(-25, 15, size(data_25_15, 2));
        lims_pre_resp = (time_25_15 >= -10) & (time_25_15 <= 0); % Pre-Response
        lims_post_resp = (time_25_15 >= 0) & (time_25_15 <= 5);  % Post-Response
    end
    
    zdata = [times_10_45, data_10_45];
    
    % --- Unified Trial Processing for Detailed Table ---
    trial_indices = ismember(zdata(:,2), [1, 2, 3]);
    all_trials = zdata(trial_indices, :);
    
    if ~isempty(all_trials)
        num_trials = size(all_trials, 1);
        
        % 1. FORMAT CUES FOR PYTHON ('reward', 'punish', 'conflict')
        trial_type_col = cell(num_trials, 1);
        trial_type_col(all_trials(:,2) == 1) = {'reward'};
        trial_type_col(all_trials(:,2) == 2) = {'punish'};
        trial_type_col(all_trials(:,2) == 3) = {'conflict'};
        
        % FORMAT OUTCOME (1 = Response, 0 = Omission)
        outcome_col = double(all_trials(:, 4) > 0);
        
        % 2. FORMAT RESPONSES FOR PYTHON
        response_type_col = cell(num_trials, 1);
        for j = 1:num_trials
            cue_code = all_trials(j, 2);
            outcome_code = all_trials(j, 4);
            
            if outcome_code == 0
                response_type_col{j} = 'Omission';
            elseif outcome_code == 2
                response_type_col{j} = 'Response-Pellet'; 
            elseif outcome_code == 3
                response_type_col{j} = 'Response-Shock';  
            elseif outcome_code == 1
                if cue_code == 1 
                    response_type_col{j} = 'Response-Pellet';
                elseif cue_code == 2 
                    response_type_col{j} = 'Response-Shock';
                else 
                    response_type_col{j} = 'Response'; 
                end
            end
        end
        
        latency_col = all_trials(:, 3);
        latency_col(all_trials(:,4) == 0) = NaN;
        z_scores_all = all_trials(:, 5:end);
        
        zmean_BL = mean(z_scores_all(:, lims1), 2);
        zmean_Cue5s = mean(z_scores_all(:, lims2), 2);
        zmean_Cue10s = mean(z_scores_all(:, lims3), 2);
        zmean_CueFull = mean(z_scores_all(:, lims4), 2);
        zmean_Lever = mean(z_scores_all(:, lims5), 2);
        
        % --- NEW: Extract Response Means from the 25_15 data ---
        zmean_Pre_Response = nan(num_trials, 1);  % Initializes with NaNs (for omissions)
        zmean_Post_Response = nan(num_trials, 1); 
        
        for j = 1:num_trials
            if outcome_col(j) > 0 && ~isempty(data_25_15) % Only process if it is a response
                
                % Expected response time = Trial Start (col 1) + 10s cue + Latency (col 3)
                expected_resp_time = all_trials(j, 1) + 10 + all_trials(j, 3);
                
                % Find the row in 25_15 that matches this expected timestamp 
                % (using a small 0.1s tolerance to account for potential jitter)
                [min_diff, match_idx] = min(abs(timestamps_25_15 - expected_resp_time));
                
                if min_diff < 0.1 
                    matched_trace = data_25_15(match_idx, :);
                    zmean_Pre_Response(j) = mean(matched_trace(lims_pre_resp));
                    zmean_Post_Response(j) = mean(matched_trace(lims_post_resp));
                end
            end
        end
        
        % Add the new columns to the base table
        results_table = table(...
            all_trials(:, 1), trial_type_col, outcome_col, response_type_col, latency_col, ...
            zmean_BL, zmean_Cue5s, zmean_Cue10s, zmean_CueFull, zmean_Lever, ...
            zmean_Pre_Response, zmean_Post_Response, ...
            'VariableNames', {'Timestamp', 'Cue', 'Outcome', 'Response', 'Latency', ...
            'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever', ...
            'ZMean_Pre_Response', 'ZMean_Post_Response'});
        
        sorted_table = sortrows(results_table, 'Timestamp');
        sequential_trial_numbers = (1:height(sorted_table))';
        sorted_table = addvars(sorted_table, sequential_trial_numbers, 'Before', 'Timestamp', 'NewVariableNames', 'Trial');
        
        % Populate the repeated session metadata
        sorted_table.Rat = repmat({r}, num_trials, 1);
        sorted_table.Session = repmat({s1}, num_trials, 1);
        sorted_table.Intensity = repmat(intensity_val, num_trials, 1); 
        
        % Reorder columns
        sorted_table = sorted_table(:, {'Rat', 'Session', 'Intensity', 'Trial', 'Timestamp', ...
            'Cue', 'Outcome', 'Response', 'Latency', 'ZMean_BL', 'ZMean_Cue5s', ...
            'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever', 'ZMean_Pre_Response', 'ZMean_Post_Response'});
    else
        sorted_table = table();
    end
    
    %% SUMMARY TABLE GENERATION
    
    % 1. Define the structure of the summary table based on experimentPhase
    % --- NEW: Added the pre/post response means to the summary compilation ---
    vars_to_summarize = {'ZMean_BL', 'ZMean_Cue5s', 'ZMean_Cue10s', 'ZMean_CueFull', 'ZMean_Lever', 'ZMean_Pre_Response', 'ZMean_Post_Response'};
    
    switch experimentPhase
        case 'reward_only'
            trialTypes = {'reward'; 'reward'};
            responses = {'Response'; 'Omission'};
        case 'reward_punish'
            trialTypes = repelem({'reward'; 'punish'}, 2, 1);
            responses = repmat({'Response'; 'Omission'}, 2, 1);
        case 'conflict'
            trialTypes = repelem({'reward'; 'punish'; 'conflict'}, 2, 1);
            responses = repmat({'Response'; 'Omission'}, 3, 1);
        otherwise
            error('Invalid experimentPhase specified.');
    end
    
    % 2. Create the empty template table with NaN values
    label_table = table(trialTypes, responses, 'VariableNames', {'Cue', 'Response'});
    num_rows = height(label_table);
    numeric_data = [zeros(num_rows, 1), nan(num_rows, length(vars_to_summarize))];
    numeric_table = array2table(numeric_data, 'VariableNames', [{'GroupCount'}, vars_to_summarize]);
    summary_template = [label_table, numeric_table];
    
    % 3. Calculate the actual summary from the existing data
    if ~isempty(sorted_table)
        % Temporarily group all response types for summary calculation
        summary_grouping_table = sorted_table;
        is_any_response = ismember(summary_grouping_table.Response, {'Response', 'Response-Pellet', 'Response-Shock'});
        summary_grouping_table.Response(is_any_response) = {'Response'};
        
        % Use 'omitnan' explicitly to ensure omissions don't drag down response averages
        actual_summary = groupsummary(summary_grouping_table, {'Cue', 'Response'}, 'mean', vars_to_summarize);
        
        % 4. Fill the template with the actual data where it exists
        for k = 1:height(summary_template)
            current_cue = summary_template.Cue{k};
            current_response = summary_template.Response{k};
            
            match_idx = strcmp(actual_summary.Cue, current_cue) & strcmp(actual_summary.Response, current_response);
            
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
    
    save(fullfile(filePath, files(i).name), 'sesdat');
end
disp('Extraction and Python formatting complete!');