%% Nathan Marchant July 2024
% Written for the conflict task
% Collate zmean scores of multiple sessions into a single file per rat  
% Written for the conflict phase of the experiment

fclose all;
clear all;
close all;

%% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)\';
Rat = {'R10','R11','R12','R13','R14','R15','R16','R17','R18','R19','R20','R21','R22','R23', 'R24'};
Test = {'Saline','Alcohol_Low','Alcohol_High'};


%% variables to save
alldat.zmean_labels.sal_rew_labels = {};
alldat.zmean_data.sal_rew = [];
alldat.zmean_labels.sal_pun_labels = {};
alldat.zmean_data.sal_pun = [];
alldat.zmean_labels.sal_conf_labels = {};
alldat.zmean_data.sal_conf = [];
alldat.zmean_labels.alc_low_rew_labels = {};
alldat.zmean_data.alc_low_rew = [];
alldat.zmean_labels.alc_low_pun_labels = {};
alldat.zmean_data.alc_low_pun = [];
alldat.zmean_labels.alc_low_conf_labels = {};
alldat.zmean_data.alc_low_conf = [];
alldat.zmean_labels.alc_hi_rew_labels = {};
alldat.zmean_data.alc_hi_rew = [];
alldat.zmean_labels.alc_hi_pun_labels = {};
alldat.zmean_data.alc_hi_pun = [];
alldat.zmean_labels.alc_hi_conf_labels = {};
alldat.zmean_data.alc_hi_conf = [];


% Omissions - for trial based analysis
alldat.zmean_labels.sal_rewO_labels = {};
alldat.zmean_data.sal_rewO = [];
alldat.zmean_labels.sal_punO_labels = {};
alldat.zmean_data.sal_punO = [];
alldat.zmean_labels.sal_confO_labels = {};
alldat.zmean_data.sal_confO = [];
alldat.zmean_labels.alc_low_rewO_labels = {};
alldat.zmean_data.alc_low_rewO = [];
alldat.zmean_labels.alc_low_punO_labels = {};
alldat.zmean_data.alc_low_punO = [];
alldat.zmean_labels.alc_low_confO_labels = {};
alldat.zmean_data.alc_low_confO = [];
alldat.zmean_labels.alc_hi_rewO_labels = {};
alldat.zmean_data.alc_hi_rewO = [];
alldat.zmean_labels.alc_hi_punO_labels = {};
alldat.zmean_data.alc_hi_punO = [];
alldat.zmean_labels.alc_hi_confO_labels = {};
alldat.zmean_data.alc_hi_confO = [];


% For Responses
% alldat.zmean_labels.sal_confrew_labels = {};
% alldat.zmean_data.sal_confrew = [];
% alldat.zmean_labels.sal_confpun_labels = {};
% alldat.zmean_data.sal_confpun = [];
% alldat.zmean_labels.alc_hi_confrew_labels = {};
% alldat.zmean_data.alc_hi_confrew = [];
% alldat.zmean_labels.alc_hi_confpun_labels = {};
% alldat.zmean_data.alc_hi_confpun = [];
% alldat.zmean_labels.alc_low_confrew_labels = {};
% alldat.zmean_data.alc_low_confrew = [];
% alldat.zmean_labels.alc_low_confpun_labels = {};
% alldat.zmean_data.alc_low_confpun = [];


sal_rew_tot = 0;
sal_rew_press = 0;
sal_pun_tot = 0;
sal_pun_press = 0;
sal_conf_tot = 0;
sal_conf_press = 0;

alc_low_rew_tot = 0;
alc_low_rew_press = 0;
alc_low_pun_tot = 0;
alc_low_pun_press = 0;
alc_low_conf_tot = 0;
alc_low_conf_press = 0;

alc_hi_rew_tot = 0;
alc_hi_rew_press = 0;
alc_hi_pun_tot = 0;
alc_hi_pun_press = 0;
alc_hi_conf_tot = 0;
alc_hi_conf_press = 0;
alldat.responses.sal = [];
alldat.responses.alc_low = [];
alldat.responses.alc_hi = [];

