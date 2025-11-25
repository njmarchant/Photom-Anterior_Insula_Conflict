%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(10-45)';
filePath = fullfile(tankfolder);
allDat = cell(1,1);
Rew_Trial_Left = [];
Rew_Trial_Right = [];
Rew_Trial_Left_O = [];
Rew_Trial_Right_O = [];
Pun_Trial_Left = [];
Pun_Trial_Right = [];
Pun_Trial_Left_O = [];
Pun_Trial_Right_O = [];
Conf_Trial_Right = [];
Conf_Trial_Left = [];
Conf_Left_F = [];
Conf_Left_S = [];
Conf_Right_S = [];
Conf_Right_F = [];
Conf_Trial_Right_O = [];
Conf_Trial_Left_O = [];

tmp = [];

% R18 and R21 should be removed based on inspection of the daily traces

%
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23','R24'};

All = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12','C13','C14','C15'};  
Early = {'C01','C02','C03','C04','C05','C06'};  
Late = {'C12','C13','C14','C15'}; %'C07','C08','C09','C10', (remove always 'C11', )
Post_Tests = {'C23', 'C24', 'C25', 'C26'};


condition = 'Pun Late';
if strcmp(condition,'Pun Early')
    included_sessions = {'P01','P02', 'P03'};
else
    included_sessions = {'P08','P09','P10'};
end
s=char(condition);


