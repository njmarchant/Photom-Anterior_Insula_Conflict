

clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(10-45)';

filePath = fullfile(tankfolder);
allDat = cell(1,1);

Rew_Trial_Omit = [];



tmp = [];


% R18 and R21 should be removed based on inspection of the daily traces
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17','R19','R20','R22','R23', 'R24'};

filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder
    load(fullfile(filePath,  [files(i).name]))
        
    side = sesdat.hemi;
    rat = sesdat.rat;
    phase = sesdat.phase;
    session = sesdat.ses;
        
    if ismember(rat,Rat) 
        for j = 1:size(sesdat.traces_z, 1)
             if isnan(sesdat.traces_z(j,5))
             elseif sesdat.traces_z(j, 2) == 1 && sesdat.traces_z(j, 4) == 0 
                Rew_Trial_Omit = [Rew_Trial_Omit; sesdat.traces_z(j, 5:end)];
             

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
 
    time = linspace(-10, 45, size(Rew_Trial_Omit, 2));
    Rew_Trial_Omitted = num2str(size(Rew_Trial_Omit,1));
    Rew_Omit_Trial_label = ['rewDS Trial - omitted (', Rew_Trial_Omitted,')'];
    % Pun_Trial_Omitted = num2str(size(Pun_Trial_Omit,1));
    % Pun_Omit_Trial_label = ['punDS Trial - omitted (', Pun_Trial_Omitted,')'];
    % 

            %------STATS -----------------------------------------------------------------------

% %bootstrap 
tmp = bootstrap_data(Rew_Trial_Omit, 5000, 0.001);
btsrp.rewOmit = CIadjust(tmp(1,:),tmp(2,:),tmp,size(Rew_Trial_Omit, 1),2);



% %permutation tests

% [perm.rewO_punO, ~] = permTest_array(Rew_Trial_Omit, Pun_Trial_Omit, 1000);


%% -----------------------------------------------------Plot Reward v Punish omitted Trials  -----------------------------------------------------------------------

% 
%Statistical parameters
p = 0.01;
thres = 8;

figure
datasets = {Rew_Trial_Omit};
labels = {Rew_Omit_Trial_label};
colors = {azure};

boottests = {'rewOmit'};
offsetsboot = [0, -0.1, -0.2, -0.3, -0.4, -0.5];
% permtests = {'rewO_punO'};
% offsetsperm = [-1.0, -1.1, -1.2];
% markersperm = {yellow, black2, black3};

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
% for i = 1:length(permtests)
%     tmp = find(perm.(permtests{i})(1, :) < p);
%     id = tmp(consec_idx(tmp, thres));
%     plot(time(id), (yMin + offsetsperm(i)) * ones(size(time(id), 2), 2), 's', 'MarkerSize', 7, 'MarkerFaceColor', markersperm{i}, 'Color', markersperm{i}, 'HandleVisibility', 'off');
% end

% Adding zero reference lines and title
yLimits = ax.YLim;
line([ax.XLim(1), ax.XLim(2)], [0, 0], 'Color', 'black', 'HandleVisibility', 'off');
line([0, 0], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([10, 10], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
line([40, 40], [yLimits(1), yLimits(2)], 'Color', 'black', 'HandleVisibility', 'off');
title('Omissions - rewDS');  