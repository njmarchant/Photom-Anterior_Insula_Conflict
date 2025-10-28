%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(25-15)';
filePath = fullfile(tankfolder);

Rew_Resp_E = [];
Pun_Resp_E = [];
Conf_Resp_E = [];
Conf_Resp_F_E = [];
Conf_Resp_S_E = [];

Rew_Resp_L = [];
Pun_Resp_L = [];
Conf_Resp_L = [];
Conf_Resp_F_L = [];
Conf_Resp_S_L = [];

tmp = [];

%Remove rats if they should be excluded for some reason
% R18 and R21 should be removed based on lack of reliable signal 'R18','R21', 
% 'R09' removed, dead
Rat = {'R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};


Post_Tests = {'C23', 'C24', 'C25', 'C26'};

rewardsignal_Rat = {'R09','R12','R14','R16','R20','R22','R24'};
punsignal_Rat = {'R17','R19','R23'};
nocuesignal_Rat = {'R10','R13','R15','R18','R21'};

lowconf_Rat = {'R24','R12','R15','R21','R20','R10','R22','R14'};
highconf_Rat = {'R17','R23','R09','R18','R16','R13','R19','R11'};

conf = {'C15','C16','C17'};

conf_all = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C12','C13','C14','C15'};  %Remove ,'C11'
conf_early = {'C01','C02','C03','C04'};  
conf_late = {'C12','C13','C14','C15'};  

Test = {'Saline','Alcohol_High','Alcohol_Low'};
Alc_test = {'Alcohol_High'};
t = strrep(char(Alc_test), '_', '\_');


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
        is_saline_and_rat = strcmp(session, 'Saline') & ismember(rat, Rat);
        is_alc_test_and_rat = strcmp(session, Alc_test) & ismember(rat, Rat);
        is_valid_row = ~isnan(sesdat.traces_z(:, 5)) & sesdat.traces_z(:, 1) >= 900;
        
        Rew_Resp_E = [Rew_Resp_E; sesdat.traces_z(is_saline_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 5 & sesdat.traces_z(:, 4) == 1, 5:end)];
        Pun_Resp_E = [Pun_Resp_E; sesdat.traces_z(is_saline_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 6 & sesdat.traces_z(:, 4) == 2, 5:end)];
        Conf_Resp_E = [Conf_Resp_E; sesdat.traces_z(is_saline_and_rat & is_valid_row & sesdat.traces_z(:, 2) >= 5  & sesdat.traces_z(:, 4) == 3, 5:end)];
        Conf_Resp_F_E = [Conf_Resp_F_E; sesdat.traces_z(is_saline_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 5 & sesdat.traces_z(:, 4) == 3, 5:end)];
        Conf_Resp_S_E = [Conf_Resp_S_E; sesdat.traces_z(is_saline_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 6 & sesdat.traces_z(:, 4) == 3, 5:end)];

        Rew_Resp_L = [Rew_Resp_L; sesdat.traces_z(is_alc_test_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 5 & sesdat.traces_z(:, 4) == 1, 5:end)];
        Pun_Resp_L = [Pun_Resp_L; sesdat.traces_z(is_alc_test_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 6 & sesdat.traces_z(:, 4) == 2, 5:end)];
        Conf_Resp_L = [Conf_Resp_L; sesdat.traces_z(is_alc_test_and_rat & is_valid_row & sesdat.traces_z(:, 2) >= 5  & sesdat.traces_z(:, 4) == 3, 5:end)];
        Conf_Resp_F_L = [Conf_Resp_F_L; sesdat.traces_z(is_alc_test_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 5 & sesdat.traces_z(:, 4) == 3, 5:end)];
        Conf_Resp_S_L = [Conf_Resp_S_L; sesdat.traces_z(is_alc_test_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 6 & sesdat.traces_z(:, 4) == 3, 5:end)];
  
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
 
    time = linspace(-25, 15, size(Rew_Resp_E, 2));
    Rew_Resp_E_completed = num2str(size(Rew_Resp_E,1));
    Rew_Resp_E_label = ['Saline Reward (', Rew_Resp_E_completed,')'];
    Pun_Resp_E_completed = num2str(size(Pun_Resp_E,1));
    Pun_Resp_E_label = ['Saline Punish (', Pun_Resp_E_completed,')'];
    Conf_Resp_E_completed = num2str(size(Conf_Resp_E,1));
    Conf_Resp_E_label = ['Saline Conf (', Conf_Resp_E_completed,')'];
    Conf_Resp_E_completed_F = num2str(size(Conf_Resp_F_E,1));
    Conf_Resp_E_F_label = ['Saline Conf + food (', Conf_Resp_E_completed_F,')'];
    Conf_Resp_E_completed_S = num2str(size(Conf_Resp_S_E,1));
    Conf_Resp_E_S_label = ['Saline Conf + shock (', Conf_Resp_E_completed_S,')'];

    Rew_Resp_L_completed = num2str(size(Rew_Resp_L,1));
    Rew_Resp_L_label = [t, ' Reward (', Rew_Resp_L_completed,')'];
    Pun_Resp_L_completed = num2str(size(Pun_Resp_L,1));
    Pun_Resp_L_label = [t, ' Punish (', Pun_Resp_L_completed,')'];
    Conf_Resp_L_completed = num2str(size(Conf_Resp_L,1));
    Conf_Resp_L_label = [t, ' Conf (', Conf_Resp_L_completed,')'];
    Conf_Resp_L_completed_F = num2str(size(Conf_Resp_F_L,1));
    Conf_Resp_L_F_label = [t, ' Conf + food (', Conf_Resp_L_completed_F,')'];
    Conf_Resp_L_completed_S = num2str(size(Conf_Resp_S_L,1));
    Conf_Resp_L_S_label = [t, ' Conf + shock (', Conf_Resp_L_completed_S,')'];
    

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Resp_E, 5000, 0.001);
btsrp.rewE = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Resp_E, 1),2);
tmp = bootstrap_data(Pun_Resp_E, 5000, 0.001);
btsrp.punE = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Resp_E, 1),2);

