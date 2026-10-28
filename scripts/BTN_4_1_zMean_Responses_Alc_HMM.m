%% Nathan Marchant July 2024 (Updated for clean CSV handling)
% Written for the conflict task
% This script calculates the zMean for a given period (-25 to +15s traces) 
% and cross-references it with an external CSV dataframe using a 
% Trial-to-Outcome timestamp hop.

close all;
clear;

%% ========================================================================
%  FILE PATHS
%  ========================================================================
savefolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)\combined_v2';
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(25-15)';
excel_path = fullfile(savefolder, 'collated_ALC_TESTS_data_cleaned.csv'); 

% --- Load the CSV Dataframe ---
fprintf('Loading CSV dataframe...\n');
% 'TextType', 'string' is crucial here! It forces MATLAB to read text as 
% modern string arrays, completely preventing "cell array" matching errors.
df = readtable(excel_path, 'TextType', 'string');

% --- DIAGNOSTIC CHECK ---
fprintf('\n--- CSV PREVIEW ---\n');
fprintf('First 5 unique Rats in CSV:\n');
disp(head(unique(df.Rat), 5));
fprintf('First 5 unique Sessions in CSV:\n');
disp(head(unique(df.Session_ID), 5));
fprintf('---------------------\n\n');

% Force initialize (or reset) the columns full of NaNs to hold our new neural data.
% Using NaN ensures that empty rows stay genuinely empty/missing, not 0.
df.mean_postResponse_0_5 = NaN(height(df), 1);
df.mean_preResponse_10_0 = NaN(height(df), 1);

%% ========================================================================
%  LOAD INDIVIDUAL SESSION DATA
%  ========================================================================
filesAndFolders = dir(fullfile(tankfolder, '*.mat')); % Safety: only .mat
files = filesAndFolders(~[filesAndFolders.isdir]); 

for i = 1:length(files)
    fprintf('\nProcessing %s...\n', files(i).name);
    load(fullfile(tankfolder, files(i).name));
   
    % Handle potential naming differences in the trace variable
    if isfield(sesdat, 'traces_updated')
        traces_matrix = sesdat.traces_updated;
    elseif isfield(sesdat, 'traces')
        traces_matrix = sesdat.traces;
    else
        fprintf('  [!] ERROR: Could not find traces or traces_updated in %s\n', files(i).name);
        continue;
    end
    
    % Get variables
    data = traces_matrix(:, 5:end);
    times = traces_matrix(:, 1:4);
    
    % Clean Rat and Session directly from the .mat file just in case
    r = strrep(string(sesdat.rat), '''', ''); 
    s1 = strtrim(string(sesdat.ses));
       
    % Define time, baseline etc for the -25 to +15 trace
    time = linspace(-25, 15, size(data, 2)); % time vector the size of trace
    base = (time >= -25) & (time <= -20);    % baseline window
    lims1 = (time >= 0) & (time <= 5);       % 5s post-response window
    lims2 = (time >= -10) & (time <= 0);     % 10s pre-response window
     
    %% Z-score standardisation on df/f
    zdata = zeros(size(data));
    for m = 1:size(data, 1)
        zb = mean(data(m, base));
        zsd = std(data(m, base));
        zdata(m, :) = (data(m, :) - zb) / zsd; % Vectorized for speed!
    end
    
    % Recombine times with z-scored data
    zdata_full = [times, zdata];  
    
    %% --- THE TWO-STEP CSV MERGE LOGIC ---
    
    % Because we loaded the CSV with 'TextType', 'string', matching is now incredibly simple:
    rat_match = strcmpi(df.Rat, r);
    ses_match = strcmpi(df.Session_Type, s1);
    
    valid_rows_for_session = rat_match & ses_match;
    
    % DIAGNOSTIC: Did we find the rat and session in the CSV?
    if sum(valid_rows_for_session) == 0
        fprintf('  [!] WARNING: Could not find rows in CSV for Rat "%s" and Session "%s".\n', r, s1);
        continue; % Skip to next file if no match
    end
    
    % Separate the array into Trials (Cue onset) and Outcomes (Responses)
    trial_rows = find(ismember(zdata_full(:, 2), [1, 2, 3]) & zdata_full(:, 4) > 0);
    outcome_data = zdata_full(ismember(zdata_full(:, 2), [5, 6]), :); 
    
    matches_found = 0;
    
    for j = 1:length(trial_rows)
        row_idx = trial_rows(j);
        trial_ts = zdata_full(row_idx, 1);     
        latency = zdata_full(row_idx, 3);      
        
        % Calculate exactly when the response should have occurred 
        % (Cue onset + 10s cue duration + latency to press)
        expected_outcome_ts = trial_ts + 10 + latency;
        ts_diffs = abs(outcome_data(:, 1) - expected_outcome_ts);
        
        if isempty(ts_diffs)
            continue; 
        end
        
        [min_diff, closest_idx] = min(ts_diffs);
        
        % If we found the corresponding response event in the trace matrix
        if min_diff < 0.1
            outcome_trace = outcome_data(closest_idx, 5:end);
            trace_mean_0_5 = mean(outcome_trace(lims1));
            trace_mean_10_0 = mean(outcome_trace(lims2));
            
            % Match the original TRIAL timestamp back to the CSV
            excel_ts_match = abs(df.Timestamp - trial_ts) < 0.05; 
            target_row = find(valid_rows_for_session & excel_ts_match);
            
            if ~isempty(target_row)
                df.mean_postResponse_0_5(target_row) = trace_mean_0_5;
                df.mean_preResponse_10_0(target_row) = trace_mean_10_0; 
                matches_found = matches_found + 1;
            end
        end
    end
    
    fprintf('Successfully matched and inserted %d outcome traces for %s.\n', matches_found, files(i).name);
end

%% ========================================================================
%  SAVE THE UPDATED DATAFRAME
%  ========================================================================
output_csv_name = 'Conflict_02_Alc_tests_UPDATED_v2.csv'; % Changed to CSV
writetable(df, fullfile(savefolder, output_csv_name));

fprintf('\n----------------------------------------------------\n');
fprintf('Finished cross-referencing! Updated file saved as:\n %s\n', fullfile(savefolder, output_csv_name));
fprintf('----------------------------------------------------\n');