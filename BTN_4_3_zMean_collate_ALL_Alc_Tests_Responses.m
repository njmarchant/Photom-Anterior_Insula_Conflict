%% Collate zmean scores of multiple sessions into a single file per rat 

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(25-15)\';
phase = 'Alc_Tests Collated';

%% find files
filePath = fullfile(tankfolder,phase);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
numfiles = length(files);

%% variables to save
% saline
collated.all_sal.rew_labels = [];
collated.all_sal.rew = [];
collated.all_sal.pun_labels = [];
collated.all_sal.pun = [];
collated.all_sal.confrew_labels = [];
collated.all_sal.confrew = [];
collated.all_sal.confpun_labels = [];
collated.all_sal.confpun = [];
collated.mean_sal_rew_labels = cell(numfiles,2);
collated.mean_sal_rew = zeros(numfiles,10);
collated.mean_sal_pun = zeros(numfiles,10);
collated.mean_sal_confrew = zeros(numfiles,10);
collated.mean_sal_confpun = zeros(numfiles,10);

% Alcohol Low
collated.all_alc_low.rew_labels = [];
collated.all_alc_low.rew = [];
collated.all_alc_low.pun_labels = [];
collated.all_alc_low.pun = [];
collated.all_alc_low.confrew_labels = [];
collated.all_alc_low.confrew = [];
collated.all_alc_low.confpun_labels = [];
collated.all_alc_low.confpun = [];
collated.mean_alc_low_rew_labels = cell(numfiles,2);
collated.mean_alc_low_rew = zeros(numfiles,10);
collated.mean_alc_low_pun = zeros(numfiles,10);
collated.mean_alc_low_confrew = zeros(numfiles,10);
collated.mean_alc_low_confpun = zeros(numfiles,10);


% Alcohol High
collated.all_alc_hi.rew_labels = [];
collated.all_alc_hi.rew = [];
collated.all_alc_hi.pun_labels = [];
collated.all_alc_hi.pun = [];
collated.all_alc_hi.confrew_labels = [];
collated.all_alc_hi.confrew = [];
collated.all_alc_hi.confpun_labels = [];
collated.all_alc_hi.confpun = [];
collated.mean_alc_hi_rew_labels = cell(numfiles,2);
collated.mean_alc_hi_rew = zeros(numfiles,10);
collated.mean_alc_hi_pun = zeros(numfiles,10);
collated.mean_alc_hi_confrew = zeros(numfiles,10);
collated.mean_alc_hi_confpun = zeros(numfiles,10);

