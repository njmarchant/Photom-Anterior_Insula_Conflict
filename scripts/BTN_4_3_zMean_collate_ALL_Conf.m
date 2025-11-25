%% Collate zmean scores of multiple sessions into a single file per rat 

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-45)\';
phase = 'conf_early';

%% find files
filePath = fullfile(tankfolder,phase);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
numfiles = length(files);

%% variables to save

collated.all.rewC_labels = [];
collated.all.rewC = [];
collated.all.rewO_labels = [];
collated.all.rewO = [];

collated.all.punC_labels = [];
collated.all.punC = [];
collated.all.punO_labels = [];
collated.all.punO = [];

collated.all.confC_labels = [];
collated.all.confC = [];
collated.all.confO_labels = [];
collated.all.confO = [];

collated.mean.labels = cell(numfiles,2);
collated.mean.rewC = zeros(numfiles,6);
collated.mean.rewO = zeros(numfiles,5);
collated.mean.punC = zeros(numfiles,6);
collated.mean.punO = zeros(numfiles,5);
collated.mean.confC = zeros(numfiles,6);
collated.mean.confO = zeros(numfiles,5);

collated.responses.rew = zeros(numfiles,3);
collated.responses.pun = zeros(numfiles,3);
collated.responses.conf = zeros(numfiles,3);

% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    collated.all.rewC_labels = [collated.all.rewC_labels; alldat.zmean_labels.rew_labels];
    collated.all.rewC = [collated.all.rewC; alldat.zmean_data.rew];
    collated.all.rewO_labels = [collated.all.rewO_labels; alldat.zmean_labels.rewO_labels];
    collated.all.rewO = [collated.all.rewO; alldat.zmean_data.rewO];
    collated.all.punC_labels = [collated.all.punC_labels; alldat.zmean_labels.pun_labels];
    collated.all.punC = [collated.all.punC; alldat.zmean_data.pun];
    collated.all.punO_labels = [collated.all.punO_labels; alldat.zmean_labels.punO_labels];
    collated.all.punO = [collated.all.punO; alldat.zmean_data.punO];
    collated.all.confC_labels = [collated.all.confC_labels; alldat.zmean_labels.conf_labels];
    collated.all.confC = [collated.all.confC; alldat.zmean_data.conf];
    collated.all.confO_labels = [collated.all.confO_labels; alldat.zmean_labels.confO_labels];
    collated.all.confO = [collated.all.confO; alldat.zmean_data.confO];  

    if ~isempty(alldat.zmean_labels.rew_labels{1,1})
        collated.mean.labels{i,1} = alldat.zmean_labels.rew_labels{1,1};
        collated.mean.labels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.rewCmean) 
         collated.mean.rewC(i, :) = alldat.zmean_data.rewCmean;
    end
    
    if ~isnan(alldat.zmean_data.rewOmean) 
         collated.mean.rewO(i, :) = alldat.zmean_data.rewOmean;
    end
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.punCmean) 
         collated.mean.punC(i, :) = alldat.zmean_data.punCmean;
    end
    
    if ~isnan(alldat.zmean_data.punOmean) 
         collated.mean.punO(i, :) = alldat.zmean_data.punOmean;
    end
    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.confCmean) 
         collated.mean.confC(i, :) = alldat.zmean_data.confCmean;
    end
    
    if ~isnan(alldat.zmean_data.confOmean) 
         collated.mean.confO(i, :) = alldat.zmean_data.confOmean;
    end
    collated.responses.rew(i,:) = alldat.responses(1,:);  
    collated.responses.pun(i,:) = alldat.responses(2,:);  
    collated.responses.conf(i,:) = alldat.responses(3,:);  
end
   p = char(phase);
    folderName = strcat(tankfolder,phase);
        save([folderName '\Conflict 02 ' p ' zMean all rats.mat'], 'collated')