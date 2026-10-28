%% Main Extraction Script: Conflict 04 (Experiment-Wide Batch)
% Updated to include:
% 1. Pre-processing exclusion (trimming start of session)
% 2. Batch processing using 'Conflict_04_sessions.csv' lookup
% 3. Multiple TDT folders per 's' folder supported 
% 4. Multiple dynamic time windows for PETH extraction

clear all
close all
fclose('all');

%% --- 1. Configuration & Setup ---
exp = 'Conflict_06'; 
tankfolder = 'C:\Photometry\Conflict_06\Raw data';
csv_filename = 'Conflict_06_sessions.csv'; 
csv_path = fullfile(tankfolder, csv_filename);

% --- TIME VARIABLES ---
% Enter as many different time windows here as you need. 
time1 = [10, 45]; 
time2 = [25, 15]; 
time_windows = {time1, time2}; % Groups them together to loop through

% Pre-processing Parameters
res = 64;           % Resampling factor
lowpass_cutoff = 3; % Hz
filt_steepness = 0.95; 
db_atten = 90; 
exc = 100;          % Seconds to exclude from the START of the recording

%% --- 2. Load Session Reference Table ---
opts = detectImportOptions(csv_path);
opts.VariableNamingRule = 'preserve';
session_table = readtable(csv_path, opts);
session_table.Rec_ses = string(session_table.Rec_ses);
session_table.Session = string(session_table.Session);
fprintf('Loaded Session Reference Table (%d rows).\n', height(session_table));

%% --- 3. Iterate Through Experiment Folders (s1, s2, ...) ---
s_folders = dir(fullfile(tankfolder)); 
s_folders(~[s_folders.isdir]) = []; 

