%% This is the main extraction and plotting script for individual sessions
%it outputs a at file per session per animal, where you can find the
%downsampled and filtered data and traces 
% Updated 10-05-2023 for TDT system with 4 photodectors (2 x Rz5P)
clear all
close all



%% define where the stuff is
exp = 'Conflict_04'; 
tankfolder = 'C:\Photometry\Conflict_04';
session = '13_11_25';

%Conflict 02c = 
% ses = 'R04';
type = 'Check_1';
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

        elseif l == 2 
          r = names{2};
          % find data from left bottom set up (BOX 2)
          % Box 2 GCaMP = B2GB; or LD1B
          % Box 2 Control = B2CB; or LD2B
          raw490 = cell2mat(data(contains(data(:,1), 'B2GB'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B2CB'), 2));

         elseif l == 3
          r = names{3}; 
          % find data from right top set up (BOX 3)
          % Box 3 GCaMP = BGB2; or RCB2
          % Box 3 Vontrol = BCB2; or RSB2
          raw490 = cell2mat(data(contains(data(:,1), 'BGB2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'BCB2'), 2));

          elseif l == 4
          r = names{4}; 
          % find data from right bottom set up (BOX 4)
          % Box 4 GCaMP = B7B2; or R1B2
          % Box 4 Vontrol = B1B2; or R2B2
          raw490 = cell2mat(data(contains(data(:,1), 'B7B2'), 2));
          raw405 =cell2mat(data(contains(data(:,1), 'B1B2'), 2));
   
        end 
    
        %save raw traces without processing
        sesdat.raw490 = raw490;
        sesdat.raw405 = raw405;
    
        %% PREPROCESSING
        % CLEAN UP - exclude beginning of session when the rat is tethered/5 min wait
        % tmp = ceil(conversion*exc);
        % filt490 = raw490(tmp:7000);
        % filt405 = raw405(tmp:7000);
        % ts_adjt = linspace(ts(1), ts(end),  size(filt490, 1))'; %change time vector for all session based on begining exclusion
        % new_ts = ts(1:tmp);
        % new_ts(1:end) = ones; %this is to combine with the final data for the trace making
        % clear tmp
        
        filt490 = raw490;
        filt405 = raw405;
    
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

        end
   
    
    close all
end 


 