% condition = 'Conf Late';
% s=char(condition);
% if strcmp(condition,'Conf Early')
%     included_sessions = {'C01','C02','C03','C04'};  
% else
%     included_sessions = {'C12','C13','C14','C15'}; 
% end

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder

    load(fullfile(filePath,  [files(i).name]))
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors



    side = sesdat.hemi;
    rat = sesdat.rat;
    session = sesdat.ses;
    is_left_and_rat = strcmp(side, 'Left') & ismember(rat, Rat) & any(strcmp(session, included_sessions));
    is_right_and_rat = strcmp(side, 'Right') & ismember(rat, Rat) & any(strcmp(session, included_sessions));
    is_valid_row = ~isnan(sesdat.traces_z(:, 5));

    % Combine conditions and extract data
    % Extract data and append

    Rew_Trial_Left = [Rew_Trial_Left; sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 1 & sesdat.traces_z(:, 4) == 1, 5:end)];
    Rew_Trial_Left_O = [Rew_Trial_Left_O; sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 1 & sesdat.traces_z(:, 4) == 0, 5:end)];
    Pun_Trial_Left = [Pun_Trial_Left; sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 2 & sesdat.traces_z(:, 4) == 1, 5:end)];
    Pun_Trial_Left_O = [Pun_Trial_Left_O; sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 2 & sesdat.traces_z(:, 4) == 0, 5:end)];
    Conf_Left_F = [Conf_Left_F;sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 2, 5:end)];
    Conf_Left_S = [Conf_Left_S;sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 3, 5:end)];
    Conf_Trial_Left = [Conf_Trial_Left ;sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3, 5:end)];
    Conf_Trial_Left_O = [Conf_Trial_Left_O;sesdat.traces_z(is_left_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 0, 5:end)];

    % Repeat for Right_test condition (similar to Left)
    Rew_Trial_Right = [Rew_Trial_Right;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 1 & sesdat.traces_z(:, 4) == 1, 5:end)];
    Rew_Trial_Right_O = [Rew_Trial_Right_O; sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 1 & sesdat.traces_z(:, 4) == 0, 5:end)];
    Pun_Trial_Right = [Pun_Trial_Right ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 2 & sesdat.traces_z(:, 4) == 1, 5:end)];
    Pun_Trial_Right_O = [Pun_Trial_Right_O ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 2 & sesdat.traces_z(:, 4) == 0, 5:end)];
    Conf_Right_F = [Conf_Right_F ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 2, 5:end)];
    Conf_Right_S = [Conf_Right_S ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 3, 5:end)];
    Conf_Trial_Right = [Conf_Trial_Right ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3, 5:end)];
    Conf_Trial_Right_O = [Conf_Trial_Right_O ;sesdat.traces_z(is_right_and_rat & is_valid_row & sesdat.traces_z(:, 2) == 3 & sesdat.traces_z(:, 4) == 0, 5:end)];

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

    time = linspace(-10, 45, size(Rew_Trial_Left, 2));
    Rew_Left = num2str(size(Rew_Trial_Left,1));
    Rew_Left_label = ['Left RewDS (', Rew_Left,')'];
    Rew_Right = num2str(size(Rew_Trial_Right,1));
    Rew_Right_label = ['Right RewDS (', Rew_Right,')'];

    Rew_Left_O = num2str(size(Rew_Trial_Left_O,1));
    Rew_Left_O_label = ['Left RewDS Omit (', Rew_Left_O,')'];
    Rew_Right_O = num2str(size(Rew_Trial_Right_O,1));
    Rew_Right_O_label = ['Right RewDS Omit (', Rew_Right_O,')'];

    Pun_Left = num2str(size(Pun_Trial_Left,1));
    Pun_Left_label = ['Left PunDS (', Pun_Left,')'];
    Pun_Right = num2str(size(Pun_Trial_Right,1));
    Pun_Right_label = ['Right PunDS (', Pun_Right,')'];

    Pun_Left_O = num2str(size(Pun_Trial_Left_O,1));
    Pun_Left_O_label = ['Left PunDS Omit (', Pun_Left_O,')'];
    Pun_Right_O = num2str(size(Pun_Trial_Right_O,1));
    Pun_Right_O_label = ['Right PunDS Omit (', Pun_Right_O,')'];

    Conf_Left_F = num2str(size(Conf_Left_F,1));
    Conf_Left_F_label = ['Left Conf food (', Conf_Left_F,')'];
    Conf_Left_S = num2str(size(Conf_Left_S,1));
    Conf_Left_S_label = ['Left Conf shock (', Conf_Left_S,')'];

    Conf_Right_F_count = num2str(size(Conf_Right_F,1));
    Conf_Right_F_label = ['Right Conf food (', Conf_Right_F_count,')'];
    Conf_Right_S_count = num2str(size(Conf_Right_S,1));
    Conf_Right_S_label = ['Right Conf shock (', Conf_Right_S_count,')'];

    Conf_Left_Trial_count = num2str(size(Conf_Trial_Left,1));
    Conf_Left_label = ['Left Conf (', Conf_Left_Trial_count,')'];
    Conf_Right_Trial_count = num2str(size(Conf_Trial_Right,1));
    Conf_Right_label = ['Right Conf ALL (', Conf_Right_Trial_count,')'];

    Conf_Left_O = num2str(size(Conf_Trial_Left_O,1));
    Conf_Left_O_label = ['Left Conf Omit (', Conf_Left_O,')'];
    Conf_Right_O = num2str(size(Conf_Trial_Right_O,1));
    Conf_Right_O_label = ['Right Conf Omit (', Conf_Right_O,')'];


            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Trial_Left, 5000, 0.001);
btsrp.rewLeft = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Left, 1),2);
tmp = bootstrap_data(Rew_Trial_Right, 5000, 0.001);
btsrp.rewRight = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Right, 1),2);
%rewDS omissions
tmp = bootstrap_data(Rew_Trial_Left_O, 5000, 0.001);
btsrp.rewLeft_O = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Left_O, 1),2);
tmp = bootstrap_data(Rew_Trial_Right_O, 5000, 0.001);
btsrp.rewRight_O = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Right_O, 1),2);
%punDS responded
tmp = bootstrap_data(Pun_Trial_Left, 5000, 0.001);
btsrp.punLeft = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Left, 1),2);
tmp = bootstrap_data(Pun_Trial_Right, 5000, 0.001);
btsrp.punRight = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Right, 1),2);
%punDS Omitted
tmp = bootstrap_data(Pun_Trial_Left_O, 5000, 0.001);
btsrp.punLeftO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Left_O, 1),2);
tmp = bootstrap_data(Pun_Trial_Right_O, 5000, 0.001);
btsrp.punRightO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Trial_Right_O, 1),2);
% %conf responded
% tmp = bootstrap_data(Conf_Trial_Left, 5000, 0.001);
% btsrp.confLeft = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Left, 1),2);
% tmp = bootstrap_data(Conf_Trial_Right, 5000, 0.001);
% btsrp.confRight = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Right, 1),2);
% %conf omitted
% tmp = bootstrap_data(Conf_Trial_Left_O, 5000, 0.001);
% btsrp.confLeftO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Left_O, 1),2);
% tmp = bootstrap_data(Conf_Trial_Right_O, 5000, 0.001);
% btsrp.confRightO = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Conf_Trial_Right_O, 1),2);

