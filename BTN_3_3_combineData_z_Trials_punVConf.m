%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDSvConf';
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
% Rat = {'R08','R07', 'R02','R03','R05','R06','R09','R10', 'R12','R13','R14','R16'};
Rat = {'R09','R10','R12','R13','R14','R15','R16'};
tmp = [];
  
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder

        load(fullfile(filePath,  [files(i).name]))
        names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors
        exp = names(2);
        Condition = names(3);
        side = dat.sesdat.hemi;
        rat = dat.sesdat.rat;

for j = 1:size(dat.zdata, 1)
 if isnan(dat.zdata(j,5))
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 1 && ismember(rat,Rat) && strcmp(Condition,'rewDS')
    Rew_Trial = [Rew_Trial; dat.zdata(j, 5:end)];
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 0 && ismember(rat,Rat) && strcmp(Condition,'rewDS')
    Rew_Trial_Omit = [Rew_Trial_Omit; dat.zdata(j, 5:end)];
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 1  && ismember(rat,Rat) && strcmp(Condition,'punDS')
    Pun_Trial = [Pun_Trial; dat.zdata(j, 5:end)];
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 0  && ismember(rat,Rat) && strcmp(Condition,'punDS')
    Pun_Trial_Omit = [Pun_Trial_Omit; dat.zdata(j, 5:end)];
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 1  && ismember(rat,Rat) && strcmp(Condition,'CONF')
    Conf_Trial = [Conf_Trial; dat.zdata(j, 5:end)];
 elseif dat.zdata(j, 2) == 1 && dat.zdata(j, 4) == 0  && ismember(rat,Rat) && strcmp(Condition,'CONF')
    Conf_Trial_Omit = [Conf_Trial_Omit; dat.zdata(j, 5:end)];

    
 end
end
end


 %% 
 %___________ colours used for the plots (RGB values / 255)______________
    purp = [0.40,0.0,1.00];
    blu = [0.01,0.66,0.96];
    red = [1.0,0,0];
    orange = [1,0.34,0.13];
    green = [0.125,0.50,0.125];
    black1 = [0.75,0.75,0.75];
    black2 = [0.5,0.5,0.5];
    black3 = [0.25,0.25,0.25];
    black4 = [0,0,0];

%___________ Dimensions and labels used for the plots ______________
 
    time = linspace(-10, 30, size(Rew_Trial, 2));
    Rew_Trial_completed = num2str(size(Rew_Trial,1));
    Rew_Trial_label = ['Phase 1 rewDS responded (', Rew_Trial_completed,')'];
    Rew_Trial_Omitted = num2str(size(Rew_Trial_Omit,1));
    Rew_Omit_Trial_label = ['Phase 1 rewDS omissions (', Rew_Trial_Omitted,')'];
    Pun_Trial_completed = num2str(size(Pun_Trial,1));
    Pun_Trial_label = ['Phase 2 rewDS responded (', Pun_Trial_completed,')'];
    Pun_Trial_Omitted = num2str(size(Pun_Trial_Omit,1));
    Pun_Omit_Trial_label = ['Phase 2 rewDS omissions (', Pun_Trial_Omitted,')'];
    Conf_Trial_completed = num2str(size(Conf_Trial,1));
    Conf_Trial_label = ['Phase 3 rewDS responded (', Conf_Trial_completed,')'];
    Conf_Trial_Omitted = num2str(size(Conf_Trial_Omit,1));
    Conf_Omit_Trial_label = ['Phase 3 rewDS omissions (', Conf_Trial_Omitted,')'];

            %------STATS-----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Trial, 5000, 0.001);
btsrp.rew = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial, 1),2);
tmp = bootstrap_data(Rew_Trial_Omit, 5000, 0.001);
btsrp.rewOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Omit, 1),2);

tmp = bootstrap_data(Pun_Trial, 5000, 0.001);
btsrp.pun = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial, 1),2);
tmp = bootstrap_data(Pun_Trial_Omit, 5000, 0.001);
btsrp.punOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Omit, 1),2);
% 
tmp = bootstrap_data(Conf_Trial, 5000, 0.001);
btsrp.conf = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial, 1),2);
tmp = bootstrap_data(Conf_Trial_Omit, 5000, 0.001);
btsrp.confOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Omit, 1),2);


% %permutation tests
[perm.rewC_rewO, ~] = permTest_array(Rew_Trial, Rew_Trial_Omit, 1000);
[perm.rewC_punC, ~] = permTest_array(Rew_Trial, Pun_Trial, 1000);
[perm.punC_punO, ~] = permTest_array(Pun_Trial, Pun_Trial_Omit, 1000);
[perm.rewC_confC, ~] = permTest_array(Rew_Trial, Conf_Trial, 1000);
[perm.punC_confC, ~] = permTest_array(Conf_Trial, Pun_Trial, 1000);
% 
% 
[perm.rewO_punO, ~] = permTest_array(Rew_Trial_Omit, Pun_Trial_Omit, 1000);
[perm.rewO_confO, ~] = permTest_array(Rew_Trial_Omit, Conf_Trial_Omit, 1000);
[perm.punO_confO, ~] = permTest_array(Conf_Trial_Omit, Pun_Trial_Omit, 1000);
% 


%-----------------------------------------------------Plot (Responded) Trials  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial, Pun_Trial, Conf_Trial};
labels = {Rew_Trial_label, Pun_Trial_label, Conf_Trial_label};
colors = {purp, blu, green};

boottests = {'rew', 'pun', 'conf'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9];
permtests = {'rewC_punC', 'rewC_confC', 'punC_confC'};
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
title('Reward Trials Responded');  

%-----------------------------------------------------Plot Omissions  -----------------------------------------------------------------------
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Omit, Pun_Trial_Omit, Conf_Trial_Omit};
labels = {Rew_Omit_Trial_label, Pun_Omit_Trial_label, Conf_Omit_Trial_label};
colors = {purp, red, green};

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
title('rewDS Omissions');  