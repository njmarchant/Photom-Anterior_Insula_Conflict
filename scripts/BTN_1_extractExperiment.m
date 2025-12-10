%% Main Extraction Script: Conflict 04 (Experiment-Wide Batch)
% Updated to include:
% 1. Pre-processing exclusion (trimming start of session)
% 2. Batch processing using 'Conflict_04_sessions.csv' lookup
% 3. Multiple TDT folders per 's' folder supported (Processing all valid blocks)

clear all
close all

%% --- 1. Configuration & Setup ---
exp = 'Conflict_04'; 
tankfolder = 'C:\Photometry\Conflict_04\Raw data';
csv_filename = 'Conflict_04_sessions.csv'; 
csv_path = fullfile(tankfolder, csv_filename);

% List of rats designated as 'Late'
late_rats = {'R13','R14'};

% Time window for PETH (Pre-event, Post-event)
time = [25, 15]; 

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
session_table.Session_late = string(session_table.Session_late);

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
    csv_ses_late   = session_table.Session_late(row_idx); 

    fprintf('\n-----------------------------------------------\n');
    fprintf('Processing Folder: %s (Mapped to %s / %s)\n', curr_s_folder, csv_ses_normal, csv_ses_late);
    
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
            
            % 4.1 Determine Session ID based on Rat Type
            if ismember(rat_id, late_rats)
                this_ses_id = csv_ses_late;
            else
                this_ses_id = csv_ses_normal;
            end
            
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
            cut_idx = ceil(conversion * exc);
            
            sesdat.raw490 = raw490;
            sesdat.raw405 = raw405;
            
            if length(raw490) > cut_idx
                work490 = raw490(cut_idx:end);
                work405 = raw405(cut_idx:end);
                work_ts = (1:length(work490))'; 
            else
                fprintf('      Recording shorter than exclusion period! Skipping.\n');
                continue;
            end
    
            % Adjust Events (Shift timestamps by 'exc')
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
            
            sesdat.filt490 = work490; 
            sesdat.filt405 = work405; 
            sesdat.lp_dFF = lp_dFF;
            sesdat.conversion = conversion;
            
            %% --- 7. Make Traces (PETH) ---
            % Updated Logic: Track valid indices to match header_info to trace_matrix
            sesdat.traces = []; 
            if valid_ev_count > 0
                for m = 1:size(ev_shifted, 1)
                    timestamps = cell2mat(ev_shifted(m, 2));
                    if isempty(timestamps); continue; end
                    
                    trace_matrix = [];
                    valid_indices = []; % To keep track of which timestamps succeeded
                    
                    for k = 1:length(timestamps)
                        adjts = ceil(conversion * timestamps(k)); 
                        idx_start = adjts - ceil(time(1)*conversion);
                        idx_end = adjts + ceil(time(end)*conversion);
                        
                        % Boundary checks (try/catch equivalent)
                        if idx_start > 0 && idx_end <= length(lp_dFF)
                            signal = lp_dFF(idx_start : idx_end)';
                            trace_matrix(end+1, :) = signal; % Append to matrix
                            valid_indices(end+1) = k;        % Record that this k was valid
                        else
                            % Trace goes out of bounds, skip it
                             fprintf('      Trace skipped (out of bounds) at timestamp: %.2f\n', timestamps(k));
                        end
                    end
                    
                    % Only proceed if we have valid traces
                    if ~isempty(trace_matrix)
                       % Filter timestamps to match the valid traces
                       valid_timestamps = timestamps(valid_indices);
                       
                       % Construct Header: [timestamp, condition_code, 0, 0]
                       header_info = [valid_timestamps, ones(length(valid_timestamps),1)*m, zeros(length(valid_timestamps),2)];
                       
                       % Concatenate
                       ev_shifted{m, 2} = [header_info, trace_matrix];
                    else
                       ev_shifted{m, 2} = [];
                    end
                end
                sesdat.traces = ev_shifted;
            end
            
            %% --- 8. Save Data ---
            sesdat.rat = rat_id;
            sesdat.ses = char(this_ses_id);
            sesdat.date = names{5};
            
            % Define Phase/Type for folder naming
            if strncmpi(this_ses_id, 'R', 1) % If starts with R (Reward)
                type = sprintf('Rew_(%d-%d)', time);
            elseif strncmpi(this_ses_id, 'P', 1) % If starts with P (Punishment)
                 type = sprintf('Pun_(%d-%d)', time);
            else
                 type = sprintf('Conf_(%d-%d)', time);
            end
            sesdat.phase = type;
            
            folderName = fullfile(tankfolder, type);
            if ~isfolder(folderName); mkdir(folderName); end
            
            % REVERTED: Filename is just Exp + Phase + Date + RatID
            fileName = [exp, ' ', type, ' ', names{5}, ' data ', rat_id, '.mat'];
            save(fullfile(folderName, fileName), 'sesdat');
            
            clear sesdat work490 work405 lp_dFF;
            
        end % End Rat Loop
    end % End TDT Folder Loop
end % End Session Loop

fprintf('\nBatch Extraction Complete.\n');