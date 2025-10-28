%% Isis Alonso-Lozares 16-06-21 script to combine data from different animals
%% NM updated for social reward experiment 15-05-23
%% define where the stuff is

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(25-15)';

filePath = fullfile(tankfolder);
allDat = cell(1,1);
Rew_Resp = [];
Pun_Resp = [];

tmp = [];

condition = 'Pun Late';
s=char(condition);
if strcmp(condition,'Pun Early')
    included_sessions = {'P01','P02', 'P03'};
else
    included_sessions = {'P08','P09','P10'};
end

pun_early = {'P01','P02','P03'};
pun_mid = {'P05','P06','P07'};
pun_late = {'P08','P09','P10'};

% R18 and R21 should be removed based on inspection of the daily traces
Rat = {'R12','R15','R17','R19','R20','R22','R23', 'R24'};
conf_02b_Rat = {'R09','R10','R13','R14','R16'};
pun_early = {'P01','P02','P03'};
pun_late = {'P08','P09','P10'};
conf_02b_pun_late = {'P13','P14','P15'};
R11_pun_late = {'P04','P05','P06'};

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

    if ismember(rat,Rat) && any(strcmp(session, included_sessions))
        for j = 1:size(sesdat.traces_z, 1)
            if isnan(sesdat.traces_z(j,5))
            elseif sesdat.traces_z(j, 2) == 5
                Rew_Resp = [Rew_Resp; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 6
                Pun_Resp = [Pun_Resp; sesdat.traces_z(j, 5:end)];
            end
        end
    elseif ismember(rat,conf_02b_Rat) && any(strcmp(session, conf_02b_pun_late))
        for j = 1:size(sesdat.traces_z, 1)
            if isnan(sesdat.traces_z(j,5))
            elseif sesdat.traces_z(j, 2) == 5
                Rew_Resp = [Rew_Resp; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 6
                Pun_Resp = [Pun_Resp; sesdat.traces_z(j, 5:end)];
            end
        end
    elseif strcmp(rat,'R11') && any(strcmp(session, R11_pun_late))
        for j = 1:size(sesdat.traces_z, 1)
            if isnan(sesdat.traces_z(j,5))
            elseif sesdat.traces_z(j, 2) == 5
                Rew_Resp = [Rew_Resp; sesdat.traces_z(j, 5:end)];
            elseif sesdat.traces_z(j, 2) == 6
                Pun_Resp = [Pun_Resp; sesdat.traces_z(j, 5:end)];
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
    Rew_completed = num2str(size(Rew_Resp,1));
    Rew_Resp_label = [s, ' - rewDS lever press (', Rew_completed,')'];
    
    Pun_completed = num2str(size(Pun_Resp,1));
    Pun_Resp_label = [s, ' - punDS lever press (', Pun_completed,')'];

    

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Resp, 5000, 0.001);
btsrp.rew = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Resp, 1),2);

tmp = bootstrap_data(Pun_Resp, 5000, 0.001);
btsrp.pun = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Pun_Resp, 1),2);



% %permutation tests

[perm.rewC_punC, ~] = permTest_array(Rew_Resp, Pun_Resp, 1000);



% %-----------------------------------------------------Plot Reward v Punish  Responses  -----------------------------------------------------------------------
% 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Resp, Pun_Resp};
labels = {Rew_Resp_label, Pun_Resp_label};
colors = {green, red};

boottests = {'rew', 'pun'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7];
permtests = {'rewC_punC'};
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
title('Lever presses', s);  

