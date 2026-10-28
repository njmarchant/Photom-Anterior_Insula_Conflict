%% Nathan Marchant July 2024
% Written for the conflict task
% This script calculates the zMean for a given period and cross-references 
% it with an external Excel dataframe using a Trial-to-Outcome timestamp hop.
close all
clear all

%% define where the stuff is
savefolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc';
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(25-15)';
excel_path = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Conflict_02_Alc_tests.xlsx'; % UPDATE THIS PATH IF NEEDED

% --- Load the Excel Dataframe ---
fprintf('Loading Excel dataframe...\n');
df = readtable(excel_path);

% --- DIAGNOSTIC CHECK: What does MATLAB see in Excel? ---
fprintf('\n--- EXCEL PREVIEW ---\n');
if isnumeric(df.Rat)
    fprintf('[!] WARNING: MATLAB loaded df.Rat as NUMBERS!\n');
else
    fprintf('First 5 unique Rats in Excel:\n');
    disp(head(unique(string(df.Rat)), 5));
end

if isnumeric(df.Session)
    fprintf('[!] WARNING: MATLAB loaded df.Session as NUMBERS!\n');
else
    fprintf('First 5 unique Sessions in Excel:\n');
    disp(head(unique(string(df.Session)), 5));
end
fprintf('---------------------\n\n');

% Initialize a new column full of NaNs to hold our new neural data
if ~ismember('mean_postResponse_0_5', df.Properties.VariableNames)
    df.mean_postResponse_0_5 = NaN(height(df), 1);
end
% Initialize a new column full of NaNs to hold our new neural data
if ~ismember('mean_preResponse_10_0', df.Properties.VariableNames)
    df.mean_preResponse_10_0 = NaN(height(df), 1);
end

%% load individual session data
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files) %iterate through experiment folder
    fprintf('\nProcessing %s...\n', files(i).name);
    load(fullfile(filePath,  [files(i).name]))
   
% get variables
    data = sesdat.traces_updated(:, 5:end);
    times = sesdat.traces_updated(:, 1:4);
    r = sesdat.rat;
    s1 = sesdat.ses;
       
% define time, baseline etc
    time = linspace(-25, 15, size(data, 2)); %time vector the size of trace
    base = (time >= -25) & (time <= -20); % baseline
    lims1 = (time >= 0) & (time <= 5);  % 5s post-response window
    lims2 = (time >= -10) & (time <= 0);  % 10s pre-response window
     
%% zscore standardisation on df/f
    zdata = zeros(size(data));
    zbase = zeros(size(data));
    tmp = 0;
        for m = 1:size(data, 1)
            zb = mean(data(m, base));
            zsd = std(data(m,base));
            for j = 1:size(data,2)
                tmp = tmp+1;
                zbase(m, tmp) = (data(m,j) -zb);
                zdata(m,tmp) = (data(m,j) - zb)/zsd;
            end
            tmp = 0;
        end
    
    % Recombine times with z-scored data
    zdata_full = [times, zdata];  
    
    %% --- THE TWO-STEP EXCEL MERGE LOGIC (NUMERIC RAT FIX) ---
    
    % 1. Extract the numeric value from the Rat string (e.g., 'R24' -> 24)
    % regexprep(r, '\D', '') removes all non-digit characters
    rat_num = str2double(regexprep(r, '\D', '')); 
    
    % 2. Clean up the Session string (MATLAB loaded this one correctly as text)
    ses_str = strtrim(char(s1));
    
    % 3. Match Rat (Numbers) and Session (Text)
    rat_match = (df.Rat == rat_num);
    ses_match = strcmpi(strtrim(string(df.Session)), ses_str);
    valid_rows_for_session = rat_match & ses_match;
    
    % DIAGNOSTIC: Did we find the rat and session in Excel?
    if sum(valid_rows_for_session) == 0
        fprintf('  [!] WARNING: Could not find rows in Excel for Rat %d and Session "%s".\n', rat_num, ses_str);
    end
    
    % Separate the array into Trials and Outcomes
    trial_rows = find(ismember(zdata_full(:, 2), [1, 2, 3]) & zdata_full(:, 4) > 0);
    outcome_data = zdata_full(ismember(zdata_full(:, 2), [5, 6]), :); 
    
    matches_found = 0;
    
    for j = 1:length(trial_rows)
        row_idx = trial_rows(j);
        trial_ts = zdata_full(row_idx, 1);     
        latency = zdata_full(row_idx, 3);      
        
        expected_outcome_ts = trial_ts + 10 + latency;
        ts_diffs = abs(outcome_data(:, 1) - expected_outcome_ts);
        
        if isempty(ts_diffs)
            continue; 
        end
        
        [min_diff, closest_idx] = min(ts_diffs);
        
        if min_diff < 0.1
            outcome_trace = outcome_data(closest_idx, 5:end);
            trace_mean_0_5 = mean(outcome_trace(lims1));
            trace_mean_10_0 = mean(outcome_trace(lims2));
            
            % STEP 3: Match the original TRIAL timestamp
            excel_ts_match = abs(df.Timestamp - trial_ts) < 0.05; 
            target_row = find(valid_rows_for_session & excel_ts_match);
            
            if ~isempty(target_row)
                df.mean_postResponse_0_5(target_row) = trace_mean_0_5;
                df.mean_postResponse_10_0(target_row) = trace_mean_10_0;
                matches_found = matches_found + 1;
            end
        end
    end
    
    fprintf('Successfully matched and inserted %d outcome traces for %s.\n', matches_found, files(i).name);
end

%% Save the updated dataframe
output_excel_name = 'Master_Dataframe_with_Probabilities_UPDATED_v2.xlsx';
writetable(df, fullfile(savefolder, output_excel_name));

fprintf('\nFinished cross-referencing! Updated file saved as %s\n', output_excel_name);