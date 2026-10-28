%% Main Extraction Script: Conflict 02 (Experiment-Wide Batch)
% 1. Batch processing across two cohort folders (02b and 02c)
% 2. Dynamic lookup of Session and Intensity via Master Labjournals
% 3. TIMING ONLY TOGGLE: Ultra-fast skipping
% 4. SEQUENTIAL LOOP: Restored to 'for' loop to prevent HDD Disk Thrashing!
% 5. OUTPUT FORMATTING: Updated naming convention per user request.

clear all
close all
fclose('all');

%% --- 1. Configuration & Setup ---
exp = 'Conflict_02'; 
base_dir = 'D:\Photom backup\Conflict_02 Photom';
% base_dir = 'C:\Photometry\Conflict_02 Photom';
out_dir = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc';

cohort_folders = {'Conflict_02b','Conflict_02c'}; % 

% Master CSV Paths 
sessions_csv_path = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Master_Labjournal_Sessions.csv'; 
intensities_csv_path = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Master_Labjournal_Intensities.csv'; 

% =========================================================================
% EXTRACTION MODE
% Set to 'false' to ONLY extract timestamps and event codes (ULTRA FAST)
extract_photometry_traces = true; 
% =========================================================================

time1 = [10, 55]; 
time_windows = {time1}; 
res = 64;           
lowpass_cutoff = 3; 
filt_steepness = 0.95; 
db_atten = 90; 

%% --- 2. Load & Normalize Master Reference Tables ---
opts_ses = detectImportOptions(sessions_csv_path);
opts_ses.VariableNamingRule = 'preserve';
session_table = readtable(sessions_csv_path, opts_ses);

opts_int = detectImportOptions(intensities_csv_path);
opts_int.VariableNamingRule = 'preserve';
intensity_table = readtable(intensities_csv_path, opts_int);

try 
    dt_ses = datetime(session_table.Date);
    session_table.Date = string(datestr(dt_ses, 'yyyy-mm-dd'));
catch; session_table.Date = string(session_table.Date); end
try 
    dt_int = datetime(intensity_table.Date);
    intensity_table.Date = string(datestr(dt_int, 'yyyy-mm-dd'));
catch; intensity_table.Date = string(intensity_table.Date); end

fprintf('Loaded Session Table (%d rows).\n', height(session_table));

output_folder = fullfile(out_dir, 'Extracted_Data_2026');
if ~isfolder(output_folder); mkdir(output_folder); end

