%% This is the main extraction and plotting script for individual sessions
%it outputs a at file per session per animal, where you can find the
%downsampled and filtered data and traces 
% Updated 10-05-2023 for TDT system with 4 photodectors (2 x Rz5P)
clear all
close all



%% define where the stuff is
exp = 'Conflict_04'; 
tankfolder = 'C:\Photometry\Conflict_04';
session = 's1';

%Conflict 02c = 
ses = 'R01';
type = 'Rew';
%limits for trace making - the first one is the time before epoch, second one is after (ALWAYS KEEP BOTH POSITIVE)
% if you want plots of all sessions at the end of the extraction
time = [10, 40]; %REMEMBER TO CHANGE THIS DEPENDING ON THE XP!!!!!


%% pre-processing
res = 64; % resampling factor
lowpass_cutoff = 3; %low-pass cut-off for Hz, e.g. 2
filt_steepness = .95; %how steep the fi lter transition is (0.5-1, default 0.85)
db_atten = 90; %decibel attenuation of filters (default = 60)
exc = 100; %signal to take out for pre-processing (for me is 300s = 5mins)


%% individual session data extraction 
files = dir(fullfile(tankfolder,session));
files(ismember({files.name}, {'.', '..'})) = [];
folder_indices = find([files.isdir]);  % Find indices of folders
files = files(folder_indices);          % Keep only folders in the list
for i = 1:length(files) %iterate through experiment folder
          fprintf('Extracting %10s \n', files(i).name);     
          [data, events, ts, conversion] = Sim_TDTextract([tankfolder '\' session '\' files(i).name]); % extract data from both set ups
          names = strsplit(files(i).name, {'-' , '_'}); %divide the file name into separte character vectors
          %col 1 = Left Top rat
          %col 2 = Left Bottom rat
          %col 3 = Right Top rat
          %col 4 = Right Bottom rat
          %col 5 = date

%% SEPARATE DATA TANKS LEFT AND RIGHT SET UPS
% DOUBLE CHECK THE STORE NAMES FOR THE DATA TANKS!!! One set up did weird stuff 
    for l = 1:4  %go through the rats
        if l == 1
            r = names{1};
            % find data from left top set up (BOX 1)
            % Box 1 GCaMP = B1GB; or LT1B
            % Box 1 Control = B1CB; or LT2B
            raw490 = cell2mat(data(contains(data(:,1), 'B1GB'), 2)); 
            raw405 =cell2mat(data(contains(data(:,1), 'B1CB'), 2));
            try
                side = 'B1'; % find data from left top set up
                ev = events(startsWith(events(:,1), side), :); 
            catch
                fprintf('No events on left top side\n')
                break
            end
        elseif l == 2 
          r = names{2};
          % find data from left bottom set up (BOX 2)
          % Box 2 GCaMP = B2GB; or LD1B
          % Box 2 Control = B2CB; or LD2B
          raw490 = cell2mat(data(contains(data(:,1), 'B2GB'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B2CB'), 2));
          try
            side = 'B2'; %find data from left bottom set up
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
         elseif l == 3
          r = names{3}; 
          % find data from right top set up (BOX 3)
          % Box 3 GCaMP = BGB2; or RCB2
          % Box 3 Vontrol = BCB2; or RSB2
          raw490 = cell2mat(data(contains(data(:,1), 'BGB2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'BCB2'), 2));
          try
            side = 'B3'; %Events are labeled by box number
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
          elseif l == 4
          r = names{4}; 
          % find data from right bottom set up (BOX 4)
          % Box 4 GCaMP = B7B2; or R1B2
          % Box 4 Vontrol = B1B2; or R2B2
          raw490 = cell2mat(data(contains(data(:,1), 'B7B2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B1B2'), 2));
          try
            side = 'B4'; %Events are labeled by box number
            ev = events(startsWith(events(:,1), side), :);
          catch
            fprintf('No events on left bottom side\n')
            break
          end
        end 
    
        %save raw traces without processing
        sesdat.raw490 = raw490;
        sesdat.raw405 = raw405;
    
        %% PREPROCESSING (Fixed)
        % Calculate the index to start at (conversion rate * seconds to exclude)
        tmp = ceil(conversion * exc); 
        
        % Start from the exclusion point and go to the END of the file
        filt490 = raw490(tmp:end);
        filt405 = raw405(tmp:end);
        
        % Adjust the timestamp vector to match the new shorter data
        % We remove the first 'tmp' timestamps
        ts = ts(tmp:end);
        
        %_____ OLD METHOD __________________________
        %filt490 = raw490;
        %filt405 = raw405;

        % --- FIX SIZE MISMATCH ---
        % Check if lengths differ and truncate to the shorter one
        len490 = length(filt490);
        len405 = length(filt405);
        
        if len490 ~= len405
            min_len = min(len490, len405);
            fprintf('Size mismatch detected (490: %d, 405: %d). Truncating both to %d.\n', len490, len405, min_len);
            
            % Keep indices 1 to min_len (removes the end of the longer array)
            filt490 = filt490(1:min_len);
            filt405 = filt405(1:min_len);
        end
            
        % Fit control to signal and calculate DFF
        cfFinal = controlfit(filt490, filt405);
        normDat= deltaFF(filt490,cfFinal);
    
    %   Highpass filter and moving average...
        [hp_normDat, mov_normDat] = hpFilter(ts, normDat);
    
        %lowpassfilter 
        lp_normDat = lpFilter(hp_normDat, conversion, lowpass_cutoff,...
        filt_steepness, db_atten);
    
        lp_dFF = lp_normDat; %this is the DFF with the exclusion at the begining
    %   lp_normDat = [new_ts; lp_normDat]; % this is the begining as ones
        sesdat.filt490 = filt490; %save filtered 409
        sesdat.filt405 = filt405; %save filtered 405
    
        sesdat.conversion = conversion;
        sesdat.lp_dFF = lp_dFF; 
        sesdat.lp_normDat = lp_normDat;
    
    %     plot and save for quality control
        % a = figure;
        % plot(filt490)
        % hold on
        % plot(filt405)
        % hold on
        % plot(1:size(lp_dFF), lp_dFF);
        % legend('490', '405', 'dFF')
        % saveas(a, [tankfolder '\' session, '\' exp ' ' type ' date ' names{5} ' DFF ' r '.png'])
      
    
        %% MAKE TRACES...
        if ~isempty(ev) %if events variable is not empty
            n = 1;
            for m = 1:size(ev, 1)
                tmp = cell2mat(ev(m, 2));
                for k = 1:size(tmp, 1)
                    adjts = ceil(conversion*tmp(k, 1)); % get adjusted timestamps based on the sampling rate
                    try
                    signal = lp_normDat(adjts-ceil(time(1)*conversion):adjts+ceil(time(end)*conversion))'; 
                    tmp2(k, :) = signal;
                    catch
                    fprintf('Trace around the timestamp goes over length of session signal! Ommiting and deleting ts...\n')
                        continue %jump to the iteration
                    end
                end
                if exist('tmp2', 'var') 
                    if size(tmp, 1) > size(tmp2, 1)
                    tmp(end-(size(tmp, 1) - size(tmp2, 1))+1:end, :) = [];
                    end 
                    tmp(:,2) = ones*m; tmp(:,3:4) = zeros;
                ev{m,2} = [tmp , tmp2];
                clear tmp tmp2
                end
            end
            sesdat.traces = ev; %save
        
        %% ______ Code the recorded Hemisphere into sesdat  _______________
        % %conflict 02b
        % Left only = R09, R11, R16
        % Right only = R10, R12, R15
        % Bilat = R13, R14
        %     names_2 = strsplit(session, {'-' , '_', ' '}); %divide the file name into separte character vectors
        %     side = names_2{4};
        %     Left_rat = {'R09','R11','R13','R15'}; % - From 04-02-24 R13 is always L 
        %     Right_rat = {'R10','R12','R16'};
        %     found_L = any(strcmp(r, Left_rat));
        %     found_R = any(strcmp(r, Right_rat));
        % % Check if the value was found and code the hemi
        %     if found_L
        %         sesdat.hemi = 'Left';
        %     elseif found_R
        %         sesdat.hemi = 'Right';
        %     elseif strcmp(side, '(R)')
        %         sesdat.hemi = 'Right';
        %     elseif strcmp(side, '(L)')
        %         sesdat.hemi = 'Left';
        %     else
        %         sesdat.hemi = 'null';
        %     end
        
        
        
        
        
        %% ______ Code the session detail into sesdat _______________
        sesdat.ses = ses;

        %% _____________ Code descriptive information into sesdat _______________
        sesdat.rat = r;
        sesdat.phase = type;
        sesdat.date = files(i).name(end-12:end-7);
        
        %% - Save the file
        folderName = strcat(tankfolder, '\',type);
            if ~isfolder(folderName)  % Check if the folder does not exist
                mkdir(folderName);  % Create the folder
                save([folderName '\' exp ' ' type ' ' names{5} ' data ' r  '.mat'], 'sesdat')
            else
                save([folderName '\' exp ' ' type ' ' names{5} ' data ' r  '.mat'], 'sesdat')
            end
        
        
        clear sesdat; 
        else 
             fprintf('No events for session! Skipping to next session \n')
            continue
        end
    end 
    
    close all
end 


 

