%% Collate zmean scores of multiple sessions into a single file per rat 

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)\';
phase = 'Alc_Tests Collated';

%% find files
filePath = fullfile(tankfolder,phase);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
numfiles = length(files);

%% variables to save
% saline
collated.all_sal.rewC_labels = [];
collated.all_sal.rewC = [];
collated.all_sal.rewO_labels = [];
collated.all_sal.rewO = [];
collated.all_sal.punC_labels = [];
collated.all_sal.punC = [];
collated.all_sal.punO_labels = [];
collated.all_sal.punO = [];
collated.all_sal.confC_labels = [];
collated.all_sal.confC = [];
collated.all_sal.confO_labels = [];
collated.all_sal.confO = [];
collated.mean_sallabels = cell(numfiles,4);
collated.mean_salrewC = zeros(numfiles,6);
collated.mean_salrewO = zeros(numfiles,5);
collated.mean_salpunC = zeros(numfiles,6);
collated.mean_salpunO = zeros(numfiles,5);
collated.mean_salconfC = zeros(numfiles,6);
collated.mean_salconfO = zeros(numfiles,5);
collated.responses_sal.rew = zeros(numfiles,3);
collated.responses_sal.pun = zeros(numfiles,3);
collated.responses_sal.conf = zeros(numfiles,3);

% Alcohol Low
collated.all_alc_low.rewC_labels = [];
collated.all_alc_low.rewC = [];
collated.all_alc_low.rewO_labels = [];
collated.all_alc_low.rewO = [];
collated.all_alc_low.punC_labels = [];
collated.all_alc_low.punC = [];
collated.all_alc_low.punO_labels = [];
collated.all_alc_low.punO = [];
collated.all_alc_low.confC_labels = [];
collated.all_alc_low.confC = [];
collated.all_alc_low.confO_labels = [];
collated.all_alc_low.confO = [];
collated.mean_alc_lowlabels = cell(numfiles,4);
collated.mean_alc_lowrewC = zeros(numfiles,6);
collated.mean_alc_lowrewO = zeros(numfiles,5);
collated.mean_alc_lowpunC = zeros(numfiles,6);
collated.mean_alc_lowpunO = zeros(numfiles,5);
collated.mean_alc_lowconfC = zeros(numfiles,6);
collated.mean_alc_lowconfO = zeros(numfiles,5);
collated.responses_alc_low.rew = zeros(numfiles,3);
collated.responses_alc_low.pun = zeros(numfiles,3);
collated.responses_alc_low.conf = zeros(numfiles,3);


% Alcohol High
collated.all_alc_hi.rewC_labels = [];
collated.all_alc_hi.rewC = [];
collated.all_alc_hi.rewO_labels = [];
collated.all_alc_hi.rewO = [];
collated.all_alc_hi.punC_labels = [];
collated.all_alc_hi.punC = [];
collated.all_alc_hi.punO_labels = [];
collated.all_alc_hi.punO = [];
collated.all_alc_hi.confC_labels = [];
collated.all_alc_hi.confC = [];
collated.all_alc_hi.confO_labels = [];
collated.all_alc_hi.confO = [];
collated.mean_alc_hilabels = cell(numfiles,4);
collated.mean_alc_hirewC = zeros(numfiles,6);
collated.mean_alc_hirewO = zeros(numfiles,5);
collated.mean_alc_hipunC = zeros(numfiles,6);
collated.mean_alc_hipunO = zeros(numfiles,5);
collated.mean_alc_hiconfC = zeros(numfiles,6);
collated.mean_alc_hiconfO = zeros(numfiles,5);
collated.responses_alc_hi.rew = zeros(numfiles,3);
collated.responses_alc_hi.pun = zeros(numfiles,3);
collated.responses_alc_hi.conf = zeros(numfiles,3);

% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    % saline
    collated.all_sal.rewC_labels = [collated.all_sal.rewC_labels; alldat.zmean_labels.sal_rew_labels];
    collated.all_sal.rewC = [collated.all_sal.rewC; alldat.zmean_data.sal_rew];
    collated.all_sal.rewO_labels = [collated.all_sal.rewO_labels; alldat.zmean_labels.sal_rewO_labels];
    collated.all_sal.rewO = [collated.all_sal.rewO; alldat.zmean_data.sal_rewO];
    collated.all_sal.punC_labels = [collated.all_sal.punC_labels; alldat.zmean_labels.sal_pun_labels];
    collated.all_sal.punC = [collated.all_sal.punC; alldat.zmean_data.sal_pun];
    collated.all_sal.punO_labels = [collated.all_sal.punO_labels; alldat.zmean_labels.sal_punO_labels];
    collated.all_sal.punO = [collated.all_sal.punO; alldat.zmean_data.sal_punO];
    collated.all_sal.confC_labels = [collated.all_sal.confC_labels; alldat.zmean_labels.sal_conf_labels];
    collated.all_sal.confC = [collated.all_sal.confC; alldat.zmean_data.sal_conf];
    collated.all_sal.confO_labels = [collated.all_sal.confO_labels; alldat.zmean_labels.sal_confO_labels];
    collated.all_sal.confO = [collated.all_sal.confO; alldat.zmean_data.sal_confO];  

    if ~isempty(alldat.zmean_labels.sal_rew_labels)
        collated.mean_sallabels{i,1} = alldat.zmean_labels.sal_rew_labels{1,1};
        collated.mean_sallabels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_rewCmean) 
         collated.mean_salrewC(i, :) = alldat.zmean_data.sal_rewCmean;
    end
    
    if ~isnan(alldat.zmean_data.sal_rewOmean) 
         collated.mean_salrewO(i, :) = alldat.zmean_data.sal_rewOmean;
    end
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_punCmean) 
         collated.mean_salpunC(i, :) = alldat.zmean_data.sal_punCmean;
    end
    
    if ~isnan(alldat.zmean_data.sal_punOmean) 
         collated.mean_salpunO(i, :) = alldat.zmean_data.sal_punOmean;
    end
    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_confCmean) 
         collated.mean_salconfC(i, :) = alldat.zmean_data.sal_confCmean;
    end
    
    if ~isnan(alldat.zmean_data.sal_confOmean) 
         collated.mean_salconfO(i, :) = alldat.zmean_data.sal_confOmean;
    end
    collated.responses_sal.rew(i,:) = alldat.responses.sal(1,:);  
    collated.responses_sal.pun(i,:) = alldat.responses.sal(2,:);  
    collated.responses_sal.conf(i,:) = alldat.responses.sal(3,:);  

    % Alcohol Low
    collated.all_alc_low.rewC_labels = [collated.all_alc_low.rewC_labels; alldat.zmean_labels.alc_low_rew_labels];
    collated.all_alc_low.rewC = [collated.all_alc_low.rewC; alldat.zmean_data.alc_low_rew];
    collated.all_alc_low.rewO_labels = [collated.all_alc_low.rewO_labels; alldat.zmean_labels.alc_low_rewO_labels];
    collated.all_alc_low.rewO = [collated.all_alc_low.rewO; alldat.zmean_data.alc_low_rewO];
    collated.all_alc_low.punC_labels = [collated.all_alc_low.punC_labels; alldat.zmean_labels.alc_low_pun_labels];
    collated.all_alc_low.punC = [collated.all_alc_low.punC; alldat.zmean_data.alc_low_pun];
    collated.all_alc_low.punO_labels = [collated.all_alc_low.punO_labels; alldat.zmean_labels.alc_low_punO_labels];
    collated.all_alc_low.punO = [collated.all_alc_low.punO; alldat.zmean_data.alc_low_punO];
    collated.all_alc_low.confC_labels = [collated.all_alc_low.confC_labels; alldat.zmean_labels.alc_low_conf_labels];
    collated.all_alc_low.confC = [collated.all_alc_low.confC; alldat.zmean_data.alc_low_conf];
    collated.all_alc_low.confO_labels = [collated.all_alc_low.confO_labels; alldat.zmean_labels.alc_low_confO_labels];
    collated.all_alc_low.confO = [collated.all_alc_low.confO; alldat.zmean_data.alc_low_confO];  

    if ~isempty(alldat.zmean_labels.alc_low_rew_labels{1,1})
        collated.mean_alc_lowlabels{i,1} = alldat.zmean_labels.alc_low_rew_labels{1,1};
        collated.mean_alc_lowlabels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_rewCmean) 
         collated.mean_alc_lowrewC(i, :) = alldat.zmean_data.alc_low_rewCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_low_rewOmean) 
         collated.mean_alc_lowrewO(i, :) = alldat.zmean_data.alc_low_rewOmean;
    end
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_punCmean) 
         collated.mean_alc_lowpunC(i, :) = alldat.zmean_data.alc_low_punCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_low_punOmean) 
         collated.mean_alc_lowpunO(i, :) = alldat.zmean_data.alc_low_punOmean;
    end
    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_confCmean) 
         collated.mean_alc_lowconfC(i, :) = alldat.zmean_data.alc_low_confCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_low_confOmean) 
         collated.mean_alc_lowconfO(i, :) = alldat.zmean_data.alc_low_confOmean;
    end
    collated.responses_alc_low.rew(i,:) = alldat.responses.alc_low(1,:);  
    collated.responses_alc_low.pun(i,:) = alldat.responses.alc_low(2,:);  
    collated.responses_alc_low.conf(i,:) = alldat.responses.alc_low(3,:);  

     % Alcohol High
    collated.all_alc_hi.rewC_labels = [collated.all_alc_hi.rewC_labels; alldat.zmean_labels.alc_hi_rew_labels];
    collated.all_alc_hi.rewC = [collated.all_alc_hi.rewC; alldat.zmean_data.alc_hi_rew];
    collated.all_alc_hi.rewO_labels = [collated.all_alc_hi.rewO_labels; alldat.zmean_labels.alc_hi_rewO_labels];
    collated.all_alc_hi.rewO = [collated.all_alc_hi.rewO; alldat.zmean_data.alc_hi_rewO];
    collated.all_alc_hi.punC_labels = [collated.all_alc_hi.punC_labels; alldat.zmean_labels.alc_hi_pun_labels];
    collated.all_alc_hi.punC = [collated.all_alc_hi.punC; alldat.zmean_data.alc_hi_pun];
    collated.all_alc_hi.punO_labels = [collated.all_alc_hi.punO_labels; alldat.zmean_labels.alc_hi_punO_labels];
    collated.all_alc_hi.punO = [collated.all_alc_hi.punO; alldat.zmean_data.alc_hi_punO];
    collated.all_alc_hi.confC_labels = [collated.all_alc_hi.confC_labels; alldat.zmean_labels.alc_hi_conf_labels];
    collated.all_alc_hi.confC = [collated.all_alc_hi.confC; alldat.zmean_data.alc_hi_conf];
    collated.all_alc_hi.confO_labels = [collated.all_alc_hi.confO_labels; alldat.zmean_labels.alc_hi_confO_labels];
    collated.all_alc_hi.confO = [collated.all_alc_hi.confO; alldat.zmean_data.alc_hi_confO];  

    if ~isempty(alldat.zmean_labels.alc_hi_rew_labels)
        collated.mean_alc_hilabels{i,1} = alldat.zmean_labels.alc_hi_rew_labels{1,1};
        collated.mean_alc_hilabels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_rewCmean) 
         collated.mean_alc_hirewC(i, :) = alldat.zmean_data.alc_hi_rewCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_hi_rewOmean) 
         collated.mean_alc_hirewO(i, :) = alldat.zmean_data.alc_hi_rewOmean;
    end
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_punCmean) 
         collated.mean_alc_hipunC(i, :) = alldat.zmean_data.alc_hi_punCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_hi_punOmean) 
         collated.mean_alc_hipunO(i, :) = alldat.zmean_data.alc_hi_punOmean;
    end
    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_confCmean) 
         collated.mean_alc_hiconfC(i, :) = alldat.zmean_data.alc_hi_confCmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_hi_confOmean) 
         collated.mean_alc_hiconfO(i, :) = alldat.zmean_data.alc_hi_confOmean;
    end
    collated.responses_alc_hi.rew(i,:) = alldat.responses.alc_hi(1,:);  
    collated.responses_alc_hi.pun(i,:) = alldat.responses.alc_hi(2,:);  
    collated.responses_alc_hi.conf(i,:) = alldat.responses.alc_hi(3,:);

end
   p = char(phase);
    folderName = strcat(tankfolder,'\',phase);
        save([folderName '\Conflict 02 ' p ' zMean all rats.mat'], 'collated')