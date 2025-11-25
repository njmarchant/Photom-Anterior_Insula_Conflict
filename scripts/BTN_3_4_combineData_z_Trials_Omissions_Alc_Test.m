%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)';
filePath = fullfile(tankfolder);
allDat = cell(1,1);
Rew_Trial_Saline = [];
Rew_Trial_Alc = [];
Rew_Trial_Saline_O = [];
Rew_Trial_Alc_O = [];
Pun_Trial_Saline = [];
Pun_Trial_Alc = [];
Pun_Trial_Saline_Omit = [];
Pun_Trial_Alc_Omit = [];
Conf_Alc_Trial = [];
Conf_Sal_Trial = [];
Conf_Saline_F = [];
Conf_Saline_S = [];
Conf_Alc_S = [];
Conf_Alc_F = [];
Conf_Alc_Trial_O = [];
Conf_Sal_Trial_O = [];

% R18 and R21 should be removed based on inspection of the daily traces
% R09 is excluded from the alcohol tests
%
Rat = {'R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23','R24'};

tmp = [];
latency.rewR_a = [];
latency.rewO_a = [];
latency.punR_a = [];
latency.punO_a = [];

latency.rewR_s = [];
latency.rewO_s = [];
latency.punR_s = [];
latency.punO_s = [];

