%% Nathan Marchant July 2024
% Written for the conflict task

%% define where the stuff is
clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\conf_(10-30)';
filePath = fullfile(tankfolder);
allDat = cell(1,1);
Rew_Trial = [];
Rew_Trial_Omit = [];
Pun_Trial = [];
Pun_Trial_Omit = [];
Conf_Trial = [];
Conf_Trial_F = [];
Conf_Trial_S = [];
Conf_Trial_Omit = [];
% Rat = {'R08','R07', 'R02','R03','R05','R06','R09','R10','R11','R12', 'R13','R14','R15','R16'};%Conflict 02ab
% Rat = {'R10','R11','R12','R13','R14','R15','R16'}; %Conflict 02b ONLY 'R09',
tmp = [];
All = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12','C13','C14','C15'};  
Early = {'C01','C02','C03','C04','C05','C06'};  
Late = {'C12','C13','C14','C15'}; %'C07','C08','C09','C10', (remove always 'C11', )
Post_Tests = {'C23', 'C24', 'C25', 'C26'};
% Test options are: Saline Alcohol_Low Alcohol_High
Test = {'Alcohol_High'};


% R18 and R21 should be removed based on inspection of the daily traces
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

rewardsignal_Rat = {'R09','R12','R14','R16','R20','R22','R24'};
punsignal_Rat = {'R17','R19','R23'};
nocuesignal_Rat = {'R10','R13','R15',};

lowconf_Rat = {'R24','R12','R15','R21','R20','R10','R22','R14'};
highconf_Rat = {'R17','R23','R09','R18','R16','R13','R19','R11'};

conf = {'C15','C16','C17'};

condition = 'Conf Late';
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
             elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 1 
                Rew_Trial = [Rew_Trial; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 0 
                Rew_Trial_Omit = [Rew_Trial_Omit; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 1 
                Pun_Trial = [Pun_Trial; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 0 
                Pun_Trial_Omit = [Pun_Trial_Omit; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 2 
                Conf_Trial = [Conf_Trial; sesdat.traces_z(j, 5:323)];
                 Conf_Trial_F = [Conf_Trial_F; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 3 
                Conf_Trial = [Conf_Trial; sesdat.traces_z(j, 5:323)];
                 Conf_Trial_S = [Conf_Trial_S; sesdat.traces_z(j, 5:323)];
             elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 0 
                Conf_Trial_Omit = [Conf_Trial_Omit; sesdat.traces_z(j, 5:323)];
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
 
    time = linspace(-10, 10, size(Rew_Trial, 2));
    Rew_Trial_completed = num2str(size(Rew_Trial,1));
    Rew_Trial_label = ['rewDS Trial - responded (', Rew_Trial_completed,')'];
    Rew_Trial_Omitted = num2str(size(Rew_Trial_Omit,1));
    Rew_Omit_Trial_label = ['rewDS Trial - omissions (', Rew_Trial_Omitted,')'];
    Pun_Trial_completed = num2str(size(Pun_Trial,1));
    Pun_Trial_label = ['punDS Trial - responded (', Pun_Trial_completed,')'];
    Pun_Trial_Omitted = num2str(size(Pun_Trial_Omit,1));
    Pun_Omit_Trial_label = ['punDS Trial - omissions (', Pun_Trial_Omitted,')'];
    Conf_Trial_completed = num2str(size(Conf_Trial,1));
    Conf_Trial_label = ['Conf Trial - responded (', Conf_Trial_completed,')'];
    Conf_Trial_completed_F = num2str(size(Conf_Trial_F,1));
    Conf_Trial_F_label = ['Conf Trial + food (', Conf_Trial_completed_F,')'];
    Conf_Trial_completed_S = num2str(size(Conf_Trial_S,1));
    Conf_Trial_S_label = ['Conf Trial + shock (', Conf_Trial_completed_S,')'];
    Conf_Trial_Omitted = num2str(size(Conf_Trial_Omit,1));
    Conf_Omit_Trial_label = ['Conf Trial - omissions (', Conf_Trial_Omitted,')'];

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Trial, 5000, 0.001);
btsrp.rew = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial, 1),2);
tmp = bootstrap_data(Rew_Trial_Omit, 5000, 0.001);
btsrp.rewOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Omit, 1),2);

tmp = bootstrap_data(Pun_Trial, 5000, 0.001);
btsrp.pun = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial, 1),2);
tmp = bootstrap_data(Pun_Trial_Omit, 5000, 0.001);
btsrp.punOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Omit, 1),2);

