%% Nathan Marchant July 2024
% Written for the conflict task
% This script will calculate the zMean for a given period, defined below

close all
clear all
close all

% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-30)';

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
    time = linspace(-10, 30, size(data, 2)); %time vector the size of trace
    base = (time >= -10) & (time <= -5); %This is the time period of the trace for which the baseline is calculated
    lims1 = (time >= -5) & (time <= 0); %limits of auc baseline - pre cues
    lims2 = (time >= 0) & (time <= 5); %limits - first 5s cues
    lims3 = (time >= 5) & (time <= 10); %limits - second 5s cues
    lims4 = (time >= 0) & (time <= 10); %limits - 10s cue period
    lims5 = (time >= 10) & (time <= 30); %limits - 20s lever period

    zdata = [];
    zdata = [times, data];  

    if strcmp(s1,'Saline')
%% __________________ SALINE SESSIONS ___________________________________

% calculate auc and mean in cue period from RESPONDED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1, 5:end); 
    temp.zmean.sal_rew_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1 & zdata(:,3), 3);

    temp.zmean.sal_rew_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_rew_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_rew_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_rew_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_rew_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        sal_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 0, 5:end); 

    temp.zmean.sal_rewO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_rewO_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_rewO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_rewO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_rewO_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        sal_rewO_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_rewO_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_rewO_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_rewO_ses_col = [repmat({s1}, size(cdat, 1),1)];
            

% calculate auc and mean in cue period from RESPONDED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 5:end);
    temp.zmean.sal_pun_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 3);

    temp.zmean.sal_pun_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_pun_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_pun_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_pun_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_pun_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        sal_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];
 

% calculate mean in cue period from OMITTED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 0, 5:end);

    temp.zmean.sal_punO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_punO_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_punO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_punO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_punO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        sal_punO_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_punO_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_punO_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_punO_ses_col = [repmat({s1}, size(cdat, 1),1)];

   
