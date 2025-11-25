%% Collate zmean scores of multiple sessions into a single file per rat 

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(25-15)\';
phase = 'conf_late';

%% find files
filePath = fullfile(tankfolder,phase);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
numfiles = length(files);

%% variables to save

collated.all.rewC_labels = [];
collated.all.rewC = [];
collated.all.punC_labels = [];
collated.all.punC = [];
collated.all.confrew_labels = [];
collated.all.confrew = [];
collated.all.confpun_labels = [];
collated.all.confpun = [];

collated.mean.labels = cell(numfiles,2);
collated.mean.rewC = zeros(numfiles,10);
collated.mean.punC = zeros(numfiles,10);
collated.mean.confrew = zeros(numfiles,10);
collated.mean.confpun = zeros(numfiles,10);

% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    collated.all.rewC_labels = [collated.all.rewC_labels; alldat.zmean_labels.rew_labels];
    collated.all.rewC = [collated.all.rewC; alldat.zmean_data.rew];
    collated.all.punC_labels = [collated.all.punC_labels; alldat.zmean_labels.pun_labels];
    collated.all.punC = [collated.all.punC; alldat.zmean_data.pun];
    collated.all.confrew_labels = [collated.all.confrew_labels; alldat.zmean_labels.confrew_labels];
    collated.all.confrew = [collated.all.confrew; alldat.zmean_data.confrew];
    collated.all.confpun_labels = [collated.all.confpun_labels; alldat.zmean_labels.confpun_labels];
    collated.all.confpun = [collated.all.confpun; alldat.zmean_data.confpun];  

    if ~isempty(alldat.zmean_labels.rew_labels{1,1})
        collated.mean.labels{i,1} = alldat.zmean_labels.rew_labels{1,1};
        collated.mean.labels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.rewCmean) 
         collated.mean.rewC(i, :) = alldat.zmean_data.rewCmean;
    end
    
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.punCmean) 
         collated.mean.punC(i, :) = alldat.zmean_data.punCmean;
    end

    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.confrewmean) 
         collated.mean.confrew(i, :) = alldat.zmean_data.confrewmean;
    end
    
    if ~isnan(alldat.zmean_data.confpunmean) 
         collated.mean.confpun(i, :) = alldat.zmean_data.confpunmean;
    end
 
end
   p = char(phase);
    folderName = strcat(tankfolder,phase);
        save([folderName '\Conflict 02 ' p ' zMean all rats.mat'], 'collated')