tmp = bootstrap_data(Conf_Trial, 5000, 0.001);
btsrp.conf = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial, 1),2);
tmp = bootstrap_data(Conf_Trial_F, 5000, 0.001);
btsrp.confF = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_F, 1),2);
tmp = bootstrap_data(Conf_Trial_S, 5000, 0.001);
btsrp.confS = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_S, 1),2);
tmp = bootstrap_data(Conf_Trial_Omit, 5000, 0.001);
btsrp.confOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Omit, 1),2);


% %permutation tests
[perm.rewC_rewO, ~] = permTest_array(Rew_Trial, Rew_Trial_Omit, 1000);
[perm.rewC_punC, ~] = permTest_array(Rew_Trial, Pun_Trial, 1000);
[perm.punC_punO, ~] = permTest_array(Pun_Trial, Pun_Trial_Omit, 1000);
[perm.confCF_confO, ~] = permTest_array(Conf_Trial_F, Conf_Trial_Omit, 1000);
[perm.rewC_confC, ~] = permTest_array(Rew_Trial, Conf_Trial, 1000);
[perm.punC_confC, ~] = permTest_array(Conf_Trial, Pun_Trial, 1000);

[perm.rewC_confCF, ~] = permTest_array(Rew_Trial, Conf_Trial_F, 1000);
[perm.punC_confCF, ~] = permTest_array(Conf_Trial_F, Pun_Trial, 1000);
% 
[perm.rewO_punO, ~] = permTest_array(Rew_Trial_Omit, Pun_Trial_Omit, 1000);
[perm.rewO_confO, ~] = permTest_array(Rew_Trial_Omit, Conf_Trial_Omit, 1000);
[perm.punO_confO, ~] = permTest_array(Conf_Trial_Omit, Pun_Trial_Omit, 1000);

[perm.confCF_confCS, ~] = permTest_array(Conf_Trial_F, Conf_Trial_S, 1000);
[perm.confCF_confO, ~] = permTest_array(Conf_Trial_F, Conf_Trial_Omit, 1000);
[perm.confO_confCS, ~] = permTest_array(Conf_Trial_Omit, Conf_Trial_S, 1000);

[perm.confC_confO, ~] = permTest_array(Conf_Trial, Conf_Trial_Omit, 1000);

%-----------------------------------------------------Plot Reward  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial, Rew_Trial_Omit};
labels = {Rew_Trial_label, Rew_Omit_Trial_label};
colors = {green, light_green};

boottests = {'rew', 'rewOmit'};
offsetsboot = [0, -0.1, -0.2, -0.3];
permtests = {'rewC_rewO'};
offsetsperm = -0.5;
 markersperm = {yellow, black2, black3};

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
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('rewDS Trials - ',s);  

%-----------------------------------------------------Plot Punish Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Pun_Trial, Pun_Trial_Omit};
labels = {Pun_Trial_label, Pun_Omit_Trial_label};
colors = {red, pink};

boottests = {'pun', 'punOmit'};
offsetsboot = [0, -0.1, -0.2, -0.3];
permtests = {'punC_punO'};
offsetsperm = [-0.5, -0.6, -0.7];
markersperm = {yellow, black2, black3};

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
title('punDS Trials - ',s);  

% %-----------------------------------------------------Plot Conflict Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Trial, Conf_Trial_Omit};
labels = {Conf_Trial_label, Conf_Omit_Trial_label};
colors = {green, light_green};

boottests = {'conf', 'confOmit'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confC_confO'};
offsetsperm = [-1.0, -1.1, -1.2];
markersperm = {yellow, black3, black4};

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
title('Conflict Trials - ',s);  


%-----------------------------------------------------Plot Reward v Punish  Completed Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial, Pun_Trial, Conf_Trial};
labels = {Rew_Trial_label, Pun_Trial_label, Conf_Trial_label};
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
title('Responded Trials - ',s);  

% %-----------------------------------------------------Plot Reward v Punish v conflict omitted Trials  -----------------------------------------------------------------------
% 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Omit, Pun_Trial_Omit, Conf_Trial_Omit};
labels = {Rew_Omit_Trial_label, Pun_Omit_Trial_label, Conf_Omit_Trial_label};
colors = {light_green, pink, light_orange};

boottests = {'rewOmit', 'punOmit', 'confOmit'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5];
permtests = {'rewO_punO','rewO_confO','punO_confO'};
offsetsperm = [-1.0, -1.1, -1.2];
markersperm = {black1, black2, black3};

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
title('Omissions - ',s);  