% calculate auc and mean in cue period from RESPONDED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 5:end);
    temp.zmean.sal_conf_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 3);

    temp.zmean.sal_conf_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_conf_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_conf_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_conf_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_conf_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        sal_conf_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_conf_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_conf_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_conf_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) == 0, 5:end);

    temp.zmean.sal_confO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.sal_confO_five = mean(cdat(:, lims2), 2);
    temp.zmean.sal_confO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.sal_confO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.sal_confO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        sal_confO_r_col = [repmat({r}, size(cdat, 1),1)];
        sal_confO_h_col = [repmat({h}, size(cdat, 1),1)];
        sal_confO_s_col = [repmat({sex}, size(cdat, 1),1)];
        sal_confO_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % save variables...
    % SALINE SESSIONS
    temp2.zmean.collated_sal_rew_labels = [sal_rew_r_col, sal_rew_s_col, sal_rew_h_col, sal_rew_ses_col];
    temp2.zmean.collated_sal_rew = [temp.zmean.sal_rew_lat, temp.zmean.sal_rew_BL, temp.zmean.sal_rew_five, temp.zmean.sal_rew_ten, temp.zmean.sal_rew_cue, temp.zmean.sal_rew_lever];
    temp2.zmean.collated_sal_rewO_labels = [sal_rewO_r_col, sal_rewO_s_col, sal_rewO_h_col, sal_rewO_ses_col];
    temp2.zmean.collated_sal_rewO = [temp.zmean.sal_rewO_BL, temp.zmean.sal_rewO_five, temp.zmean.sal_rewO_ten, temp.zmean.sal_rewO_cue, temp.zmean.sal_rewO_lever];

    temp2.zmean.collated_sal_pun_labels = [sal_pun_r_col, sal_pun_s_col, sal_pun_h_col, sal_pun_ses_col];
    temp2.zmean.collated_sal_pun = [temp.zmean.sal_pun_lat, temp.zmean.sal_pun_BL, temp.zmean.sal_pun_five, temp.zmean.sal_pun_ten, temp.zmean.sal_pun_cue, temp.zmean.sal_pun_lever];
    temp2.zmean.collated_sal_punO_labels = [sal_punO_r_col, sal_punO_s_col, sal_punO_h_col, sal_punO_ses_col];
    temp2.zmean.collated_sal_punO = [temp.zmean.sal_punO_BL, temp.zmean.sal_punO_five, temp.zmean.sal_punO_ten, temp.zmean.sal_punO_cue, temp.zmean.sal_punO_lever];

    temp2.zmean.collated_sal_conf_labels = [sal_conf_r_col, sal_conf_s_col, sal_conf_h_col, sal_conf_ses_col];
    temp2.zmean.collated_sal_conf = [temp.zmean.sal_conf_lat, temp.zmean.sal_conf_BL, temp.zmean.sal_conf_five, temp.zmean.sal_conf_ten, temp.zmean.sal_conf_cue, temp.zmean.sal_conf_lever];
    temp2.zmean.collated_sal_confO_labels = [sal_confO_r_col, sal_confO_s_col, sal_confO_h_col, sal_confO_ses_col];
    temp2.zmean.collated_sal_confO = [temp.zmean.sal_confO_BL, temp.zmean.sal_confO_five, temp.zmean.sal_confO_ten, temp.zmean.sal_confO_cue, temp.zmean.sal_confO_lever];

    % Count the rewDS, punDS, and conflict trials for the session
    respdat = [];
    respdat = zdata(zdata(:, 1) < 900 & zdata(:,2) < 4, 1:4);
    rew_tot = sum(respdat(:,2) == 1);
    rew_press = sum(respdat(:,2) == 1 & respdat(:,4) == 1);
    rew_percent = (rew_press/rew_tot);
    pun_tot = sum(respdat(:,2) == 2);
    pun_press = sum(respdat(:,2) == 2 & respdat(:,4) == 1);
    pun_percent = (pun_press/pun_tot);
    conf_tot = sum(respdat(:,2) == 3);
    conf_press = sum(respdat(:,2) == 3 & respdat(:,4) > 1);
    conf_percent = (conf_press/conf_tot);
    sesdat.responses = [rew_tot rew_press rew_percent;
                       pun_tot pun_press pun_percent;
                       conf_tot conf_press conf_percent];


    elseif strcmp(s1,'Alcohol_Low')
%% __________________ Alcohol Low SESSIONS ___________________________________

% calculate auc and mean in cue period from RESPONDED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1, 5:end); 
    temp.zmean.alc_low_rew_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1 & zdata(:,3), 3);

    temp.zmean.alc_low_rew_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_rew_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_rew_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_rew_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_rew_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        alc_low_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 0, 5:end); 

    temp.zmean.alc_low_rewO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_rewO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_rewO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_rewO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_rewO_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        alc_low_rewO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_rewO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_rewO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_rewO_ses_col = [repmat({s1}, size(cdat, 1),1)];
            

% calculate auc and mean in cue period from RESPONDED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 5:end);
    temp.zmean.alc_low_pun_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 3);

    temp.zmean.alc_low_pun_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_pun_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_pun_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_pun_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_pun_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];
 

% calculate mean in cue period from OMITTED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 0, 5:end);

    temp.zmean.alc_low_punO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_punO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_punO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_punO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_punO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_punO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_punO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_punO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_punO_ses_col = [repmat({s1}, size(cdat, 1),1)];

   