%% load invidivual session sesdata
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for j = 1:length(Rat) %iterate through experiment folder
    for i = 1:length(files) %iterate through experiment folder
        names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors
        r = Rat{j};
        openrat = names{9};
        if strcmp(r,openrat)
            load(fullfile(filePath, [files(i).name]))
            session = sesdat.ses;
            % _______________________ Saline sessions ______________________________
            if strcmp(session,Test{1})

                % Collate values for REWARD trials
                %responded
                if ~isempty(sesdat.zmean.collated_sal_rew_labels)
                    alldat.zmean_labels.sal_rew_labels = [alldat.zmean_labels.sal_rew_labels; sesdat.zmean.collated_sal_rew_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_rew)
                    alldat.zmean_data.sal_rew = [alldat.zmean_data.sal_rew; sesdat.zmean.collated_sal_rew];
                end
                %omissions
                if ~isempty(sesdat.zmean.collated_sal_rewO_labels)
                    alldat.zmean_labels.sal_rewO_labels = [alldat.zmean_labels.sal_rewO_labels; sesdat.zmean.collated_sal_rewO_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_rew)
                    alldat.zmean_data.sal_rewO = [alldat.zmean_data.sal_rewO; sesdat.zmean.collated_sal_rewO];
                end

                % Collate values for PUNISH trials
                %responses
                if ~isempty(sesdat.zmean.collated_sal_pun_labels)
                    alldat.zmean_labels.sal_pun_labels = [alldat.zmean_labels.sal_pun_labels; sesdat.zmean.collated_sal_pun_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_pun)
                    alldat.zmean_data.sal_pun = [alldat.zmean_data.sal_pun; sesdat.zmean.collated_sal_pun];
                end
                %omissions
                if ~isempty(sesdat.zmean.collated_sal_punO_labels)
                    alldat.zmean_labels.sal_punO_labels = [alldat.zmean_labels.sal_punO_labels; sesdat.zmean.collated_sal_punO_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_punO)
                    alldat.zmean_data.sal_punO = [alldat.zmean_data.sal_punO; sesdat.zmean.collated_sal_punO];
                end

                % Collate values for CONFLICT RESPONSES
                % if ~isempty(sesdat.zmean.collated_sal_confrew_labels)
                %     alldat.zmean_labels.sal_confrew_labels = [alldat.zmean_labels.sal_confrew_labels; sesdat.zmean.collated_sal_confrew_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_sal_confrew)
                %     alldat.zmean_data.sal_confrew = [alldat.zmean_data.sal_confrew; sesdat.zmean.collated_sal_confrew];
                % end
                % 
                % if ~isempty(sesdat.zmean.collated_sal_confpun_labels)
                %     alldat.zmean_labels.sal_confpun_labels = [alldat.zmean_labels.sal_confpun_labels; sesdat.zmean.collated_sal_confpun_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_sal_confpun)
                %     alldat.zmean_data.sal_confpun = [alldat.zmean_data.sal_confpun; sesdat.zmean.collated_sal_confpun];
                % end
                
                % Collate values for CONFLICT trials        
                if ~isempty(sesdat.zmean.collated_sal_conf_labels)
                    alldat.zmean_labels.sal_conf_labels = [alldat.zmean_labels.sal_conf_labels; sesdat.zmean.collated_sal_conf_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_conf)
                    alldat.zmean_data.sal_conf = [alldat.zmean_data.sal_conf; sesdat.zmean.collated_sal_conf];
                end               
                                
                if ~isempty(sesdat.zmean.collated_sal_confO_labels)
                    alldat.zmean_labels.sal_confO_labels = [alldat.zmean_labels.sal_confO_labels; sesdat.zmean.collated_sal_confO_labels];
                end
                if ~isempty(sesdat.zmean.collated_sal_confO)
                    alldat.zmean_data.sal_confO = [alldat.zmean_data.sal_confO; sesdat.zmean.collated_sal_confO];
                end
                
                
                sal_rew_tot = sal_rew_tot + sesdat.responses(1,1);
                sal_rew_press = sal_rew_press + sesdat.responses(1,2);
                sal_pun_tot = sal_pun_tot + sesdat.responses(2,1);
                sal_pun_press = sal_pun_press + sesdat.responses(2,2);
                sal_conf_tot = sal_conf_tot + sesdat.responses(3,1);
                sal_conf_press = sal_conf_press + sesdat.responses(3,2);

                %% _______________________ Alc Low sessions ______________________________
            elseif strcmp(session,Test{2})
                % Collate values for REWARD trials
                if ~isempty(sesdat.zmean.collated_alc_low_rew_labels)
                    alldat.zmean_labels.alc_low_rew_labels = [alldat.zmean_labels.alc_low_rew_labels; sesdat.zmean.collated_alc_low_rew_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_rew)
                    alldat.zmean_data.alc_low_rew = [alldat.zmean_data.alc_low_rew; sesdat.zmean.collated_alc_low_rew];
                end

                if ~isempty(sesdat.zmean.collated_alc_low_rewO_labels)
                    alldat.zmean_labels.alc_low_rewO_labels = [alldat.zmean_labels.alc_low_rewO_labels; sesdat.zmean.collated_alc_low_rewO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_rewO)
                    alldat.zmean_data.alc_low_rewO = [alldat.zmean_data.alc_low_rewO; sesdat.zmean.collated_alc_low_rewO];
                end

                % Collate values for PUNISH trials
                if ~isempty(sesdat.zmean.collated_alc_low_pun_labels)
                    alldat.zmean_labels.alc_low_pun_labels = [alldat.zmean_labels.alc_low_pun_labels; sesdat.zmean.collated_alc_low_pun_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_pun)
                    alldat.zmean_data.alc_low_pun = [alldat.zmean_data.alc_low_pun; sesdat.zmean.collated_alc_low_pun];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_punO_labels)
                    alldat.zmean_labels.alc_low_punO_labels = [alldat.zmean_labels.alc_low_punO_labels; sesdat.zmean.collated_alc_low_punO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_punO)
                    alldat.zmean_data.alc_low_punO = [alldat.zmean_data.alc_low_punO; sesdat.zmean.collated_alc_low_punO];
                end

                % Collate values for CONFLICT trials
                % 
                if ~isempty(sesdat.zmean.collated_alc_low_conf_labels)
                    alldat.zmean_labels.alc_low_conf_labels = [alldat.zmean_labels.alc_low_conf_labels; sesdat.zmean.collated_alc_low_conf_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_conf)
                    alldat.zmean_data.alc_low_conf = [alldat.zmean_data.alc_low_conf; sesdat.zmean.collated_alc_low_conf];
                end
                
                % Collate values for CONFLICT RESPONSES
                % if ~isempty(sesdat.zmean.collated_alc_low_confrew_labels)
                %     alldat.zmean_labels.alc_low_confrew_labels = [alldat.zmean_labels.alc_low_confrew_labels; sesdat.zmean.collated_alc_low_confrew_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_alc_low_confrew)
                %     alldat.zmean_data.alc_low_confrew = [alldat.zmean_data.alc_low_confrew; sesdat.zmean.collated_alc_low_confrew];
                % end
                % 
                % if ~isempty(sesdat.zmean.collated_alc_low_confpun_labels)
                %     alldat.zmean_labels.alc_low_confpun_labels = [alldat.zmean_labels.alc_low_confpun_labels; sesdat.zmean.collated_alc_low_confpun_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_alc_low_confpun)
                %     alldat.zmean_data.alc_low_confpun = [alldat.zmean_data.alc_low_confpun; sesdat.zmean.collated_alc_low_confpun];
                % end
                if ~isempty(sesdat.zmean.collated_alc_low_confO_labels)
                    alldat.zmean_labels.alc_low_confO_labels = [alldat.zmean_labels.alc_low_confO_labels; sesdat.zmean.collated_alc_low_confO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_low_confO)
                    alldat.zmean_data.alc_low_confO = [alldat.zmean_data.alc_low_confO; sesdat.zmean.collated_alc_low_confO];
                end
                alc_low_rew_tot = alc_low_rew_tot + sesdat.responses(1,1);
                alc_low_rew_press = alc_low_rew_press + sesdat.responses(1,2);
                alc_low_pun_tot = alc_low_pun_tot + sesdat.responses(2,1);
                alc_low_pun_press = alc_low_pun_press + sesdat.responses(2,2);
                alc_low_conf_tot = alc_low_conf_tot + sesdat.responses(3,1);
                alc_low_conf_press = alc_low_conf_press + sesdat.responses(3,2);

                %% _______________________ Alc High sessions ______________________________

            elseif strcmp(session,Test{3})
                % Collate values for REWARD trials
                if ~isempty(sesdat.zmean.collated_alc_hi_rew_labels)
                    alldat.zmean_labels.alc_hi_rew_labels = [alldat.zmean_labels.alc_hi_rew_labels; sesdat.zmean.collated_alc_hi_rew_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_rew)
                    alldat.zmean_data.alc_hi_rew = [alldat.zmean_data.alc_hi_rew; sesdat.zmean.collated_alc_hi_rew];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_rewO_labels)
                    alldat.zmean_labels.alc_hi_rewO_labels = [alldat.zmean_labels.alc_hi_rewO_labels; sesdat.zmean.collated_alc_hi_rewO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_rewO)
                    alldat.zmean_data.alc_hi_rewO = [alldat.zmean_data.alc_hi_rewO; sesdat.zmean.collated_alc_hi_rewO];
                end

                % Collate values for PUNISH trials
                if ~isempty(sesdat.zmean.collated_alc_hi_pun_labels)
                    alldat.zmean_labels.alc_hi_pun_labels = [alldat.zmean_labels.alc_hi_pun_labels; sesdat.zmean.collated_alc_hi_pun_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_pun)
                    alldat.zmean_data.alc_hi_pun = [alldat.zmean_data.alc_hi_pun; sesdat.zmean.collated_alc_hi_pun];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_punO_labels)
                    alldat.zmean_labels.alc_hi_punO_labels = [alldat.zmean_labels.alc_hi_punO_labels; sesdat.zmean.collated_alc_hi_punO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_punO)
                    alldat.zmean_data.alc_hi_punO = [alldat.zmean_data.alc_hi_punO; sesdat.zmean.collated_alc_hi_punO];
                end

                % Collate values for CONFLICT trials
                if ~isempty(sesdat.zmean.collated_alc_hi_conf_labels)
                    alldat.zmean_labels.alc_hi_conf_labels = [alldat.zmean_labels.alc_hi_conf_labels; sesdat.zmean.collated_alc_hi_conf_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_conf)
                    alldat.zmean_data.alc_hi_conf = [alldat.zmean_data.alc_hi_conf; sesdat.zmean.collated_alc_hi_conf];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_confO_labels)
                    alldat.zmean_labels.alc_hi_confO_labels = [alldat.zmean_labels.alc_hi_confO_labels; sesdat.zmean.collated_alc_hi_confO_labels];
                end
                if ~isempty(sesdat.zmean.collated_alc_hi_confO)
                    alldat.zmean_data.alc_hi_confO = [alldat.zmean_data.alc_hi_confO; sesdat.zmean.collated_alc_hi_confO];
                end

                % Collate values for CONFLICT RESPONSES
                % if ~isempty(sesdat.zmean.collated_alc_hi_confrew_labels)
                %     alldat.zmean_labels.alc_hi_confrew_labels = [alldat.zmean_labels.alc_hi_confrew_labels; sesdat.zmean.collated_alc_hi_confrew_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_alc_hi_confrew)
                %     alldat.zmean_data.alc_hi_confrew = [alldat.zmean_data.alc_hi_confrew; sesdat.zmean.collated_alc_hi_confrew];
                % end
                % 
                % if ~isempty(sesdat.zmean.collated_alc_hi_confpun_labels)
                %     alldat.zmean_labels.alc_hi_confpun_labels = [alldat.zmean_labels.alc_hi_confpun_labels; sesdat.zmean.collated_alc_hi_confpun_labels];
                % end
                % if ~isempty(sesdat.zmean.collated_alc_hi_confpun)
                %     alldat.zmean_data.alc_hi_confpun = [alldat.zmean_data.alc_hi_confpun; sesdat.zmean.collated_alc_hi_confpun];
                % end


                alc_hi_rew_tot = alc_hi_rew_tot + sesdat.responses(1,1);
                alc_hi_rew_press = alc_hi_rew_press + sesdat.responses(1,2);
                alc_hi_pun_tot = alc_hi_pun_tot + sesdat.responses(2,1);
                alc_hi_pun_press = alc_hi_pun_press + sesdat.responses(2,2);
                alc_hi_conf_tot = alc_hi_conf_tot + sesdat.responses(3,1);
                alc_hi_conf_press = alc_hi_conf_press + sesdat.responses(3,2);
            else
            end
        end
    end