Test = {'Saline','Alcohol_High','Alcohol_Low'};
Alc_test = {'Alcohol_High'};
t = strrep(char(Alc_test), '_', '\_');

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder

    load(fullfile(filePath,  [files(i).name]))
    side = sesdat.hemi;
    rat = sesdat.rat;
    session = sesdat.ses;
    if strcmp(session, 'Saline') && ismember(rat,Rat)
        for j = 1:size(sesdat.traces_z, 1)
            if isnan(sesdat.traces_z(j,5)) || sesdat.traces_z(j, 1) < 900
            elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 1
                Rew_Trial_Saline = [Rew_Trial_Saline; sesdat.traces_z(j, 5:end)];
                latency.rewR_s = [latency.rewR_s; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 0
                Rew_Trial_Saline_O = [Rew_Trial_Saline_O; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 1
                Pun_Trial_Saline = [Pun_Trial_Saline; sesdat.traces_z(j, 5:end)];
                latency.punR_s = [latency.punR_s; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 0
                Pun_Trial_Saline_Omit = [Pun_Trial_Saline_Omit; sesdat.traces_z(j, 5:end)];
                latency.punO_s = [latency.punO_s; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 2
                Conf_Saline_F = [Conf_Saline_F; sesdat.traces_z(j, 5:end)];
                Conf_Sal_Trial = [Conf_Sal_Trial; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 3
                Conf_Saline_S = [Conf_Saline_S; sesdat.traces_z(j, 5:end)];
                Conf_Sal_Trial = [Conf_Sal_Trial; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 0
                Conf_Sal_Trial_O = [Conf_Sal_Trial_O; sesdat.traces_z(j, 5:end)];
            end
        end
    end
    if strcmp(session, Alc_test) && ismember(rat,Rat)
        for j = 1:size(sesdat.traces_z, 1)
            if isnan(sesdat.traces_z(j,5)) || sesdat.traces_z(j, 1) < 900
            elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 1
                Rew_Trial_Alc = [Rew_Trial_Alc; sesdat.traces_z(j, 5:end)];
                latency.rewR_a = [latency.rewR_a; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 0
                Rew_Trial_Alc_O = [Rew_Trial_Alc_O; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 1
                Pun_Trial_Alc = [Pun_Trial_Alc; sesdat.traces_z(j, 5:end)];
                latency.punR_a = [latency.punR_a; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 2 && sesdat.traces_z(j, 4) == 0
                Pun_Trial_Alc_Omit = [Pun_Trial_Alc_Omit; sesdat.traces_z(j, 5:end)];
                latency.punO_a = [latency.punO_a; sesdat.traces_z(j, 3)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 2
                Conf_Alc_F = [Conf_Alc_F; sesdat.traces_z(j, 5:end)];
                Conf_Alc_Trial = [Conf_Alc_Trial; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 3
                Conf_Alc_S = [Conf_Alc_S; sesdat.traces_z(j, 5:end)];
                Conf_Alc_Trial = [Conf_Alc_Trial; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 3 && sesdat.traces_z(j, 4) == 0
                Conf_Alc_Trial_O = [Conf_Alc_Trial_O; sesdat.traces_z(j, 5:end)];
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
 
    time = linspace(-10, 45, size(Rew_Trial_Saline, 2));
    Rew_Sal = num2str(size(Rew_Trial_Saline,1));
    Rew_Sal_label = ['Saline RewDS (', Rew_Sal,')'];
    Rew_Alc = num2str(size(Rew_Trial_Alc,1));
    Rew_Alc_label = ['Alc RewDS (', Rew_Alc,')'];
    
    Rew_Sal_O = num2str(size(Rew_Trial_Saline_O,1));
    Rew_Sal_O_label = ['Saline RewDS Omit (', Rew_Sal_O,')'];
    Rew_Alc_O = num2str(size(Rew_Trial_Alc_O,1));
    Rew_Alc_O_label = ['Alc RewDS Omit (', Rew_Alc_O,')'];

    Pun_Sal = num2str(size(Pun_Trial_Saline,1));
    Pun_Sal_label = ['Saline PunDS (', Pun_Sal,')'];
    Pun_Alc = num2str(size(Pun_Trial_Alc,1));
    Pun_Alc_label = ['Alc PunDS (', Pun_Alc,')'];
    
    Pun_SalO = num2str(size(Pun_Trial_Saline_Omit,1));
    Pun_SalO_label = ['Saline PunDS Omit (', Pun_SalO,')'];
    Pun_AlcO = num2str(size(Pun_Trial_Alc_Omit,1));
    Pun_AlcO_label = ['Alc PunDS Omit (', Pun_AlcO,')'];
    
    Conf_Sal_F = num2str(size(Conf_Saline_F,1));
    Conf_Saline_F_label = ['Saline Conf food (', Conf_Sal_F,')'];
    Conf_Sal_S = num2str(size(Conf_Saline_S,1));
    Conf_Saline_S_label = ['Saline Conf shock (', Conf_Sal_S,')'];
    
    Conf_Alc_F_count = num2str(size(Conf_Alc_F,1));
    Conf_Alc_F_label = ['Alc Conf food (', Conf_Alc_F_count,')'];
    Conf_Alc_S_count = num2str(size(Conf_Alc_S,1));
    Conf_Alc_S_label = ['Alc Conf shock (', Conf_Alc_S_count,')'];

    Conf_Sal_Trial_count = num2str(size(Conf_Sal_Trial,1));
    Conf_Sal_label = ['Saline Conf (', Conf_Sal_Trial_count,')'];
    Conf_Alc_Trial_count = num2str(size(Conf_Alc_Trial,1));
    Conf_Alc_label = ['Alc Conf ALL (', Conf_Alc_Trial_count,')'];

    Conf_SalO = num2str(size(Conf_Sal_Trial_O,1));
    Conf_SalO_label = ['Saline Conf Omit (', Conf_SalO,')'];
    Conf_AlcO = num2str(size(Conf_Alc_Trial_O,1));
    Conf_AlcO_label = ['Alc Conf Omit (', Conf_AlcO,')'];


            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Trial_Saline, 5000, 0.001);
btsrp.rewSal = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Saline, 1),2);
tmp = bootstrap_data(Rew_Trial_Alc, 5000, 0.001);
btsrp.rewAlc = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Alc, 1),2);

tmp = bootstrap_data(Rew_Trial_Saline_O, 5000, 0.001);
btsrp.rewSal_O = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Saline_O, 1),2);
tmp = bootstrap_data(Rew_Trial_Alc_O, 5000, 0.001);
btsrp.rewAlc_O = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Alc_O, 1),2);

tmp = bootstrap_data(Pun_Trial_Saline, 5000, 0.001);
btsrp.punSal = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Saline, 1),2);
tmp = bootstrap_data(Pun_Trial_Alc, 5000, 0.001);
btsrp.punAlc = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Alc, 1),2);

tmp = bootstrap_data(Conf_Saline_F, 5000, 0.001);
btsrp.confSalF = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Saline_F, 1),2);
tmp = bootstrap_data(Conf_Saline_S, 5000, 0.001);
btsrp.confSalS = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Saline_S, 1),2);

tmp = bootstrap_data(Conf_Alc_F, 5000, 0.001);
btsrp.confAlcHiF = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_F, 1),2);
tmp = bootstrap_data(Conf_Alc_S, 5000, 0.001);
btsrp.confAlcHiS = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_S, 1),2);

tmp = bootstrap_data(Pun_Trial_Saline_Omit, 5000, 0.001);
btsrp.punSalO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_F, 1),2);
tmp = bootstrap_data(Pun_Trial_Alc_Omit, 5000, 0.001);
btsrp.punAlcO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_S, 1),2);

tmp = bootstrap_data(Conf_Sal_Trial, 5000, 0.001);
btsrp.confS = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Sal_Trial, 1),2);
tmp = bootstrap_data(Conf_Alc_Trial, 5000, 0.001);
btsrp.confA = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_Trial, 1),2);

