%% Nathan Marchant July 2024
% Written for the conflict task
% This script will calculate the zMean for a given period, defined below
% Adjusted to take only the trials 900 seconds after the start (i.e.
% excluding the first 15 min)

close all
clear all
close all

% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(25-15)';

% load invidivual session data
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder
    load(fullfile(filePath,  [files(i).name]))
    names = strsplit(files(i).name, {'-' , '_', ' ', '.'}); %divide the file name into separte character vectors

    temp.zmean = [];
    temp2.zmean = [];

    % get variables
    data = sesdat.traces_z(:, 5:end);
    times = sesdat.traces_z(:, 1:4);
    condition = sesdat.phase;
    r = sesdat.rat;
    sex = sesdat.sex;
    s1 = sesdat.ses;
    h = sesdat.hemi;

    %define time, baseline etc
    time = linspace(-25, 15, size(data, 2)); %time vector the size of trace
    base = (time >= -25) & (time <= -20); %This is the time period of the trace for which the baseline is calculated
    lims1 = (time >= -5) & (time <= -4); %
    lims2 = (time >= -4) & (time <= -3); %
    lims3 = (time >= -3) & (time <= -2); %
    lims4 = (time >= -2) & (time <= -1); %
    lims5 = (time >= -1) & (time <= 0); %
    lims6 = (time >= 0) & (time <= 1.5); %
    lims7 = (time >= 1.5) & (time <= 3); %
    lims8 = (time >= 2) & (time <= 3); %
    lims9 = (time >= 3) & (time <= 4); %
    lims10 = (time >= 4) & (time <= 5); %

    zdata = [];
    zdata = [times, data];

    if strcmp(s1,'Saline')
        %% __________________ SALINE SESSIONS ___________________________________
        % calculate auc and mean in cue period from RESPONDED reward trials
        cdat = zdata(zdata(:, 1) >= 900 & zdata(:,2) == 5 & zdata(:,4) == 1, 5:end);
        temp.zmean.sal_rew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.sal_rew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.sal_rew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.sal_rew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.sal_rew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.sal_rew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.sal_rew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.sal_rew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.sal_rew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.sal_rew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        sal_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % calculate auc and mean in cue period from RESPONDED punishment trials
        cdat = zdata(zdata(:, 1) >= 900 &zdata(:,2) == 6 & zdata(:,4) == 2, 5:end);
        temp.zmean.sal_pun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.sal_pun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.sal_pun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.sal_pun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.sal_pun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.sal_pun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.sal_pun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.sal_pun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.sal_pun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.sal_pun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        sal_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % %calculate Rewarded Responses in conf trials
        cdat = zdata(zdata(:,2) == 5 & zdata(:,4) == 3, 5:end);
        temp.zmean.sal_confrew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.sal_confrew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.sal_confrew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.sal_confrew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.sal_confrew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.sal_confrew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.sal_confrew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.sal_confrew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.sal_confrew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.sal_confrew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        sal_confrew_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_confrew_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_confrew_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_confrew_ses_col = [repmat({s1}, size(cdat, 1),1)];
        %
        % %calculate Punished Responses in conf trials
        cdat = zdata(zdata(:,2) == 6 & zdata(:,4) == 3, 5:end);
        temp.zmean.sal_confpun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.sal_confpun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.sal_confpun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.sal_confpun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.sal_confpun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.sal_confpun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.sal_confpun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.sal_confpun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.sal_confpun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.sal_confpun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        sal_confpun_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_confpun_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_confpun_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_confpun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % save variables...
        % SALINE SESSIONS
        temp2.zmean.collated_sal_rew_labels = [sal_rew_r_col, sal_rew_s_col, sal_rew_h_col, sal_rew_ses_col];
        temp2.zmean.collated_sal_rew = [temp.zmean.sal_rew_1, temp.zmean.sal_rew_2, temp.zmean.sal_rew_3, temp.zmean.sal_rew_4, temp.zmean.sal_rew_5, temp.zmean.sal_rew_6, temp.zmean.sal_rew_7, temp.zmean.sal_rew_8, temp.zmean.sal_rew_9, temp.zmean.sal_rew_10];

        temp2.zmean.collated_sal_pun_labels = [sal_pun_r_col, sal_pun_s_col, sal_pun_h_col, sal_pun_ses_col];
        temp2.zmean.collated_sal_pun = [temp.zmean.sal_pun_1, temp.zmean.sal_pun_2, temp.zmean.sal_pun_3, temp.zmean.sal_pun_4, temp.zmean.sal_pun_5, temp.zmean.sal_pun_6, temp.zmean.sal_pun_7, temp.zmean.sal_pun_8, temp.zmean.sal_pun_9, temp.zmean.sal_pun_10];

        temp2.zmean.collated_sal_confrew_labels = [sal_confrew_r_col, sal_confrew_s_col, sal_confrew_h_col, sal_confrew_ses_col];
        temp2.zmean.collated_sal_confrew = [temp.zmean.sal_confrew_1, temp.zmean.sal_confrew_2, temp.zmean.sal_confrew_3, temp.zmean.sal_confrew_4, temp.zmean.sal_confrew_5, temp.zmean.sal_confrew_6, temp.zmean.sal_confrew_7, temp.zmean.sal_confrew_8, temp.zmean.sal_confrew_9, temp.zmean.sal_confrew_10];
        temp2.zmean.collated_sal_confpun_labels = [sal_confpun_r_col, sal_confpun_s_col, sal_confpun_h_col, sal_confpun_ses_col];
        temp2.zmean.collated_sal_confpun = [temp.zmean.sal_confpun_1, temp.zmean.sal_confpun_2, temp.zmean.sal_confpun_3, temp.zmean.sal_confpun_4, temp.zmean.sal_confpun_5, temp.zmean.sal_confpun_6, temp.zmean.sal_confpun_7, temp.zmean.sal_confpun_8, temp.zmean.sal_confpun_9, temp.zmean.sal_confpun_10];



    elseif strcmp(s1,'Alcohol_Low')
        %% __________________ Alcohol Low SESSIONS ___________________________________
        % calculate auc and mean in cue period from RESPONDED reward trials
        cdat = zdata(zdata(:, 1) >= 900 & zdata(:,2) == 5 & zdata(:,4) == 1, 5:end);
        temp.zmean.alc_low_rew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_low_rew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_low_rew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_low_rew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_low_rew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_low_rew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_low_rew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_low_rew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_low_rew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_low_rew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % calculate auc and mean in cue period from RESPONDED punishment trials
        cdat = zdata(zdata(:, 1) >= 900 &zdata(:,2) == 6 & zdata(:,4) == 2, 5:end);
        temp.zmean.alc_low_pun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_low_pun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_low_pun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_low_pun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_low_pun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_low_pun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_low_pun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_low_pun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_low_pun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_low_pun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % %calculate Rewarded Responses in conf trials
        cdat = zdata(zdata(:,2) == 5 & zdata(:,4) == 3, 5:end);
        temp.zmean.alc_low_confrew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_low_confrew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_low_confrew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_low_confrew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_low_confrew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_low_confrew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_low_confrew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_low_confrew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_low_confrew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_low_confrew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_confrew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_confrew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_confrew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_confrew_ses_col = [repmat({s1}, size(cdat, 1),1)];
        
        % %calculate Punished Responses in conf trials
        cdat = zdata(zdata(:,2) == 6 & zdata(:,4) == 3, 5:end);
        temp.zmean.alc_low_confpun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_low_confpun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_low_confpun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_low_confpun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_low_confpun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_low_confpun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_low_confpun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_low_confpun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_low_confpun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_low_confpun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_confpun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_confpun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_confpun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_confpun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % save variables...
        temp2.zmean.collated_alc_low_rew_labels = [alc_low_rew_r_col, alc_low_rew_s_col, alc_low_rew_h_col, alc_low_rew_ses_col];
        temp2.zmean.collated_alc_low_rew = [temp.zmean.alc_low_rew_1, temp.zmean.alc_low_rew_2, temp.zmean.alc_low_rew_3, temp.zmean.alc_low_rew_4, temp.zmean.alc_low_rew_5, temp.zmean.alc_low_rew_6, temp.zmean.alc_low_rew_7, temp.zmean.alc_low_rew_8, temp.zmean.alc_low_rew_9, temp.zmean.alc_low_rew_10];

        temp2.zmean.collated_alc_low_pun_labels = [alc_low_pun_r_col, alc_low_pun_s_col, alc_low_pun_h_col, alc_low_pun_ses_col];
        temp2.zmean.collated_alc_low_pun = [temp.zmean.alc_low_pun_1, temp.zmean.alc_low_pun_2, temp.zmean.alc_low_pun_3, temp.zmean.alc_low_pun_4, temp.zmean.alc_low_pun_5, temp.zmean.alc_low_pun_6, temp.zmean.alc_low_pun_7, temp.zmean.alc_low_pun_8, temp.zmean.alc_low_pun_9, temp.zmean.alc_low_pun_10];

        temp2.zmean.collated_alc_low_confrew_labels = [alc_low_confrew_r_col, alc_low_confrew_s_col, alc_low_confrew_h_col, alc_low_confrew_ses_col];
        temp2.zmean.collated_alc_low_confrew = [temp.zmean.alc_low_confrew_1, temp.zmean.alc_low_confrew_2, temp.zmean.alc_low_confrew_3, temp.zmean.alc_low_confrew_4, temp.zmean.alc_low_confrew_5, temp.zmean.alc_low_confrew_6, temp.zmean.alc_low_confrew_7, temp.zmean.alc_low_confrew_8, temp.zmean.alc_low_confrew_9, temp.zmean.alc_low_confrew_10];
        temp2.zmean.collated_alc_low_confpun_labels = [alc_low_confpun_r_col, alc_low_confpun_s_col, alc_low_confpun_h_col, alc_low_confpun_ses_col];
        temp2.zmean.collated_alc_low_confpun = [temp.zmean.alc_low_confpun_1, temp.zmean.alc_low_confpun_2, temp.zmean.alc_low_confpun_3, temp.zmean.alc_low_confpun_4, temp.zmean.alc_low_confpun_5, temp.zmean.alc_low_confpun_6, temp.zmean.alc_low_confpun_7, temp.zmean.alc_low_confpun_8, temp.zmean.alc_low_confpun_9, temp.zmean.alc_low_confpun_10];


    elseif strcmp(s1,'Alcohol_High')
        % __________________ Alcohol High SESSIONS ___________________________________
        % calculate auc and mean in cue period from RESPONDED reward trials
        cdat = zdata(zdata(:, 1) >= 900 & zdata(:,2) == 5 & zdata(:,4) == 1, 5:end);
        temp.zmean.alc_hi_rew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_hi_rew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_hi_rew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_hi_rew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_hi_rew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_hi_rew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_hi_rew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_hi_rew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_hi_rew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_hi_rew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % calculate auc and mean in cue period from RESPONDED punishment trials
        cdat = zdata(zdata(:, 1) >= 900 &zdata(:,2) == 6 & zdata(:,4) == 2, 5:end);
        temp.zmean.alc_hi_pun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_hi_pun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_hi_pun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_hi_pun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_hi_pun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_hi_pun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_hi_pun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_hi_pun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_hi_pun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_hi_pun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % %calculate Rewarded Responses in conf trials
        cdat = zdata(zdata(:,2) == 5 & zdata(:,4) == 3, 5:end);
        temp.zmean.alc_hi_confrew_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_hi_confrew_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_hi_confrew_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_hi_confrew_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_hi_confrew_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_hi_confrew_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_hi_confrew_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_hi_confrew_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_hi_confrew_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_hi_confrew_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_confrew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_confrew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_confrew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_confrew_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % %calculate Punished Responses in conf trials
        cdat = zdata(zdata(:,2) == 6 & zdata(:,4) == 3, 5:end);
        temp.zmean.alc_hi_confpun_1 = mean(cdat(:, lims1), 2);
        temp.zmean.alc_hi_confpun_2 = mean(cdat(:, lims2), 2);
        temp.zmean.alc_hi_confpun_3 = mean(cdat(:, lims3), 2);
        temp.zmean.alc_hi_confpun_4 = mean(cdat(:, lims4), 2);
        temp.zmean.alc_hi_confpun_5 = mean(cdat(:, lims5), 2);
        temp.zmean.alc_hi_confpun_6 = mean(cdat(:, lims6), 2);
        temp.zmean.alc_hi_confpun_7 = mean(cdat(:, lims7), 2);
        temp.zmean.alc_hi_confpun_8 = mean(cdat(:, lims8), 2);
        temp.zmean.alc_hi_confpun_9 = mean(cdat(:, lims9), 2);
        temp.zmean.alc_hi_confpun_10 = mean(cdat(:, lims10), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_confpun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_confpun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_confpun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_confpun_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % save variables...

        temp2.zmean.collated_alc_hi_rew_labels = [alc_hi_rew_r_col, alc_hi_rew_s_col, alc_hi_rew_h_col, alc_hi_rew_ses_col];
        temp2.zmean.collated_alc_hi_rew = [temp.zmean.alc_hi_rew_1, temp.zmean.alc_hi_rew_2, temp.zmean.alc_hi_rew_3, temp.zmean.alc_hi_rew_4, temp.zmean.alc_hi_rew_5, temp.zmean.alc_hi_rew_6, temp.zmean.alc_hi_rew_7, temp.zmean.alc_hi_rew_8, temp.zmean.alc_hi_rew_9, temp.zmean.alc_hi_rew_10];

        temp2.zmean.collated_alc_hi_pun_labels = [alc_hi_pun_r_col, alc_hi_pun_s_col, alc_hi_pun_h_col, alc_hi_pun_ses_col];
        temp2.zmean.collated_alc_hi_pun = [temp.zmean.alc_hi_pun_1, temp.zmean.alc_hi_pun_2, temp.zmean.alc_hi_pun_3, temp.zmean.alc_hi_pun_4, temp.zmean.alc_hi_pun_5, temp.zmean.alc_hi_pun_6, temp.zmean.alc_hi_pun_7, temp.zmean.alc_hi_pun_8, temp.zmean.alc_hi_pun_9, temp.zmean.alc_hi_pun_10];

        temp2.zmean.collated_alc_hi_confrew_labels = [alc_hi_confrew_r_col, alc_hi_confrew_s_col, alc_hi_confrew_h_col, alc_hi_confrew_ses_col];
        temp2.zmean.collated_alc_hi_confrew = [temp.zmean.alc_hi_confrew_1, temp.zmean.alc_hi_confrew_2, temp.zmean.alc_hi_confrew_3, temp.zmean.alc_hi_confrew_4, temp.zmean.alc_hi_confrew_5, temp.zmean.alc_hi_confrew_6, temp.zmean.alc_hi_confrew_7, temp.zmean.alc_hi_confrew_8, temp.zmean.alc_hi_confrew_9, temp.zmean.alc_hi_confrew_10];
        temp2.zmean.collated_alc_hi_confpun_labels = [alc_hi_confpun_r_col, alc_hi_confpun_s_col, alc_hi_confpun_h_col, alc_hi_confpun_ses_col];
        temp2.zmean.collated_alc_hi_confpun = [temp.zmean.alc_hi_confpun_1, temp.zmean.alc_hi_confpun_2, temp.zmean.alc_hi_confpun_3, temp.zmean.alc_hi_confpun_4, temp.zmean.alc_hi_confpun_5, temp.zmean.alc_hi_confpun_6, temp.zmean.alc_hi_confpun_7, temp.zmean.alc_hi_confpun_8, temp.zmean.alc_hi_confpun_9, temp.zmean.alc_hi_confpun_10];


    else
    end


    sesdat.zmean = [];
    sesdat.zmean = [sesdat.zmean, temp2.zmean];

    save([filePath '\' files(i).name(1:end-4) '.mat'], 'sesdat')

    temp.zmean = [];
    temp2.zmean = [];

end