%% ___________Put it all together_______________________________________
alldat.zmean_data.sal_rewCmean = mean(alldat.zmean_data.sal_rew,1);
alldat.zmean_data.sal_punCmean = mean(alldat.zmean_data.sal_pun,1);
alldat.zmean_data.sal_confCmean = mean(alldat.zmean_data.sal_conf,1);

alldat.zmean_data.alc_low_rewCmean = mean(alldat.zmean_data.alc_low_rew,1);
alldat.zmean_data.alc_low_punCmean = mean(alldat.zmean_data.alc_low_pun,1);
alldat.zmean_data.alc_low_confCmean = mean(alldat.zmean_data.alc_low_conf,1);

alldat.zmean_data.alc_hi_rewCmean = mean(alldat.zmean_data.alc_hi_rew,1);
alldat.zmean_data.alc_hi_punCmean = mean(alldat.zmean_data.alc_hi_pun,1);
alldat.zmean_data.alc_hi_confCmean = mean(alldat.zmean_data.alc_hi_conf,1);


%Omissions
alldat.zmean_data.sal_rewOmean = mean(alldat.zmean_data.sal_rewO,1);
alldat.zmean_data.sal_punOmean = mean(alldat.zmean_data.sal_punO,1);
alldat.zmean_data.sal_confOmean = mean(alldat.zmean_data.sal_confO,1);
alldat.zmean_data.alc_low_rewOmean = mean(alldat.zmean_data.alc_low_rewO,1);
alldat.zmean_data.alc_low_punOmean = mean(alldat.zmean_data.alc_low_punO,1);
alldat.zmean_data.alc_low_confOmean = mean(alldat.zmean_data.alc_low_confO,1);
alldat.zmean_data.alc_hi_rewOmean = mean(alldat.zmean_data.alc_hi_rewO,1);
alldat.zmean_data.alc_hi_punOmean = mean(alldat.zmean_data.alc_hi_punO,1);
alldat.zmean_data.alc_hi_confOmean = mean(alldat.zmean_data.alc_hi_confO,1);



