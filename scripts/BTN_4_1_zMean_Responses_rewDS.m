%% Nathan Marchant July 2024
% Written for the conflict task
% This script will calculate the zMean for a given period, defined below

close all
clear all
close all

% define where the stuff is
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\rewDS_(25-15)';

% load invidivual session data
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
for i = 1:length(files) %iterate through experiment folder
    load(fullfile(filePath,  [files(i).name]))

    temp.zmean = [];
    temp2.zmean = [];

% get variables
    data = sesdat.traces_updated(:, 5:end);
    times = sesdat.traces_updated(:, 1:4);
    condition = sesdat.phase;
    r = sesdat.rat;
    sex = sesdat.sex;
    s1 = sesdat.ses;
    h = sesdat.hemi;
 
%define time, baseline etc
    time = linspace(-25, 15, size(data, 2)); %time vector the size of trace
    base = (time >= -25) & (time <= -20); %This is the time period of the trace for which the baseline is calculated
    lims1 = (time >= -10) & (time <= -0); %
    lims2 = (time >= -4) & (time <= -3); %
    lims3 = (time >= -3) & (time <= -2); %
    lims4 = (time >= -2) & (time <= -1); %
    lims5 = (time >= -1) & (time <= 0); %
    lims6 = (time >= 0) & (time <= 1.5); %
    lims7 = (time >= 1.5) & (time <= 3); %
    lims8 = (time >= 2) & (time <= 3); %
    lims9 = (time >= 3) & (time <= 4); %
    lims10 = (time >= 4) & (time <= 5); %
     
%% zscore standardisation on df/f
    zdata = zeros(size(data));
    zbase = zeros(size(data));
    tmp = 0;
        for m = 1:size(data, 1)
            zb = mean(data(m, base));
            zsd = std(data(m,base));
            for j = 1:size(data,2)
                tmp = tmp+1;
                zbase(m, tmp) = (data(m,j) -zb);
                zdata(m,tmp) = (data(m,j) - zb)/zsd;
            end
            tmp = 0;
        end
    zdata = [times, zdata];  


%calculate Rewarded Responses in rewDS trials  
    cdat = zdata(zdata(:,2) == 5 & zdata(:,4) == 1, 5:end); 
    temp.zmean.rew_1 = mean(cdat(:, lims1), 2);
    temp.zmean.rew_2 = mean(cdat(:, lims2), 2);
    temp.zmean.rew_3 = mean(cdat(:, lims3), 2);
    temp.zmean.rew_4 = mean(cdat(:, lims4), 2);
    temp.zmean.rew_5 = mean(cdat(:, lims5), 2);
    temp.zmean.rew_6 = mean(cdat(:, lims6), 2);
    temp.zmean.rew_7 = mean(cdat(:, lims7), 2);
    temp.zmean.rew_8 = mean(cdat(:, lims8), 2);
    temp.zmean.rew_9 = mean(cdat(:, lims9), 2);
    temp.zmean.rew_10 = mean(cdat(:, lims10), 2);
    % add rat, sec, hemi, to the respective values
        rew_r_col = [repmat({r}, size(cdat, 1),1)];
        rew_h_col = [repmat({h}, size(cdat, 1),1)];
        rew_s_col = [repmat({sex}, size(cdat, 1),1)];
        rew_ses_col = [repmat({s1}, size(cdat, 1),1)];         

    
%% save variables...
    temp2.zmean.collated_rew_labels = [rew_r_col, rew_s_col, rew_h_col, rew_ses_col];
    temp2.zmean.collated_rew = [temp.zmean.rew_1, temp.zmean.rew_2, temp.zmean.rew_3, temp.zmean.rew_4, temp.zmean.rew_5, temp.zmean.rew_6, temp.zmean.rew_7, temp.zmean.rew_8, temp.zmean.rew_9, temp.zmean.rew_10];
   
    sesdat.zmean = [];
    sesdat.zmean = [sesdat.zmean, temp2.zmean];
    
    save([filePath '\' files(i).name(1:end-4) '.mat'], 'sesdat')
 
    temp.zmean = [];
    temp2.zmean = [];

end
