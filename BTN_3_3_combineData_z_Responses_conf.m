%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(25-15)';
filePath = fullfile(tankfolder);
allDat = cell(1,1);
Rew_Resp = [];
Pun_Resp = [];
Conf_Resp = [];
Conf_Resp_F = [];
Conf_Resp_S = [];

tmp = [];

%Remove rats if they should be excluded for some reason
% R18 and R21 should be removed based on lack of reliable signal 'R18','R21',
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};


Post_Tests = {'C23', 'C24', 'C25', 'C26'};
% Test options are: Saline Alcohol_Low Alcohol_High
Test = {'Alcohol_High'};


rewardsignal_Rat = {'R09','R12','R14','R16','R20','R22','R24'};
punsignal_Rat = {'R17','R19','R23'};
nocuesignal_Rat = {'R10','R13','R15','R18','R21'};

lowconf_Rat = {'R24','R12','R15','R21','R20','R10','R22','R14'};
highconf_Rat = {'R17','R23','R09','R18','R16','R13','R19','R11'};


conf_all = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C12','C13','C14','C15'};  %Remove ,'C11'

condition = 'Conf Early';
s=char(condition);
if strcmp(condition,'Conf Early')
    included_sessions = {'C01','C02','C03','C04'};  
else
    included_sessions = {'C12','C13','C14','C15'}; 
end

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder

        load(fullfile(filePath,  [files(i).name]))
        names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors
        Condition = sesdat.phase;
        % side = sesdat.hemi;
        rat = sesdat.rat;
        session = sesdat.ses;
        % conf_percent = dat.sesdat.responses(3,3);
    if any(strcmp(session, included_sessions)) && ismember(rat,Rat) 
        for j = 1:size(sesdat.traces_z, 1)
             if isnan(sesdat.traces_z(j,5))
             elseif sesdat.traces_z(j, 2) == 5 && sesdat.traces_z(j, 4) == 1 
                Rew_Resp = [Rew_Resp; sesdat.traces_z(j, 5:end)];
             elseif sesdat.traces_z(j, 2) == 6 && sesdat.traces_z(j, 4) == 2 
                Pun_Resp = [Pun_Resp; sesdat.traces_z(j, 5:end)];
             elseif sesdat.traces_z(j, 2) == 5 && sesdat.traces_z(j, 4) == 3 
                Conf_Resp = [Conf_Resp; sesdat.traces_z(j, 5:end)];
                 Conf_Resp_F = [Conf_Resp_F; sesdat.traces_z(j, 5:end)];
             elseif sesdat.traces_z(j, 2) == 6 && sesdat.traces_z(j, 4) == 3 
                Conf_Resp = [Conf_Resp; sesdat.traces_z(j, 5:end)];
                 Conf_Resp_S = [Conf_Resp_S; sesdat.traces_z(j, 5:end)];
             end
        end
    end
end


 %% 
 %___________ colours used for the plots (RGB values / 255)______________
    purp = [0.36,0.32,0.64];
    blue = [0.00,0.26,1.00];
    azure = [0.00,0.62,1.00];
    red = [1.0,0,0];
    pink = [1.00,0.50,0.50];
    orange = [1.00,0.45,0.00];
    light_orange = [1.00,0.87,0.60];
    green = [0.10,0.60,0.00];
    light_green = [0.00,0.50,0.50];
    yellow = [1.00,0.88,0.00];
    black1 = [0.75,0.75,0.75];
    black2 = [0.5,0.5,0.5];
    black3 = [0.25,0.25,0.25];
    black4 = [0,0,0];

%___________ Dimensions and labels used for the plots ______________
 
    time = linspace(-25, 15, size(Rew_Resp, 2));
    Rew_Resp_completed = num2str(size(Rew_Resp,1));
    Rew_Resp_label = ['rewDS Trial - responded (', Rew_Resp_completed,')'];
    Pun_Resp_completed = num2str(size(Pun_Resp,1));
    Pun_Resp_label = ['punDS Trial - responded (', Pun_Resp_completed,')'];
    Conf_Resp_completed = num2str(size(Conf_Resp,1));
    Conf_Resp_label = ['Conf Trial - responded (', Conf_Resp_completed,')'];
    Conf_Resp_completed_F = num2str(size(Conf_Resp_F,1));
    Conf_Resp_F_label = ['Conf Trial - responded + food (', Conf_Resp_completed_F,')'];
    Conf_Resp_completed_S = num2str(size(Conf_Resp_S,1));
    Conf_Resp_S_label = ['Conf Trial - responded + shock (', Conf_Resp_completed_S,')'];
    

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Resp, 5000, 0.001);
btsrp.rew = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Resp, 1),2);

tmp = bootstrap_data(Pun_Resp, 5000, 0.001);
btsrp.pun = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Resp, 1),2);