%% ___________Code responses info_______________________________________
sal_rew_percent = (sal_rew_press/sal_rew_tot);
sal_pun_percent = (sal_pun_press/sal_pun_tot);
sal_conf_percent = (sal_conf_press/sal_conf_tot);
alldat.responses.sal = [sal_rew_tot sal_rew_press sal_rew_percent
                       sal_pun_tot sal_pun_press sal_pun_percent
                       sal_conf_tot sal_conf_press sal_conf_percent];

alc_low_rew_percent = (alc_low_rew_press/alc_low_rew_tot);
alc_low_pun_percent = (alc_low_pun_press/alc_low_pun_tot);
alc_low_conf_percent = (alc_low_conf_press/alc_low_conf_tot);
alldat.responses.alc_low = [alc_low_rew_tot alc_low_rew_press alc_low_rew_percent
                       alc_low_pun_tot alc_low_pun_press alc_low_pun_percent
                       alc_low_conf_tot alc_low_conf_press alc_low_conf_percent];

alc_hi_rew_percent = (alc_hi_rew_press/alc_hi_rew_tot);
alc_hi_pun_percent = (alc_hi_pun_press/alc_hi_pun_tot);
alc_hi_conf_percent = (alc_hi_conf_press/alc_hi_conf_tot);
alldat.responses.alc_hi = [alc_hi_rew_tot alc_hi_rew_press alc_hi_rew_percent
                       alc_hi_pun_tot alc_hi_pun_press alc_hi_pun_percent
                       alc_hi_conf_tot alc_hi_conf_press alc_hi_conf_percent];