% calculate auc and mean in cue period from RESPONDED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 5:end);
    temp.zmean.alc_low_conf_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 3);

    temp.zmean.alc_low_conf_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_conf_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_conf_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_conf_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_conf_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_conf_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_conf_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_conf_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_conf_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) == 0, 5:end);

    temp.zmean.alc_low_confO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_low_confO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_low_confO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_low_confO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_low_confO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_low_confO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_low_confO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_low_confO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_low_confO_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % save variables...
    % ALC LOW SESSIONS
    temp2.zmean.collated_alc_low_rew_labels = [alc_low_rew_r_col, alc_low_rew_s_col, alc_low_rew_h_col, alc_low_rew_ses_col];
    temp2.zmean.collated_alc_low_rew = [temp.zmean.alc_low_rew_lat, temp.zmean.alc_low_rew_BL, temp.zmean.alc_low_rew_five, temp.zmean.alc_low_rew_ten, temp.zmean.alc_low_rew_cue, temp.zmean.alc_low_rew_lever];
    temp2.zmean.collated_alc_low_rewO_labels = [alc_low_rewO_r_col, alc_low_rewO_s_col, alc_low_rewO_h_col, alc_low_rewO_ses_col];
    temp2.zmean.collated_alc_low_rewO = [temp.zmean.alc_low_rewO_BL, temp.zmean.alc_low_rewO_five, temp.zmean.alc_low_rewO_ten, temp.zmean.alc_low_rewO_cue, temp.zmean.alc_low_rewO_lever];

    temp2.zmean.collated_alc_low_pun_labels = [alc_low_pun_r_col, alc_low_pun_s_col, alc_low_pun_h_col, alc_low_pun_ses_col];
    temp2.zmean.collated_alc_low_pun = [temp.zmean.alc_low_pun_lat, temp.zmean.alc_low_pun_BL, temp.zmean.alc_low_pun_five, temp.zmean.alc_low_pun_ten, temp.zmean.alc_low_pun_cue, temp.zmean.alc_low_pun_lever];
    temp2.zmean.collated_alc_low_punO_labels = [alc_low_punO_r_col, alc_low_punO_s_col, alc_low_punO_h_col, alc_low_punO_ses_col];
    temp2.zmean.collated_alc_low_punO = [temp.zmean.alc_low_punO_BL, temp.zmean.alc_low_punO_five, temp.zmean.alc_low_punO_ten, temp.zmean.alc_low_punO_cue, temp.zmean.alc_low_punO_lever];

    temp2.zmean.collated_alc_low_conf_labels = [alc_low_conf_r_col, alc_low_conf_s_col, alc_low_conf_h_col, alc_low_conf_ses_col];
    temp2.zmean.collated_alc_low_conf = [temp.zmean.alc_low_conf_lat, temp.zmean.alc_low_conf_BL, temp.zmean.alc_low_conf_five, temp.zmean.alc_low_conf_ten, temp.zmean.alc_low_conf_cue, temp.zmean.alc_low_conf_lever];
    temp2.zmean.collated_alc_low_confO_labels = [alc_low_confO_r_col, alc_low_confO_s_col, alc_low_confO_h_col, alc_low_confO_ses_col];
    temp2.zmean.collated_alc_low_confO = [temp.zmean.alc_low_confO_BL, temp.zmean.alc_low_confO_five, temp.zmean.alc_low_confO_ten, temp.zmean.alc_low_confO_cue, temp.zmean.alc_low_confO_lever];

    % Count the rewDS, punDS, and conflict trials for the session
    respdat = [];
    respdat = zdata(zdata(:, 1) < 900 & zdata(:,2) < 4, 1:4);
    rew_tot = sum(respdat(:,2) == 1);
    rew_press = sum(respdat(:,2) == 1 & respdat(:,4) == 1);
    rew_percent = (rew_press/rew_tot);
    pun_tot = sum(respdat(:,2) == 2);
    pun_press = sum(respdat(:,2) == 2 & respdat(:,4) == 1);
    pun_percent = (pun_press/pun_tot);
    conf_tot = sum(respdat(:,2) == 3);
    conf_press = sum(respdat(:,2) == 3 & respdat(:,4) > 1);
    conf_percent = (conf_press/conf_tot);
    sesdat.responses = [rew_tot rew_press rew_percent;
                       pun_tot pun_press pun_percent;
                       conf_tot conf_press conf_percent];

         elseif strcmp(s1,'Alcohol_High')