tmp = bootstrap_data(Conf_Resp, 5000, 0.001);
btsrp.conf = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp, 1),2);
tmp = bootstrap_data(Conf_Resp_F, 5000, 0.001);
btsrp.confF = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_F, 1),2);
tmp = bootstrap_data(Conf_Resp_S, 5000, 0.001);
btsrp.confS = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_S, 1),2);

% %permutation tests
[perm.rewC_punC, ~] = permTest_array(Rew_Resp, Pun_Resp, 1000);
[perm.rewC_confC, ~] = permTest_array(Rew_Resp, Conf_Resp, 1000);
[perm.punC_confC, ~] = permTest_array(Conf_Resp, Pun_Resp, 1000);

[perm.rewC_confCF, ~] = permTest_array(Rew_Resp, Conf_Resp_F, 1000);
[perm.punC_confCS, ~] = permTest_array(Conf_Resp_S, Pun_Resp, 1000);
% 

[perm.confCF_confCS, ~] = permTest_array(Conf_Resp_F, Conf_Resp_S, 1000);

% %-----------------------------------------------------Plot Conflict Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Resp_F, Conf_Resp_S};
labels = {Conf_Resp_F_label, Conf_Resp_S_label};
colors = {orange, light_orange};

boottests = {'confF', 'confS'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confCF_confCS'};
offsetsperm = [-1.0, -1.1, -1.2];
markersperm = {yellow};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels, 'Location', 'northwest'); % Provide only the handles for mean lines
ax = gca;
yLimits = ax.YLim;
yMin = yLimits(1);

% Plotting markers for bootstrapping
for i = 1:2:length(boottests)*2
    tmp = find(btsrp.(boottests{(i+1)/2})(1,:) > 0);   % Find indices for values > 0 (i.e. signal higher than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');

    clear tmp id
    tmp = find(btsrp.(boottests{(i+1)/2})(2,:) < 0); % Find indices for values < 0 (i.e. signal lower than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i+1) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
end

% Plotting permutation tests
for i = 1:length(permtests)
    tmp = find(perm.(permtests{i})(1, :) < p);
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
end

% Adding zero reference lines and title
yLimits = ax.YLim;
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Conflict Responses');  


%-----------------------------------------------------Plot Reward v Punish  Completed Responses  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Resp, Pun_Resp, Conf_Resp};
labels = {Rew_Resp_label, Pun_Resp_label, Conf_Resp_label};
colors = {green, red, orange};

boottests = {'rew', 'pun', 'conf'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewC_punC','rewC_confC','punC_confC'};
offsetsperm = [-1.0, -1.1, -1.2, -1.3];
markersperm = {black1, black2, black3, black4};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels, 'Location', 'northwest'); % Provide only the handles for mean lines
ax = gca;
yLimits = ax.YLim;
yMin = yLimits(1);

% Plotting markers for bootstrapping
for i = 1:2:length(boottests)*2
    tmp = find(btsrp.(boottests{(i+1)/2})(1,:) > 0);   % Find indices for values > 0 (i.e. signal higher than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');

    clear tmp id
    tmp = find(btsrp.(boottests{(i+1)/2})(2,:) < 0); % Find indices for values < 0 (i.e. signal lower than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i+1) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
end

% Plotting permutation tests
for i = 1:length(permtests)
    tmp = find(perm.(permtests{i})(1, :) < p);
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
end

% Adding zero reference lines and title
yLimits = ax.YLim;
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(s,' - Responses');  

%-----------------------------------------------------Plot Reward v Punish  v Conflict (split) Completed Responses  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Resp, Pun_Resp, Conf_Resp_F, Conf_Resp_S};
labels = {Rew_Resp_label, Pun_Resp_label, Conf_Resp_F_label, Conf_Resp_S_label};
colors = {green, red, blue, azure};

boottests = {'rew', 'pun', 'confF', 'confS'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewC_confCF','punC_confCS','confCF_confCS'};
offsetsperm = [-1.0, -1.2, -1.4, -1.6];
markersperm = {black1, black2, black3, black4};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels, 'Location', 'northwest'); % Provide only the handles for mean lines
ax = gca;
yLimits = ax.YLim;
yMin = yLimits(1);

% Plotting markers for bootstrapping
for i = 1:2:length(boottests)*2
    tmp = find(btsrp.(boottests{(i+1)/2})(1,:) > 0);   % Find indices for values > 0 (i.e. signal higher than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');

    clear tmp id
    tmp = find(btsrp.(boottests{(i+1)/2})(2,:) < 0); % Find indices for values < 0 (i.e. signal lower than baseline)
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsboot(i+1) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
end

% Plotting permutation tests
for i = 1:length(permtests)
    tmp = find(perm.(permtests{i})(1, :) < p);
    id = tmp(consec_idx(tmp, thres));
    plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
end

% Adding zero reference lines and title
yLimits = ax.YLim;
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(s,' - Responses');  
