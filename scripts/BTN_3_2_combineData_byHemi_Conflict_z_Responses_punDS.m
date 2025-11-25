%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(25-15)';

filePath = fullfile(tankfolder);
allDat = cell(1,1);
L_Rew_Resp = [];
L_Pun_Resp = [];

R_Rew_Resp = [];
R_Pun_Resp = [];
tmp = [];


pun_early = {'P01','P02','P03','P04'};
pun_mid = {'P05','P06','P07'};
pun_late = {'P08','P09','P10'};%,'P13','P14','P15'};

% R18 and R21 should be removed based on inspection of the daily traces
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder

        load(fullfile(filePath,  [files(i).name]))
        names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors
        side = sesdat.hemi;
        rat = sesdat.rat;
        phase = sesdat.phase;
        session = sesdat.ses;
        % conf_percent = dat.sesdat.responses(3,3);
    if ismember(rat,Rat) && any(strcmp(session, pun_late)) 
        for j = 1:size(sesdat.traces_z, 1)
            if strcmp(side,'Left') 
                if isnan(sesdat.traces_z(j,5))
                 elseif sesdat.traces_z(j, 2) == 5
                    L_Rew_Resp = [L_Rew_Resp; sesdat.traces_z(j, 5:end)];
                 elseif sesdat.traces_z(j, 2) == 6 
                    L_Pun_Resp = [L_Pun_Resp; sesdat.traces_z(j, 5:end)];
                end
            elseif strcmp(side,'Right')
                if isnan(sesdat.traces_z(j,5))
                    elseif sesdat.traces_z(j, 2) == 5
                        R_Rew_Resp = [R_Rew_Resp; sesdat.traces_z(j, 5:end)];
                    elseif sesdat.traces_z(j, 2) == 6 
                        R_Pun_Resp = [R_Pun_Resp; sesdat.traces_z(j, 5:end)];
                end
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
 
    time = linspace(-25, 15, size(L_Rew_Resp, 2));
    L_Rew_completed = num2str(size(L_Rew_Resp,1));
    L_Rew_Resp_label = ['Left Reward completions (', L_Rew_completed,')'];
    R_Rew_completed = num2str(size(R_Rew_Resp,1));
    R_Rew_Resp_label = ['Right Reward completions (', R_Rew_completed,')'];

    L_Pun_completed = num2str(size(L_Pun_Resp,1));
    L_Pun_Resp_label = ['Left Punish completions (', L_Pun_completed,')'];
    R_Pun_completed = num2str(size(R_Pun_Resp,1));
    R_Pun_Resp_label = ['Right Punish completions (', R_Pun_completed,')'];
    

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(L_Rew_Resp, 5000, 0.001);
btsrp.rewL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(L_Rew_Resp, 1),2);
tmp = bootstrap_data(R_Rew_Resp, 5000, 0.001);
btsrp.rewR = CIadjust(tmp(1,:),tmp(2,:),tmp,size(R_Rew_Resp, 1),2);

tmp = bootstrap_data(L_Pun_Resp, 5000, 0.001);
btsrp.punL = CIadjust(tmp(1,:),tmp(2,:),tmp,size(L_Pun_Resp, 1),2);
tmp = bootstrap_data(R_Pun_Resp, 5000, 0.001);
btsrp.punR = CIadjust(tmp(1,:),tmp(2,:),tmp,size(R_Pun_Resp, 1),2);


% %permutation tests

[perm.rewL_punL, ~] = permTest_array(L_Rew_Resp, L_Pun_Resp, 1000);

[perm.rewR_punR, ~] = permTest_array(R_Rew_Resp, R_Pun_Resp, 1000);


% %-----------------------------------------------------Plot Left Reward v Punish  Responses  -----------------------------------------------------------------------
% 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {L_Rew_Resp, L_Pun_Resp};
labels = {L_Rew_Resp_label, L_Pun_Resp_label};
colors = {blue, red};

boottests = {'rewL', 'punL'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewL_punL'};
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
title('LEFT Reward v Punish');  

% %-----------------------------------------------------Plot Right Reward v Punish  Responses  -----------------------------------------------------------------------
% 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {R_Rew_Resp, R_Pun_Resp};
labels = {R_Rew_Resp_label, R_Pun_Resp_label};
colors = {blue, red};

boottests = {'rewR', 'punR'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewR_punR'};
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
title('RIGHT Reward v Punish');  