%% __________________ Alcohol High SESSIONS ___________________________________

% calculate auc and mean in cue period from RESPONDED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1, 5:end); 
    temp.zmean.alc_hi_rew_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 1 & zdata(:,3), 3);

    temp.zmean.alc_hi_rew_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_rew_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_rew_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_rew_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_rew_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        alc_hi_rew_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_rew_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_rew_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED reward trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 1 & zdata(:,4) == 0, 5:end); 

    temp.zmean.alc_hi_rewO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_rewO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_rewO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_rewO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_rewO_lever = mean(cdat(:, lims5), 2);
    % add rat, sec, hemi, to the respective values
        alc_hi_rewO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_rewO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_rewO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_rewO_ses_col = [repmat({s1}, size(cdat, 1),1)];
            

% calculate auc and mean in cue period from RESPONDED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 5:end);
    temp.zmean.alc_hi_pun_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 1, 3);

    temp.zmean.alc_hi_pun_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_pun_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_pun_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_pun_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_pun_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_pun_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_pun_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_pun_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_pun_ses_col = [repmat({s1}, size(cdat, 1),1)];
 

% calculate mean in cue period from OMITTED punishment trials  
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 2 & zdata(:,4) == 0, 5:end);

    temp.zmean.alc_hi_punO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_punO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_punO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_punO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_punO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_punO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_punO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_punO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_punO_ses_col = [repmat({s1}, size(cdat, 1),1)];

   
% calculate auc and mean in cue period from RESPONDED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 5:end);
    temp.zmean.alc_hi_conf_lat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) > 0, 3);

    temp.zmean.alc_hi_conf_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_conf_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_conf_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_conf_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_conf_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_conf_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_conf_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_conf_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_conf_ses_col = [repmat({s1}, size(cdat, 1),1)];