for i = 1:length(s_folders)
    curr_s_folder = s_folders(i).name; % e.g., 's16'
    
    % Find corresponding info in CSV
    row_idx = find(session_table.Rec_ses == curr_s_folder);
    
    if isempty(row_idx)
        fprintf('Warning: Folder %s not found in CSV. Skipping.\n', curr_s_folder);
        continue;
    end
    
    % Get the generic session IDs from CSV
    csv_ses_normal = session_table.Session(row_idx);      
    fprintf('\n-----------------------------------------------\n');
    fprintf('Processing Folder: %s (Mapped to %s)\n', curr_s_folder, csv_ses_normal);
    
    % Find TDT subfolders inside 'sX'
    tdt_path = fullfile(tankfolder, curr_s_folder);
    subfiles = dir(tdt_path);
    subfiles(ismember({subfiles.name}, {'.', '..'})) = [];
    subfiles = subfiles([subfiles.isdir]); % Keep only folders (TDT tanks)
    
    %% --- Loop through ALL TDT Data Blocks found in this folder ---
    for t = 1:length(subfiles)
        
        target_folder = subfiles(t).name;
        full_tdt_path = fullfile(tdt_path, target_folder);
        
        fprintf('  -> Processing Block %d/%d: %s\n', t, length(subfiles), target_folder);
        
        % Extract Data
        try
            [data, events, ts, conversion] = Sim_TDTextract(full_tdt_path);
        catch ME
            fprintf('     Error extracting TDT data: %s\n', ME.message);
            continue;
        end
        
        % Parse Folder Name: R01_R02_R05_R06-251117-140614
        names = strsplit(target_folder, {'-' , '_'}); 
        % names{1-4}=Rats, names{5}=Date
        
        %% --- 4. Process Each Rat (Boxes 1-4) ---
        for l = 1:4 
            rat_id = names{l};
            
            % 4.1 Assign Session ID 
            this_ses_id = csv_ses_normal;
            
            if ismissing(this_ses_id) || strcmpi(this_ses_id, 'null')
                continue; 
            end
            
            % 4.2 Extract Channels (Box Logic)
            try
                if l == 1 
                    raw490 = cell2mat(data(contains(data(:,1), 'B1GB'), 2)); 
                    raw405 = cell2mat(data(contains(data(:,1), 'B1CB'), 2));
                    side = 'B1'; 
                elseif l == 2 
                    raw490 = cell2mat(data(contains(data(:,1), 'B2GB'), 2));
                    raw405 = cell2mat(data(contains(data(:,1), 'B2CB'), 2));
                    side = 'B2';
                elseif l == 3 
                    raw490 = cell2mat(data(contains(data(:,1), 'BGB2'), 2));
                    raw405 = cell2mat(data(contains(data(:,1), 'BCB2'), 2));
                    side = 'B3';
                elseif l == 4 
                    raw490 = cell2mat(data(contains(data(:,1), 'B7B2'), 2));
                    raw405 = cell2mat(data(contains(data(:,1), 'B1B2'), 2));
                    side = 'B4';
                end
                ev = events(startsWith(events(:,1), side), :);
            catch
                 % Quietly skip empty boxes
                 continue;
            end
            
            % Check Size Mismatch
            len490 = length(raw490);
            len405 = length(raw405);
            if len490 ~= len405
                min_len = min(len490, len405);
                raw490 = raw490(1:min_len);
                raw405 = raw405(1:min_len);
            end
            
            %% --- 5. PREPROCESSING (Exclusion Logic) ---
            % 1. Calculate Index to cut
            cut_idx = ceil(conversion * exc);
            
            sesdat.raw490 = raw490; 
            sesdat.raw405 = raw405;
            
            if length(raw490) > cut_idx
                % A. Cut the Signal
                work490 = raw490(cut_idx:end);
                work405 = raw405(cut_idx:end);
                
                % B. Cut the Time Vector (ts)
                if length(ts) >= length(raw490)
                     work_ts = ts(cut_idx:cut_idx+length(work490)-1);
                else
                     work_ts = ts(cut_idx:end); 
                end
            else
                fprintf('      Recording shorter than exclusion period! Skipping.\n');
                continue;
            end
    
            % C. Adjust Events (Shift timestamps by 'exc')
            ev_shifted = ev; 
            valid_ev_count = 0;
            if ~isempty(ev)
                for m = 1:size(ev, 1)
                    original_ts_list = cell2mat(ev(m, 2));
                    shifted_ts = original_ts_list - exc;
                    shifted_ts = shifted_ts(shifted_ts > 0);
                    ev_shifted{m, 2} = shifted_ts;
                    valid_ev_count = valid_ev_count + length(shifted_ts);
                end
            end
            
            %% --- 6. Signal Processing (dFF) ---
            cfFinal = controlfit(work490, work405);
            normDat = deltaFF(work490, cfFinal);
            [hp_normDat, ~] = hpFilter(work_ts, normDat);
            lp_dFF = lpFilter(hp_normDat, conversion, lowpass_cutoff, filt_steepness, db_atten);
            lp_dFF_nohp = lpFilter(normDat, conversion, lowpass_cutoff, filt_steepness, db_atten);

            sesdat.filt490 = work490; 
            sesdat.filt405 = work405; 
            sesdat.lp_dFF = lp_dFF;
            sesdat.lp_dFF_nohp = lp_dFF_nohp;
            sesdat.conversion = conversion;
            
            %% --- 7. Make Traces (PETH) - MULTIPLE TIME WINDOWS ---
            if valid_ev_count > 0
                
                % Loop through defined time windows
                for t_idx = 1:length(time_windows)
                    current_time = time_windows{t_idx};
                    current_ev = ev_shifted; % Fresh copy of shifted events for this window
                    
                    for m = 1:size(current_ev, 1)
                        timestamps = cell2mat(current_ev(m, 2));
                        if isempty(timestamps); continue; end
                        
                        trace_matrix = []; valid_indices = [];
                        for k = 1:length(timestamps)
                            adjts = ceil(conversion * timestamps(k)); 
                            
                            idx_start = adjts - ceil(current_time(1)*conversion);
                            idx_end = adjts + ceil(current_time(2)*conversion);
                            
                            if idx_start > 0 && idx_end <= length(lp_dFF)
                                signal = lp_dFF(idx_start : idx_end)';
                                trace_matrix(end+1, :) = signal;
                                valid_indices(end+1) = k;
                            end
                        end
                        
                        if ~isempty(trace_matrix)
                           valid_timestamps = timestamps(valid_indices);
                           header_info = [valid_timestamps, ones(length(valid_timestamps),1)*m, zeros(length(valid_timestamps),2)];
                           current_ev{m, 2} = [header_info, trace_matrix];
                        else
                           current_ev{m, 2} = [];
                        end
                    end
                    
                    % Create dynamic field name (e.g., 'traces_10_45')
                    trace_field_name = sprintf('traces_%d_%d', current_time(1), current_time(2));
                    sesdat.(trace_field_name) = current_ev; 
                    
                end % End of time windows loop
            end
            
            %% --- 8. Save Data ---
            sesdat.rat = rat_id;
            sesdat.ses = char(this_ses_id);
            sesdat.date = names{5};
            
            % Define Phase/Type for simplified folder naming
            if strncmpi(this_ses_id, 'R', 1) 
                type = 'Rew';
            elseif strncmpi(this_ses_id, 'P', 1) 
                 type = 'Pun';
            elseif strncmpi(this_ses_id, 'C', 1) 
                 type = 'Conf';
            else
                 type = 'Test';
            end
            sesdat.phase = type;
            
            folderName = fullfile(tankfolder, type);
            if ~isfolder(folderName); mkdir(folderName); end
            
            % Simplified Filename: Exp + Session + Date + RatID
            fileName = sprintf('%s Session %s %s Rat %s.mat', exp, this_ses_id, names{5}, rat_id);
            save(fullfile(folderName, fileName), 'sesdat');
            
            %  Cleanup
            clear sesdat work490 work405 lp_dFF raw490 raw405 cfFinal normDat hp_normDat trace_matrix ev_shifted current_ev;
        end % End Rat Loop
        
        % --- MEMORY & FILE HANDLE CLEANUP ---
        clear data events ts conversion
        fclose('all'); 
        close all force; 
    end % End TDT Folder Loop
end % End Session Loop

fprintf('\nBatch Extraction Complete.\n');