% Loop through files to collate data
for i = 1:numfiles
    load(fullfile(filePath, files(i).name));
    % saline
    collated.all_sal.rew_labels = [collated.all_sal.rew_labels; alldat.zmean_labels.sal_rew_labels];
    collated.all_sal.rew = [collated.all_sal.rew; alldat.zmean_data.sal_rew];
    collated.all_sal.pun_labels = [collated.all_sal.pun_labels; alldat.zmean_labels.sal_pun_labels];
    collated.all_sal.pun = [collated.all_sal.pun; alldat.zmean_data.sal_pun];
    collated.all_sal.confrew_labels = [collated.all_sal.confrew_labels; alldat.zmean_labels.sal_confrew_labels];
    collated.all_sal.confrew = [collated.all_sal.confrew; alldat.zmean_data.sal_confrew];
    collated.all_sal.confpun_labels = [collated.all_sal.confpun_labels; alldat.zmean_labels.sal_confpun_labels];
    collated.all_sal.confpun = [collated.all_sal.confpun; alldat.zmean_data.sal_confpun];  

    if ~isempty(alldat.zmean_labels.sal_rew_labels{1,1})
        collated.mean_sal_rew_labels{i,1} = alldat.zmean_labels.sal_rew_labels{1,1};
        collated.mean_sal_rew_labels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_rewmean) 
         collated.mean_sal_rew(i, :) = alldat.zmean_data.sal_rewmean;
    end
    

    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_punmean) 
         collated.mean_sal_pun(i, :) = alldat.zmean_data.sal_punmean;
    end
    

    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.sal_confrewmean) 
         collated.mean_sal_confrew(i, :) = alldat.zmean_data.sal_confrewmean;
    end
    
    if ~isnan(alldat.zmean_data.sal_confpunmean) 
         collated.mean_sal_confpun(i, :) = alldat.zmean_data.sal_confpunmean;
    end
 

    % Alcohol Low
    collated.all_alc_low.rew_labels = [collated.all_alc_low.rew_labels; alldat.zmean_labels.alc_low_rew_labels];
    collated.all_alc_low.rew = [collated.all_alc_low.rew; alldat.zmean_data.alc_low_rew];
    collated.all_alc_low.pun_labels = [collated.all_alc_low.pun_labels; alldat.zmean_labels.alc_low_pun_labels];
    collated.all_alc_low.pun = [collated.all_alc_low.pun; alldat.zmean_data.alc_low_pun];
    collated.all_alc_low.confrew_labels = [collated.all_alc_low.confrew_labels; alldat.zmean_labels.alc_low_conf_labels];
    collated.all_alc_low.confrew = [collated.all_alc_low.confrew; alldat.zmean_data.alc_low_conf];
    collated.all_alc_low.confpun_labels = [collated.all_alc_low.confpun_labels; alldat.zmean_labels.alc_low_confpun_labels];
    collated.all_alc_low.confpun = [collated.all_alc_low.confpun; alldat.zmean_data.alc_low_confpun];  

    if ~isempty(alldat.zmean_labels.alc_low_rew_labels{1,1})
        collated.mean_alc_low_labels{i,1} = alldat.zmean_labels.alc_low_rew_labels{1,1};
        collated.mean_alc_low_labels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_rewmean) 
         collated.mean_alc_low_rew(i, :) = alldat.zmean_data.alc_low_rewmean;
    end
    

    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_punmean) 
         collated.mean_alc_low_pun(i, :) = alldat.zmean_data.alc_low_punmean;
    end
    

    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_low_confrewmean) 
         collated.mean_alc_low_confrew(i, :) = alldat.zmean_data.alc_low_confrewmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_low_confpunmean) 
         collated.mean_alc_low_confpun(i, :) = alldat.zmean_data.alc_low_confpunmean;
    end

    % Alcohol High
    collated.all_alc_hi.rew_labels = [collated.all_alc_hi.rew_labels; alldat.zmean_labels.alc_hi_rew_labels];
    collated.all_alc_hi.rew = [collated.all_alc_hi.rew; alldat.zmean_data.alc_hi_rew];
    collated.all_alc_hi.pun_labels = [collated.all_alc_hi.pun_labels; alldat.zmean_labels.alc_hi_pun_labels];
    collated.all_alc_hi.pun = [collated.all_alc_hi.pun; alldat.zmean_data.alc_hi_pun];
    collated.all_alc_hi.confrew_labels = [collated.all_alc_hi.confrew_labels; alldat.zmean_labels.alc_hi_conf_labels];
    collated.all_alc_hi.confrew = [collated.all_alc_hi.confrew; alldat.zmean_data.alc_hi_conf];
    collated.all_alc_hi.confpun_labels = [collated.all_alc_hi.confpun_labels; alldat.zmean_labels.alc_hi_confpun_labels];
    collated.all_alc_hi.confpun = [collated.all_alc_hi.confpun; alldat.zmean_data.alc_hi_confpun];  

    if ~isempty(alldat.zmean_labels.alc_hi_rew_labels)
        collated.mean_alc_hi_labels{i,1} = alldat.zmean_labels.alc_hi_rew_labels{1,1};
        collated.mean_alc_hi_labels{i,2} = phase;
    end
    % Check if the reward means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_rewmean) 
         collated.mean_alc_hi_rew(i, :) = alldat.zmean_data.alc_hi_rewmean;
    end
    
    % Check if the punishment means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_punmean) 
         collated.mean_alc_hi_pun(i, :) = alldat.zmean_data.alc_hi_punmean;
    end

    % Check if the conflict means are NaN and if not add it to the array
    if ~isnan(alldat.zmean_data.alc_hi_confrewmean) 
         collated.mean_alc_hi_confrew(i, :) = alldat.zmean_data.alc_hi_confrewmean;
    end
    
    if ~isnan(alldat.zmean_data.alc_hi_confpunmean) 
         collated.mean_alc_hi_confpun(i, :) = alldat.zmean_data.alc_hi_confpunmean;
    end


end
   p = char(phase);
    folderName = strcat(tankfolder,'\',phase);
        save([folderName '\Conflict 02 ' p ' zMean all rats.mat'], 'collated')