% calculate auc and mean in cue period from OMITTED conflict trials 
    cdat = zdata(zdata(:, 1) < 900 & zdata(:,2) == 3 & zdata(:,4) == 0, 5:end);

    temp.zmean.alc_hi_confO_BL = mean(cdat(:, lims1), 2);
    temp.zmean.alc_hi_confO_five = mean(cdat(:, lims2), 2);
    temp.zmean.alc_hi_confO_ten = mean(cdat(:, lims3), 2);
    temp.zmean.alc_hi_confO_cue = mean(cdat(:, lims4), 2);
    temp.zmean.alc_hi_confO_lever = mean(cdat(:, lims5), 2);
        % add rat, sec, hemi, to the respective values
        alc_hi_confO_r_col = [repmat({r}, size(cdat, 1),1)];
        alc_hi_confO_h_col = [repmat({h}, size(cdat, 1),1)];
        alc_hi_confO_s_col = [repmat({sex}, size(cdat, 1),1)];
        alc_hi_confO_ses_col = [repmat({s1}, size(cdat, 1),1)];

        % ALC HIGH SESSIONS
    temp2.zmean.collated_alc_hi_rew_labels = [alc_hi_rew_r_col, alc_hi_rew_s_col, alc_hi_rew_h_col, alc_hi_rew_ses_col];
    temp2.zmean.collated_alc_hi_rew = [temp.zmean.alc_hi_rew_lat, temp.zmean.alc_hi_rew_BL, temp.zmean.alc_hi_rew_five, temp.zmean.alc_hi_rew_ten, temp.zmean.alc_hi_rew_cue, temp.zmean.alc_hi_rew_lever];
    temp2.zmean.collated_alc_hi_rewO_labels = [alc_hi_rewO_r_col, alc_hi_rewO_s_col, alc_hi_rewO_h_col, alc_hi_rewO_ses_col];
    temp2.zmean.collated_alc_hi_rewO = [temp.zmean.alc_hi_rewO_BL, temp.zmean.alc_hi_rewO_five, temp.zmean.alc_hi_rewO_ten, temp.zmean.alc_hi_rewO_cue, temp.zmean.alc_hi_rewO_lever];

    temp2.zmean.collated_alc_hi_pun_labels = [alc_hi_pun_r_col, alc_hi_pun_s_col, alc_hi_pun_h_col, alc_hi_pun_ses_col];
    temp2.zmean.collated_alc_hi_pun = [temp.zmean.alc_hi_pun_lat, temp.zmean.alc_hi_pun_BL, temp.zmean.alc_hi_pun_five, temp.zmean.alc_hi_pun_ten, temp.zmean.alc_hi_pun_cue, temp.zmean.alc_hi_pun_lever];
    temp2.zmean.collated_alc_hi_punO_labels = [alc_hi_punO_r_col, alc_hi_punO_s_col, alc_hi_punO_h_col, alc_hi_punO_ses_col];
    temp2.zmean.collated_alc_hi_punO = [temp.zmean.alc_hi_punO_BL, temp.zmean.alc_hi_punO_five, temp.zmean.alc_hi_punO_ten, temp.zmean.alc_hi_punO_cue, temp.zmean.alc_hi_punO_lever];

    temp2.zmean.collated_alc_hi_conf_labels = [alc_hi_conf_r_col, alc_hi_conf_s_col, alc_hi_conf_h_col, alc_hi_conf_ses_col];
    temp2.zmean.collated_alc_hi_conf = [temp.zmean.alc_hi_conf_lat, temp.zmean.alc_hi_conf_BL, temp.zmean.alc_hi_conf_five, temp.zmean.alc_hi_conf_ten, temp.zmean.alc_hi_conf_cue, temp.zmean.alc_hi_conf_lever];
    temp2.zmean.collated_alc_hi_confO_labels = [alc_hi_confO_r_col, alc_hi_confO_s_col, alc_hi_confO_h_col, alc_hi_confO_ses_col];
    temp2.zmean.collated_alc_hi_confO = [temp.zmean.alc_hi_confO_BL, temp.zmean.alc_hi_confO_five, temp.zmean.alc_hi_confO_ten, temp.zmean.alc_hi_confO_cue, temp.zmean.alc_hi_confO_lever];
    
    % Count the rewDS, punDS, and conflict trials for the session
    respdat = [];
    respdat = zdata(zdata(:, 1) < 900 & zdata(:,2) < 4, 1:4);
    rew_tot = sum(respdat(:,2) == 1);
    rew_press = sum(respdat(:,2) == 1 & respdat(:,4) == 1);
    rew_percent = (rew_press/rew_tot);
    pun_tot = sum(respdat(:,2) == 2);
    pun_press = sum(respdat(:,2) == 2 & respdat(:,4) == 1);
    pun_percent = (pun_press/pun_tot);
    conf_tot = sum(respdat(:,2) == 3);
    conf_press = sum(respdat(:,2) == 3 & respdat(:,4) > 1);
    conf_percent = (conf_press/conf_tot);
    sesdat.responses = [rew_tot rew_press rew_percent;
                       pun_tot pun_press pun_percent;
                       conf_tot conf_press conf_percent];
    else
    end
    

    sesdat.zmean = [];
    sesdat.zmean = [sesdat.zmean, temp2.zmean];

    
    folderName = strcat(tankfolder,'\Alc_Tests By Half\First 15 min');
    if ~isfolder(folderName)  % Check if the folder does not exist
        mkdir(folderName);  % Create the folder
        save([folderName '\' files(i).name(1:end-4) '.mat'], 'sesdat')
    else
        save([folderName '\' files(i).name(1:end-4) '.mat'], 'sesdat')
    end
    
 
    temp.zmean = [];
    temp2.zmean = [];

end