tmp = bootstrap_data(Conf_Resp_E, 5000, 0.001);
btsrp.confE = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_E, 1),2);
tmp = bootstrap_data(Conf_Resp_F_E, 5000, 0.001);
btsrp.confFE = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_F_E, 1),2);
tmp = bootstrap_data(Conf_Resp_S_E, 5000, 0.001);
btsrp.confSE = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_S_E, 1),2);

tmp = bootstrap_data(Rew_Resp_L, 5000, 0.001);
btsrp.rewL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Resp_L, 1),2);
tmp = bootstrap_data(Pun_Resp_L, 5000, 0.001);
btsrp.punL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Resp_L, 1),2);

tmp = bootstrap_data(Conf_Resp_L, 5000, 0.001);
btsrp.confL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_L, 1),2);
tmp = bootstrap_data(Conf_Resp_F_L, 5000, 0.001);
btsrp.confFL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_F_L, 1),2);
tmp = bootstrap_data(Conf_Resp_S_L, 5000, 0.001);
btsrp.confSL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Resp_S_L, 1),2);


% %permutation tests
[perm.rewE_rewL, ~] = permTest_array(Rew_Resp_E, Rew_Resp_L, 1000);
[perm.punE_punL, ~] = permTest_array(Pun_Resp_E, Pun_Resp_L, 1000);

[perm.confE_confL, ~] = permTest_array(Conf_Resp_E, Conf_Resp_L, 1000);
[perm.confFE_confFL, ~] = permTest_array(Conf_Resp_F_E, Conf_Resp_F_L, 1000);
[perm.confSE_confSL, ~] = permTest_array(Conf_Resp_S_L, Conf_Resp_S_L, 1000);
% 



% %-----------------------------------------------------Conflict Saline v Alcohol -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Resp_E, Conf_Resp_L};
labels = {Conf_Resp_E_label, Conf_Resp_L_label};
colors = {green, orange};

boottests = {'confE', 'confL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confE_confL'};
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
title('Conflict Saline v ', t);  


%-----------------------------------------------------Plot Reward Saline v Alcohol -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Resp_E, Rew_Resp_L};
labels = {Rew_Resp_E_label, Rew_Resp_L_label};
colors = {blue, azure};

boottests = {'rewE', 'rewL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewE_rewL'};
offsetsperm = [-1.0, -1.1, -1.2, -1.3];
markersperm = {yellow, black2, black3, black4};

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
title('Reward Saline v ', t);  

%-----------------------------------------------------Plot Punish Saline v Alcohol -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Pun_Resp_E, Pun_Resp_L};
labels = {Pun_Resp_E_label, Pun_Resp_L_label};
colors = {red, orange};

boottests = {'punE', 'punL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'punE_punL'};
offsetsperm = [-1.0, -1.1, -1.2, -1.3];
markersperm = {yellow, black2, black3, black4};

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
title('Punish Saline v ', t);  

% %-----------------------------------------------------Conflict Food Saline v Alcohol -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Resp_F_E, Conf_Resp_F_L};
labels = {Conf_Resp_E_F_label, Conf_Resp_L_F_label};
colors = {green, light_green};

boottests = {'confFE', 'confFL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confFE_confFL'};
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
title('Conflict Food Saline v ', t);  

% %-----------------------------------------------------Conflict Shock Saline v Alcohol -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Resp_S_E, Conf_Resp_S_L};
labels = {Conf_Resp_E_S_label, Conf_Resp_L_S_label};
colors = {orange, light_orange};

boottests = {'confSE', 'confSL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confSE_confSL'};
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
title('Conflict Shock Saline v ', t);  