%% ___________SAVE FILE_______________________________________
folderName = strcat(tankfolder,'\Alc_Tests Collated');
r = char(Rat(j));

if ~isfolder(folderName)  % Check if the folder does not exist
    mkdir(folderName);  % Create the folder
    save([folderName '\Conflict 02 alc_tests zmean combined ', r '.mat'], 'alldat');
else
    save([folderName '\Conflict 02 alc_tests zmean combined ', r '.mat'], 'alldat');
end
%% variables to reset between rats
alldat.zmean_labels.sal_rew_labels = {};
alldat.zmean_data.sal_rew = [];
alldat.zmean_labels.sal_pun_labels = {};
alldat.zmean_data.sal_pun = [];
alldat.zmean_labels.sal_conf_labels = {};
alldat.zmean_data.sal_conf = [];
alldat.zmean_labels.sal_rewO_labels = {};
alldat.zmean_data.sal_rewO = [];
alldat.zmean_labels.sal_punO_labels = {};
alldat.zmean_data.sal_punO = [];
alldat.zmean_labels.sal_confO_labels = {};
alldat.zmean_data.sal_confO = [];
alldat.zmean_labels.sal_confrew_labels = {};
alldat.zmean_data.sal_confrew = [];
alldat.zmean_labels.sal_confpun_labels = {};
alldat.zmean_data.sal_confpun = [];