% %permutation tests
%responded trials
[perm.rewL_rewR, ~] = permTest_array(Rew_Trial_Left, Rew_Trial_Right, 1000);
[perm.punL_punR, ~] = permTest_array(Pun_Trial_Left, Pun_Trial_Right, 1000);
% [perm.confL_confR, ~] = permTest_array(Conf_Trial_Left, Conf_Trial_Right, 1000);

%omissions
[perm.rewLO_rewRO, ~] = permTest_array(Rew_Trial_Left_O, Rew_Trial_Right_O, 1000);
[perm.punLO_punRO, ~] = permTest_array(Pun_Trial_Left_O, Pun_Trial_Right_O, 1000);
% [perm.confLO_confRO, ~] = permTest_array(Conf_Trial_Left_O, Conf_Trial_Right_O, 1000);

%right tests
[perm.rewR_rewRO, ~] = permTest_array(Rew_Trial_Right, Rew_Trial_Right_O, 1000);
[perm.punR_punRO, ~] = permTest_array(Pun_Trial_Right, Pun_Trial_Right_O, 1000);
% [perm.confR_confRO, ~] = permTest_array(Conf_Trial_Right, Conf_Trial_Right_O, 1000);

%Left tests
[perm.rewL_rewLO, ~] = permTest_array(Rew_Trial_Left, Rew_Trial_Left_O, 1000);
[perm.punL_punLO, ~] = permTest_array(Pun_Trial_Left, Pun_Trial_Left_O, 1000);
% [perm.confL_confLO, ~] = permTest_array(Conf_Trial_Left, Conf_Trial_Left_O, 1000);


%%
% -----------------------------------------------------Plot Right - RewDS  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Right, Rew_Trial_Right_O};
labels = {Rew_Right_label, Rew_Right_O_label};
colors = {purp, blue};

boottests = {'rewRight', 'rewRight_O'};
offsetsboot = [0, -0.1, -0.4, -0.5];
permtests = {'rewR_rewRO'};
offsetsperm = -1.0;
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
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Right rewDS Trials');  

% -----------------------------------------------------Plot Left - RewDS  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Left, Rew_Trial_Left_O};
labels = {Rew_Left_label, Rew_Left_O_label};
colors = {purp, blue};

boottests = {'rewLeft', 'rewLeft_O'};
offsetsboot = [0, -0.1, -0.4, -0.5];
permtests = {'rewL_rewLO'};
offsetsperm = -1.0;
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
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Left rewDS Trials'); 

% -----------------------------------------------------Plot Right - punDS  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Pun_Trial_Right, Pun_Trial_Right_O};
labels = {Pun_Right_label, Pun_Right_O_label};
colors = {red, pink};

boottests = {'punRight', 'punRightO'};
offsetsboot = [0, -0.1, -0.4, -0.5];
permtests = {'punR_punRO'};
offsetsperm = -1.0;
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
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Right punDS Trials');  

% -----------------------------------------------------Plot Left - punDS  -----------------------------------------------------------------------
 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Pun_Trial_Left, Pun_Trial_Left_O};
labels = {Pun_Left_label, Pun_Left_O_label};
colors = {red, pink};

boottests = {'punLeft', 'punLeftO'};
offsetsboot = [0, -0.1, -0.4, -0.5];
permtests = {'punL_punLO'};
offsetsperm = -1.0;
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
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Left punDS Trials'); 