%% --- 3. Iterate Through Cohorts (02b and 02c) ---
for c = 1:length(cohort_folders)
    tankfolder = fullfile(base_dir, cohort_folders{c});
    if ~isfolder(tankfolder); continue; end
    
    date_folders = dir(tankfolder);
    date_folders(~[date_folders.isdir] | startsWith({date_folders.name}, '.')) = []; 
    
    for i = 1:length(date_folders)
        curr_folder_name = date_folders(i).name; 
        
        folder_date = regexp(curr_folder_name, '\d{4}-\d{2}-\d{2}', 'match', 'once');
        if isempty(folder_date); continue; end
        
        out_date_yyyymmdd = strrep(folder_date, '-', '');
        hemi_match = regexp(curr_folder_name, '\(([a-zA-Z0-9]+)\)', 'tokens', 'once');
        if ~isempty(hemi_match); hemi = hemi_match{1}; else; hemi = 'Unknown'; end
        
        row_idx_ses = find(session_table.Date == string(folder_date));
        if isempty(row_idx_ses); continue; end
        
        has_conflict_session = false;
        for r_idx = 9:24
            col_name = sprintf('R%02d', r_idx);
            if ismember(col_name, session_table.Properties.VariableNames)
                val = session_table{row_idx_ses, col_name};
                if iscell(val); val = val{1}; end
                val_str = char(string(val));
                if ~isempty(val_str) && length(val_str) >= 1 && strcmpi(val_str(1), 'C')
                    has_conflict_session = true;
                    break; 
                end
            end
        end
        if ~has_conflict_session; continue; end
        
        fprintf('\n-----------------------------------------------\n');
        fprintf('Processing Cohort: %s | Date: %s | Hemi: %s\n', cohort_folders{c}, folder_date, hemi);
        
        tdt_path = fullfile(tankfolder, curr_folder_name);
        subfiles = dir(tdt_path);
        subfiles(ismember({subfiles.name}, {'.', '..'})) = [];
        subfiles = subfiles([subfiles.isdir]); 
        
        for t = 1:length(subfiles)
            target_folder = subfiles(t).name;
            full_tdt_path = fullfile(tdt_path, target_folder);
            fprintf('  -> Block %d/%d: %s\n', t, length(subfiles), target_folder);
            
            try
                [data, events, ts, conversion] = Sim_TDTextract(full_tdt_path);
            catch ME
                fprintf('     Error extracting TDT data: %s\n', ME.message);
                continue;
            end
            
            names = strsplit(target_folder, {'-' , '_'}); 
            
            for l = 1:4 
                sesdat = struct(); 
                
                rat_num = str2double(regexprep(names{l}, '\D', '')); 
                if isnan(rat_num); continue; end
                rat_col_name = sprintf('R%02d', rat_num);
                
                this_ses_id = session_table{row_idx_ses, rat_col_name};
                if iscell(this_ses_id); this_ses_id = this_ses_id{1}; end
                if isempty(this_ses_id) || ismissing(string(this_ses_id)) || strcmp(string(this_ses_id), '-'); continue; end
                this_ses_id = char(string(this_ses_id));
                if ~strncmpi(this_ses_id, 'C', 1); continue; end
                
                row_idx_int = find(intensity_table.Date == string(folder_date));
                if ~isempty(row_idx_int)
                    this_intensity = intensity_table{row_idx_int, rat_col_name};
                    if iscell(this_intensity); this_intensity = this_intensity{1}; end
                else
                    this_intensity = NaN;
                end
                
                side = '';
                if l == 1; side = 'B1'; 
                elseif l == 2; side = 'B2';
                elseif l == 3; side = 'B3';
                elseif l == 4; side = 'B4';
                end
                
                try
                    ev = events(startsWith(events(:,1), side), :);
                catch
                     continue; 
                end
                
                if isempty(ev)
                    fprintf('      No events found for Rat %02d.\n', rat_num);
                    continue;
                end
                
                if ~extract_photometry_traces
                    timing_data = [];
                    for m = 1:size(ev, 1)
                        timestamps = cell2mat(ev(m, 2));
                        if ~isempty(timestamps)
                            event_codes = ones(length(timestamps), 1) * m;
                            timing_data = [timing_data; timestamps, event_codes];
                        end
                    end
                    
                    if ~isempty(timing_data)
                        timing_data = sortrows(timing_data, 1);
                    end
                    sesdat.timing_data = timing_data; 
                    
                else
                    if l == 1 
                        raw490 = cell2mat(data(contains(data(:,1), 'B1GB'), 2)); 
                        raw405 = cell2mat(data(contains(data(:,1), 'B1CB'), 2));
                    elseif l == 2 
                        raw490 = cell2mat(data(contains(data(:,1), 'B2GB'), 2));
                        raw405 = cell2mat(data(contains(data(:,1), 'B2CB'), 2));
                    elseif l == 3 
                        raw490 = cell2mat(data(contains(data(:,1), 'BGB2'), 2));
                        raw405 = cell2mat(data(contains(data(:,1), 'BCB2'), 2));
                    elseif l == 4 
                        raw490 = cell2mat(data(contains(data(:,1), 'B7B2'), 2));
                        raw405 = cell2mat(data(contains(data(:,1), 'B1B2'), 2));
                    end

                    len490 = length(raw490); len405 = length(raw405);
                    if len490 ~= len405
                        min_len = min(len490, len405);
                        raw490 = raw490(1:min_len); raw405 = raw405(1:min_len);
                    end
                    
                    cfFinal = controlfit(raw490, raw405);
                    normDat = deltaFF(raw490, cfFinal);
                    [hp_normDat, ~] = hpFilter(ts, normDat);
                    lp_dFF = lpFilter(hp_normDat, conversion, lowpass_cutoff, filt_steepness, db_atten);
                    
                    sesdat.filt490 = raw490; 
                    sesdat.filt405 = raw405; 
                    sesdat.lp_dFF = lp_dFF;
                    sesdat.conversion = conversion;
                    
                    for t_idx = 1:length(time_windows)
                        current_time = time_windows{t_idx};
                        current_ev = ev; 
                        
                        for m = 1:size(current_ev, 1)
                            timestamps = cell2mat(current_ev(m, 2));
                            if isempty(timestamps); continue; end
                            
                            expected_length = ceil(current_time(1)*conversion) + ceil(current_time(2)*conversion) + 1;
                            trace_matrix = NaN(length(timestamps), expected_length); 
                            valid_indices = [];
                            
                            row_counter = 1;
                            for k = 1:length(timestamps)
                                adjts = ceil(conversion * timestamps(k)); 
                                idx_start = adjts - ceil(current_time(1)*conversion);
                                idx_end = adjts + ceil(current_time(2)*conversion);
                                
                                if idx_start > 0 && idx_end <= length(lp_dFF)
                                    signal = lp_dFF(idx_start : idx_end)';
                                    if length(signal) == expected_length
                                        trace_matrix(row_counter, :) = signal;
                                    else
                                        trace_matrix(row_counter, 1:length(signal)) = signal;
                                    end
                                    valid_indices(end+1) = k;
                                    row_counter = row_counter + 1;
                                end
                            end
                            
                            trace_matrix = trace_matrix(1:row_counter-1, :);
                            
                            if ~isempty(trace_matrix)
                               valid_timestamps = timestamps(valid_indices);
                               header_info = [valid_timestamps, ones(length(valid_timestamps),1)*m, zeros(length(valid_timestamps),2)];
                               current_ev{m, 2} = [header_info, trace_matrix];
                            else
                               current_ev{m, 2} = [];
                            end
                        end
                        
                        trace_field_name = sprintf('traces_%d_%d', current_time(1), current_time(2));
                        sesdat.(trace_field_name) = current_ev; 
                    end 
                end
                
                %% --- 8. MetaData & Save ---
                sesdat.rat = names{l};
                sesdat.ses = this_ses_id;
                sesdat.date = out_date_yyyymmdd; 
                sesdat.hemi = hemi;             
                sesdat.intensity = this_intensity; 
                sesdat.phase = 'Conf'; 
                
                if extract_photometry_traces
                    fileName = sprintf('%s_%s_Ses_%s_Rat_%s.mat', exp, out_date_yyyymmdd, this_ses_id, sesdat.rat);
                else
                    fileName = sprintf('%s_%s_Ses_%s_Rat_%s_TIMING.mat', exp, out_date_yyyymmdd, this_ses_id, sesdat.rat);
                end
                
                save(fullfile(output_folder, fileName), 'sesdat');
                
                clear sesdat cfFinal normDat hp_normDat trace_matrix current_ev timing_data raw490 raw405 lp_dFF;
            end % End Rat Loop
            
            clear data events ts conversion
        end % End TDT Folder Loop
    end % End Date Folder Loop
end % End Cohort Loop
fprintf('\nBatch Extraction Complete!\n');