alldat.zmean_labels.alc_low_rew_labels = {};
alldat.zmean_data.alc_low_rew = [];
alldat.zmean_labels.alc_low_pun_labels = {};
alldat.zmean_data.alc_low_pun = [];
alldat.zmean_labels.alc_low_conf_labels = {};
alldat.zmean_data.alc_low_conf = [];
alldat.zmean_labels.alc_low_rewO_labels = {};
alldat.zmean_data.alc_low_rewO = [];
alldat.zmean_labels.alc_low_punO_labels = {};
alldat.zmean_data.alc_low_punO = [];
alldat.zmean_labels.alc_low_confO_labels = {};
alldat.zmean_data.alc_low_confO = [];
alldat.zmean_labels.alc_low_confrew_labels = {};
alldat.zmean_data.alc_low_confrew = [];
alldat.zmean_labels.alc_low_confpun_labels = {};
alldat.zmean_data.alc_low_confpun = [];



alldat.zmean_labels.alc_hi_rew_labels = {};
alldat.zmean_data.alc_hi_rew = [];
alldat.zmean_labels.alc_hi_pun_labels = {};
alldat.zmean_data.alc_hi_pun = [];
alldat.zmean_labels.alc_hi_conf_labels = {};
alldat.zmean_data.alc_hi_conf = [];
alldat.zmean_labels.alc_hi_rewO_labels = {};
alldat.zmean_data.alc_hi_rewO = [];
alldat.zmean_labels.alc_hi_punO_labels = {};
alldat.zmean_data.alc_hi_punO = [];
alldat.zmean_labels.alc_hi_confO_labels = {};
alldat.zmean_data.alc_hi_confO = [];
alldat.zmean_labels.alc_hi_confrew_labels = {};
alldat.zmean_data.alc_hi_confrew = [];
alldat.zmean_labels.alc_hi_confpun_labels = {};
alldat.zmean_data.alc_hi_confpun = [];

sal_rew_tot = 0;
sal_rew_press = 0;
sal_pun_tot = 0;
sal_pun_press = 0;
sal_conf_tot = 0;
sal_conf_press = 0;

alc_low_rew_tot = 0;
alc_low_rew_press = 0;
alc_low_pun_tot = 0;
alc_low_pun_press = 0;
alc_low_conf_tot = 0;
alc_low_conf_press = 0;

alc_hi_rew_tot = 0;
alc_hi_rew_press = 0;
alc_hi_pun_tot = 0;
alc_hi_pun_press = 0;
alc_hi_conf_tot = 0;
alc_hi_conf_press = 0;
alldat.responses.sal = [];
alldat.responses.alc_low = [];
alldat.responses.alc_hi = [];

end