% % -----------------------------------------------------Plot Right - conf  -----------------------------------------------------------------------
% 
% %Statistical parameters
% p = 0.01;
% thres = 8;
% 
% figure
% datasets = {Conf_Trial_Right, Conf_Trial_Right_O};
% labels = {Conf_Right_label, Conf_Right_O_label};
% colors = {orange, green};
% 
% boottests = {'confRight', 'confRightO'};
% offsetsboot = [0, -0.1, -0.4, -0.5];
% permtests = {'confR_confRO'};
% offsetsperm = -1.0;
%  markersperm = {black1, black2, black3};
% 
% handles = zeros(1, numel(datasets)*2); % Preallocate handles
% for i = 1:length(colors)
%     hold on
%     handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
%     jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
%         (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
%     handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
% end
% 
% legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
% ax = gca;
% yLimits = ax.YLim;
% yMin = yLimits(1);
% 
% % Plotting markers for bootstrapping
% for i = 1:2:length(boottests)*2
%     tmp = find(btsrp.(boottests{(i+1)/2})(1,:) > 0);   % Find indices for values > 0 (i.e. signal higher than baseline)
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsboot(i) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
% 
%     clear tmp id
%     tmp = find(btsrp.(boottests{(i+1)/2})(2,:) < 0); % Find indices for values < 0 (i.e. signal lower than baseline)
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsboot(i+1) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
% end
% 
% % Plotting permutation tests
% for i = 1:length(permtests)
%     tmp = find(perm.(permtests{i})(1, :) < p);
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
% end
% 
% % Adding zero reference lines and title
% line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
% line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
% line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
% title('Right confDS Trials');  
% 
% % -----------------------------------------------------Plot Left - conf  -----------------------------------------------------------------------
% 
% %Statistical parameters
% p = 0.01;
% thres = 8;
% 
% figure
% datasets = {Conf_Trial_Left, Conf_Trial_Left_O};
% labels = {Conf_Left_label, Conf_Left_O_label};
% colors = {orange, green};
% 
% boottests = {'confLeft', 'confLeftO'};
% offsetsboot = [0, -0.1, -0.4, -0.5];
% permtests = {'confL_confLO'};
% offsetsperm = -1.0;
%  markersperm = {black1, black2, black3};
% 
% handles = zeros(1, numel(datasets)*2); % Preallocate handles
% for i = 1:length(colors)
%     hold on
%     handles(i) = plot(time, mean(datasets{i}, 1), 'Color', colors{i});
%     jbfill(time, (mean(datasets{i}) - std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1))), ...
%         (std(datasets{i}, 0, 1) / sqrt(size(datasets{i}, 1)) + mean(datasets{i})), colors{i}, 'none', 0, 0.2);
%     handles(i+3) = plot(NaN, NaN, 'Color', colors{i}); % Dummy handle for legend
% end
% 
% legend(handles(1:length(labels)), labels); % Provide only the handles for mean lines
% ax = gca;
% yLimits = ax.YLim;
% yMin = yLimits(1);
% 
% % Plotting markers for bootstrapping
% for i = 1:2:length(boottests)*2
%     tmp = find(btsrp.(boottests{(i+1)/2})(1,:) > 0);   % Find indices for values > 0 (i.e. signal higher than baseline)
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsboot(i) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
% 
%     clear tmp id
%     tmp = find(btsrp.(boottests{(i+1)/2})(2,:) < 0); % Find indices for values < 0 (i.e. signal lower than baseline)
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsboot(i+1) * ones(size(time(id), 2), 2)), 's', 'MarkerSize', 7, 'MarkerFaceColor', colors{(i+1)/2}, 'Color', colors{(i+1)/2}, 'HandleVisibility', 'off');
% end
% 
% % Plotting permutation tests
% for i = 1:length(permtests)
%     tmp = find(perm.(permtests{i})(1, :) < p);
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
% end
% 
% % Adding zero reference lines and title
% line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
% line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
% line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
% title('Left conf Trials'); 