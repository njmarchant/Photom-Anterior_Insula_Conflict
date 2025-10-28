%% Collate zmean scores of multiple sessions into a single file per rat 

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(25-15)';
phase = 'pun_early collated';

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

% Remove to focus on responses only
% collated.all.rewO_labels = [];
% collated.all.rewO = [];
% collated.all.punO_labels = [];
% collated.all.punO = [];

% Pre-allocated size to fit TRIAL-base analysis
% collated.mean.labels = cell(numfiles,2);
% collated.mean.rewC = zeros(numfiles,6);
% collated.mean.rewO = zeros(numfiles,5);
% collated.mean.punC = zeros(numfiles,6);
% collated.mean.punO = zeros(numfiles,5);

% Remove to focus on responses only
% collated.responses.rew = zeros(numfiles,3);
% collated.responses.pun = zeros(numfiles,3);

% Pre-allocated size to fit RESPONSE-based analysis
collated.mean.rewC = zeros(numfiles,10);
collated.mean.punC = zeros(numfiles,10);


% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    collated.all.rewC_labels = [collated.all.rewC_labels; alldat.zmean_labels.rew_labels];
    collated.all.rewC = [collated.all.rewC; alldat.zmean_data.rew];
    % collated.all.rewO_labels = [collated.all.rewO_labels; alldat.zmean_labels.rewO_labels];
    % collated.all.rewO = [collated.all.rewO; alldat.zmean_data.rewO];
    collated.all.punC_labels = [collated.all.punC_labels; alldat.zmean_labels.pun_labels];
    collated.all.punC = [collated.all.punC; alldat.zmean_data.pun];
    % collated.all.punO_labels = [collated.all.punO_labels; alldat.zmean_labels.punO_labels];
    % collated.all.punO = [collated.all.punO; alldat.zmean_data.punO];
 

    if ~isempty(alldat.zmean_labels.rew_labels{1,1})
        collated.mean.labels{i,1} = alldat.zmean_labels.rew_labels{1,1};
        collated.mean.labels{i,2} = phase;

        collated.mean.labels{i,1} = alldat.zmean_labels.rew_labels{1,1};
        collated.mean.labels{i,2} = alldat.zmean_labels.rew_labels{1,2};
        collated.mean.labels{i,3} = alldat.zmean_labels.rew_labels{1,3};
        collated.mean.labels{i,4} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.rewCmean) 
         collated.mean.rewC(i, :) = alldat.zmean_data.rewCmean;
    end
    
    % Remove to focus on responses only
    % if ~isnan(alldat.zmean_data.rewOmean) 
    %      collated.mean.rewO(i, :) = alldat.zmean_data.rewOmean;
    % end
    
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.punCmean) 
         collated.mean.punC(i, :) = alldat.zmean_data.punCmean;
    end
    
    % Remove to focus on responses only
    % if ~isnan(alldat.zmean_data.punOmean) 
    %      collated.mean.punO(i, :) = alldat.zmean_data.punOmean;
    % end
    % collated.responses.rewC(i,:) = alldat.responses(1,:);  
    % collated.responses.punC(i,:) = alldat.responses(2,:);  
end
   p = char(phase);
    % folderName = strcat(tankfolder,phase);
        save([filePath '\Conflict 02 ' p ' zMean all rats.mat'], 'collated')