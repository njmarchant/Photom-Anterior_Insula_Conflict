%% Nathan Marchant July 2024
% Written for the conflict task
% Collate zmean scores of multiple sessions into a single file per
% experiment
% Only for rewDS trials - and thus this is only for the rewDS phase of the
% experiment


fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(25-15)\combined';

%% find files
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
numfiles = length(files);

%% variables to save

collated.all.rewC_labels = [];
collated.all.rewC = [];
% collated.all.rewO_labels = [];
% collated.all.rewO = [];


% Pre-allocated size to fit TRIAL-base analysis
% collated.mean.labels = cell(numfiles,2);
% collated.mean.rewC = zeros(numfiles,6);
% collated.mean.rewO = zeros(numfiles,5);

% Pre-allocated size to fit RESPONSE-based analysis
collated.mean.labels = cell(numfiles,4);
collated.mean.rewC = zeros(numfiles,10);

collated.responses.rew = zeros(numfiles,3);

% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    collated.all.rewC_labels = [collated.all.rewC_labels; alldat.zmean_labels.rew_labels];
    collated.all.rewC = [collated.all.rewC; alldat.zmean_data.rew];
    % collated.all.rewO_labels = [collated.all.rewO_labels; alldat.zmean_labels.rewO_labels];
    % collated.all.rewO = [collated.all.rewO; alldat.zmean_data.rewO];

    if ~isempty(alldat.zmean_labels.rew_labels{1,1})
        collated.mean.labels{i,1} = alldat.zmean_labels.rew_labels{1,1};
        collated.mean.labels{i,2} = alldat.zmean_labels.rew_labels{1,2};
        collated.mean.labels{i,3} = alldat.zmean_labels.rew_labels{1,3};
        collated.mean.labels{i,4} = 'rewDS';
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.rewCmean) 
         collated.mean.rewC(i, :) = alldat.zmean_data.rewCmean;
    end
    % Removed to focus on responses only
    % if ~isnan(alldat.zmean_data.rewOmean) 
    %      collated.mean.rewO(i, :) = alldat.zmean_data.rewOmean;
    % end
    collated.responses.rew(i,:) = alldat.responses(1,:);  

end
   folderName = strcat(tankfolder);
        save([folderName '\Conflict 02 rewDS zMean all rats.mat'], 'collated')