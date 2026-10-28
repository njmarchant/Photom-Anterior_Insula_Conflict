%% This is the main extraction and plotting script for individual sessions
%it outputs a mat file per session per animal, where you can find the
%downsampled and filtered data and traces 
% Updated 10-05-2023 for TDT system with 4 photodectors (2 x Rz5P)
clear all
close all
%% define where the stuff is
exp = 'Conflict_06'; 
tankfolder = 'C:\Photometry\Conflict_06';
day = 's18';
session = 'P10';
type = 'Pun';

% --- TIME VARIABLES ---
% Enter as many different time windows here as you need. 
time1 = [10, 45]; 
time2 = [25, 15]; 
time_windows = {time1, time2}; % Groups them together to loop through

%% pre-processing
res = 64; % resampling factor
lowpass_cutoff = 3; %low-pass cut-off for Hz, e.g. 2
filt_steepness = .95; %how steep the fi lter transition is (0.5-1, default 0.85)
db_atten = 90; %decibel attenuation of filters (default = 60)
exc = 100; %signal to take out for pre-processing (for me is 300s = 5mins)

%% individual session data extraction
files_folder = fullfile(tankfolder, day);
files = dir(fullfile(files_folder));
files(ismember({files.name}, {'.', '..'})) = [];
folder_indices = find([files.isdir]);  
files = files(folder_indices);          
for i = 1:length(files) 
          fprintf('Extracting %10s \n', files(i).name);     
          [data, events, ts, conversion] = Sim_TDTextract([files_folder '\' files(i).name]); 
          names = strsplit(files(i).name, {'-' , '_'}); 

%% SEPARATE DATA TANKS LEFT AND RIGHT SET UPS
    for l = 1:4  
        r = names{l}; % Extract the rat label dynamically based on the loop index
        
        % Check for a placeholder 'x' (converted to lowercase just in case of 'X')
        if contains(lower(r), 'x')
            fprintf('Placeholder "%s" detected. Skipping extraction for this box.\n', r);
            continue; % Skips the rest of the code in this loop and moves to the next rat
        end
        if l == 1
            raw490 = cell2mat(data(contains(data(:,1), 'B1GB'), 2)); 
            raw405 =cell2mat(data(contains(data(:,1), 'B1CB'), 2));
            try
                side = 'B1'; 
                ev = events(startsWith(events(:,1), side), :); 
            catch
                fprintf('No events on left top side\n')
                break
            end
        elseif l == 2 
          raw490 = cell2mat(data(contains(data(:,1), 'B2GB'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B2CB'), 2));
          try
            side = 'B2'; 
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
         elseif l == 3
          raw490 = cell2mat(data(contains(data(:,1), 'BGB2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'BCB2'), 2));
          try
            side = 'B3'; 
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
          elseif l == 4
          raw490 = cell2mat(data(contains(data(:,1), 'B7B2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B1B2'), 2));
          try
            side = 'B4'; 
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
        end 
    
        % --- Initialize sesdat with raw data ---
        sesdat = struct(); % Create empty struct for this rat
        sesdat.raw490 = raw490;
        sesdat.raw405 = raw405;
    
        %% PREPROCESSING
        filt490 = raw490;
        filt405 = raw405;
        
        % Check sizes and truncate
        len490 = length(filt490);
        len405 = length(filt405);
        if len490 ~= len405
            min_len = min(len490, len405);
            fprintf('Size mismatch detected (490: %d, 405: %d). Truncating both to %d.\n', len490, len405, min_len);
            filt490 = filt490(1:min_len);
            filt405 = filt405(1:min_len);
        end
            
        cfFinal = controlfit(filt490, filt405);
        normDat= deltaFF(filt490,cfFinal);
        [hp_normDat, mov_normDat] = hpFilter(ts, normDat);
        lp_normDat = lpFilter(hp_normDat, conversion, lowpass_cutoff, filt_steepness, db_atten);
        lp_dFF = lp_normDat;
        lp_dFF_nohp = lpFilter(normDat, conversion, lowpass_cutoff, filt_steepness, db_atten);
        
        % Save preprocessed data into our combined structure
        sesdat.filt490 = filt490; 
        sesdat.filt405 = filt405; 
        sesdat.conversion = conversion;
        sesdat.lp_dFF = lp_dFF; 
        sesdat.lp_normDat = lp_normDat;
        sesdat.lp_dFF_nohp = lp_dFF_nohp;
    
        % Plot and save QC figures
        a = figure;
        plot(filt490)
        hold on
        plot(filt405)
        hold on
        plot(1:size(lp_dFF), lp_dFF);
        legend('490', '405', 'dFF')
        saveas(a, [tankfolder '\' day '\'  exp ' ' session ' ' names{5} ' DFF ' r '.png'])
        saveas(a, [tankfolder '\'  day '\' exp ' ' session ' ' names{5} ' DFF ' r '.fig'])
      
    
        %% MAKE TRACES...
        if ~isempty(ev) 
            
            % --- Loop to generate dynamically named trace fields ---
            for t_idx = 1:length(time_windows)
                current_time = time_windows{t_idx}; 
                current_ev = ev; % Fresh copy of events 
                
                n = 1;
                for m = 1:size(current_ev, 1)
                    tmp = cell2mat(current_ev(m, 2));
                    for k = 1:size(tmp, 1)
                        adjts = ceil(conversion*tmp(k, 1)); 
                        try
                        % Slice signal based on current time window
                        signal = lp_normDat(adjts-ceil(current_time(1)*conversion):adjts+ceil(current_time(2)*conversion))'; 
                        tmp2(k, :) = signal;
                        catch
                        fprintf('Trace around the timestamp goes over length of session signal! Ommiting and deleting ts...\n')
                            continue 
                        end
                    end
                    if exist('tmp2', 'var') 
                        if size(tmp, 1) > size(tmp2, 1)
                        tmp(end-(size(tmp, 1) - size(tmp2, 1))+1:end, :) = [];
                        end 
                        tmp(:,2) = ones*m; tmp(:,3:4) = zeros;
                    current_ev{m,2} = [tmp , tmp2];
                    clear tmp tmp2
                    end
                end
                
                % Create dynamic field name (e.g., 'traces_10_45')
                trace_field_name = sprintf('traces_%d_%d', current_time(1), current_time(2));
                
                % Save into the unified sesdat structure dynamically
                sesdat.(trace_field_name) = current_ev; 
            
            end % End of time windows loop
                  
            %% _____________ Code descriptive information into sesdat _______________
            
            % Simplified folder/phase naming since multiple trace types exist in one file now
            if strncmpi(session, 'R', 1) 
                folder_phase = 'Rew';
            elseif strncmpi(session, 'P', 1) 
                 folder_phase = 'Pun';
            elseif strncmpi(session, 'C', 1) 
                 folder_phase = 'Conf';
            else
                 folder_phase = 'Test';
            end
            
            sesdat.rat = r;
            sesdat.ses = session;    
            sesdat.phase = type;
            sesdat.date = files(i).name(end-12:end-7);
            
            %% - Save the file ONCE per rat -
            % Construct the filename cleanly
            folderName = fullfile(tankfolder, folder_phase);
            
            % Single file name per rat (e.g., "Conflict_05 Session R06 20230510 data R13.mat")
            fileName = sprintf('%s Session %s %s Rat %s.mat', exp, session, names{5}, r);
            fullPath = fullfile(folderName, fileName);
            
            % Create folder if needed
            if ~isfolder(folderName)
                mkdir(folderName);
            end
            
            % Save the unified structure
            save(fullPath, 'sesdat');
           
            clear sesdat current_ev; 
            
        else 
             fprintf('No events for session! Skipping to next session \n')
            continue
        end
    end % End of Rat loop
    
    close all
end