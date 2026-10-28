%% Standalone Manual Artifact Exclusion Script
% Run this script AFTER extracting data but BEFORE z-scoring.
% It will overwrite the trace data (columns 5:end) with NaNs for 
% specific time windows in specific files, leaving trial markers intact.

clear all
close all

%% 1. Define folder path
% Point this to the folder containing your extracted .mat files
tankfolder = 'C:\Photometry\Conflict_06\Rew'; 

%% 2. Define Manual Artifact Exclusion List
% Format: {'Filename.mat', [start_time_in_seconds, end_time_in_seconds]}
% You can add as many rows as you need. You can even list the same file 
% multiple times if there are multiple bad windows in a single session.
exclude_list = {
    'Conflict_06 R05 260827 data R02.mat', [190, 240]; 
    'Conflict_06 R05 260827 data R02.mat', [720, 800]; 
    'Conflict_06 R05 260827 data R02.mat', [1650, 1800];
    'Conflict_06 R05 260827 data R04.mat', [1920, 2000]; 
    'Conflict_06 R05 260827 data R04.mat', [2260, 2440]; 
    'Conflict_06 R05 260827 data R08.mat', [510, 580];
    'Conflict_06 R02 260824 data R01.mat', [2730, inf]; 
};

%% 3. Process Files
fprintf('Starting manual artifact exclusion...\n');
fprintf('--------------------------------------\n');

for ex_idx = 1:size(exclude_list, 1)
    target_file = exclude_list{ex_idx, 1};
    bad_window = exclude_list{ex_idx, 2};
    file_path = fullfile(tankfolder, target_file);
    
    if isfile(file_path)
        fprintf('Checking %s...\n', target_file);
        
        % Load the data (loads the 'sesdat' struct)
        load(file_path); 
        file_modified = false;
        
        % Find all fields in sesdat that contain traces
        all_fields = fieldnames(sesdat);
        trace_fields = all_fields(startsWith(all_fields, 'traces_'));
        
        for t_idx = 1:length(trace_fields)
            current_field = trace_fields{t_idx};
            current_traces = sesdat.(current_field); % This is the cell array
            
            % Loop through the rows (event types) in the cell array
            for ev_idx = 1:size(current_traces, 1)
                event_name = current_traces{ev_idx, 1};
                event_data = current_traces{ev_idx, 2}; % Extract numeric matrix
                
                if ~isempty(event_data)
                    % Column 1 is the timestamp. Check if it falls in the bad window.
                    bad_trials = event_data(:, 1) >= bad_window(1) & event_data(:, 1) <= bad_window(2);
                    
                    if any(bad_trials)
                        % Overwrite trace data (Column 5 to end) with NaN
                        event_data(bad_trials, 5:end) = NaN;
                        
                        % Update the numeric matrix back into the cell array
                        current_traces{ev_idx, 2} = event_data;
                        file_modified = true;
                        
                        fprintf('  -> Field "%s" (%s): Excluded %d trials between %g and %g.\n', ...
                                current_field, event_name, sum(bad_trials), bad_window(1), bad_window(2));
                    end
                end
            end
            
            % Update the struct with the fully modified cell array
            sesdat.(current_field) = current_traces;
        end
        
        % Save the file only if modifications were actually made
        if file_modified
            save(file_path, 'sesdat');
            fprintf('  -> Saved updated %s to disk.\n', target_file);
        else
            fprintf('  -> No trials found in the specified window. No changes made.\n');
        end
        fprintf('--------------------------------------\n');
        
    else
        fprintf('WARNING: File %s not found in folder. Skipping...\n', target_file);
        fprintf('--------------------------------------\n');
    end
end

fprintf('Artifact exclusion complete!\n');