tmp = bootstrap_data(Conf_Sal_Trial_O, 5000, 0.001);
btsrp.confSalO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Sal_Trial_O, 1),2);
tmp = bootstrap_data(Conf_Alc_Trial_O, 5000, 0.001);
btsrp.confAlcO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Alc_Trial_O, 1),2);

% %permutation tests
[perm.rewS_rewA, ~] = permTest_array(Rew_Trial_Saline, Rew_Trial_Alc, 1000);
[perm.punS_punA, ~] = permTest_array(Pun_Trial_Saline, Pun_Trial_Alc, 1000);
[perm.punSO_punAO, ~] = permTest_array(Pun_Trial_Saline_Omit, Pun_Trial_Alc_Omit, 1000);
[perm.confSO_confAO, ~] = permTest_array(Conf_Sal_Trial_O, Conf_Alc_Trial_O, 1000);

% 
[perm.confSF_confAF, ~] = permTest_array(Conf_Saline_F, Conf_Alc_F, 1000);
[perm.confSS_confAS, ~] = permTest_array(Conf_Saline_S, Conf_Alc_S, 1000);
[perm.confS_confA, ~] = permTest_array(Conf_Sal_Trial, Conf_Alc_Trial, 1000);

%-----------------------------------------------------Plot Reward  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Saline, Rew_Trial_Alc,Rew_Trial_Saline_O, Rew_Trial_Alc_O};
labels = {Rew_Sal_label, Rew_Alc_label, Rew_Sal_O_label, Rew_Alc_O_label};
colors = {blue, azure, black1, black4};

boottests = {'rewSal', 'rewAlc','rewSal_O', 'rewAlc_O'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewS_rewA'};
offsetsperm = -0.9;
 markersperm = {yellow, black2, black3};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');

title(strcat('Reward Saline vs. ',t));  

%-----------------------------------------------------Plot Punish Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Pun_Trial_Saline, Pun_Trial_Alc};
labels = {Pun_Sal_label, Pun_Alc_label};
colors = {red, pink};

boottests = {'punSal', 'punAlc'};
offsetsboot = [0, -0.1, -0.2, -0.3];
permtests = {'punS_punA'};
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

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(strcat('Punish Trials Saline vs ', t));  

% %-----------------------------------------------------Plot Conflict Food + shock  -----------------------------------------------------------------------

%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Conf_Saline_F, Conf_Saline_S, Conf_Alc_F, Conf_Alc_S};
labels = {Conf_Saline_F_label, Conf_Saline_S_label, Conf_Alc_F_label, Conf_Alc_S_label};
colors = {green, light_green, orange, black4};

boottests = {'confSalF', 'confSalS', 'confAlcHiF', 'confAlcHiS'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'confSF_confAF', 'confSS_confAS'};
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

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(strcat('Conflict Outcomes Saline vs ', t));  


%-----------------------------------------------------Plot Conflict Trials  -----------------------------------------------------------------------

%Statistical parameters
p = 0.05;
thres = 8;

figure
datasets = {Conf_Sal_Trial, Conf_Alc_Trial};
labels = {Conf_Sal_label, Conf_Alc_label};
colors = {orange, light_orange};

boottests = {'confS', 'confA'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'confS_confA'};
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

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(strcat('Conflict Trials - Saline vs ', t));  


% % %-----------------------------------------------------Plot Punish omitted Trials  -----------------------------------------------------------------------
% % 
%Statistical parameters
p = 0.05;
thres = 8;

figure
datasets = {Pun_Trial_Saline_Omit, Pun_Trial_Alc_Omit};
labels = {Pun_SalO_label, Pun_AlcO_label};
colors = {red, pink};

boottests = {'punSalO', 'punAlcO'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5];
permtests = {'punSO_punAO'};
offsetsperm = [-1.0, -1.1, -1.2];
markersperm = {yellow, black2, black3};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(strcat('Punish Omissions Saline vs ', t));  

% % %-----------------------------------------------------Plot Punish omitted Trials  -----------------------------------------------------------------------
% % 
%Statistical parameters
p = 0.05;
thres = 8;

figure
datasets = {Conf_Sal_Trial_O, Conf_Alc_Trial_O};
labels = {Conf_SalO_label, Conf_AlcO_label};
colors = {orange, light_orange};

boottests = {'confSalO', 'confAlcO'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5];
permtests = {'confSO_confAO'};
offsetsperm = [-1.0, -1.1, -1.2];
markersperm = {yellow, black2, black3};

handles = zeros(1, numel(datasets)*2); % Preallocate handles
for i = 1:length(colors)
    hold on
    handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
    jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
        (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
    handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
end

legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
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
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title(strcat('Conflict Omissions Saline vs ', t));  