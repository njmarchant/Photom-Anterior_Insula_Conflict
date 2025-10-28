%% Nathan Marchant July 2024
% Written for the conflict task
% A script to make changes in traces, combine them, or add extra info
% zScoring of the traces is also added at the end of this script
clear all
close all

%% define where the stuff is

tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(25-15)';

%% define timestamps you wanna work with
%!!!! REMEMBER TO CHECK THE NAMES OF THE VARIABBLES ON SESDAT
var1 = {'B1R','B2R','B3R','B4R'}; %Reward trial start, all boxes
var2 = {'B1P','B2P','B3P','B4P'}; %Punish Trial start, all boxes
var3 = {'B1L','B2L','B3L','B4L'}; %Lever press, all boxes
var4 = {'B1F','B2F','B3F','B4F'}; %Food outcome, all boxes
var5 = {'B1S','B2S','B3S','B4S'}; %shock outcone, all boxes


%% load individual session data
filePath = fullfile(tankfolder);
files = dir(fullfile(filePath));
files(ismember({files.name}, {'.', '..'})) = [];
files = files(~[files.isdir]);
for i = 1:length(files) %iterate through experiment folder
%     if strfind(files(i).name, r)
    if isfile(fullfile(filePath,  [files(i).name]))
        load(fullfile(filePath,  [files(i).name]))

    v1 = [];
    v1R = [];
    v1L = [];
    v1P = [];
    v1S = [];
    v1F = [];
    v1RPC = [];

    %Code Reward cue trial start as 1 in second column
    for j = 1:length(var1)
        if any(contains(sesdat.traces(:,1), var1(j)))
            v1R = cell2mat(sesdat.traces(contains(sesdat.traces(:,1), var1), 2));
            v1R(:,2) = 1;
        end
    end
    
    %Code Punish cue trial start as 2 in second column
    for j = 1:length(var2)
        if any(contains(sesdat.traces(:,1), var2(j)))
            v1P = cell2mat(sesdat.traces(contains(sesdat.traces(:,1), var2),2));
            v1P(:,2) = 2;
        end
    end

    %Conflict trial start = change value in second column to 3 for conflict
    %trials (will need to avoid doubles?)
    for j = 1:size(v1R,1)
        for k = 1:size(v1P,1)
            TrialStartR = v1R(j,1);
            TrialStartP = v1P(k,1);
            if TrialStartR == TrialStartP
                v1R(j,2) = 3;
            else
                
            end
        end
    end

    for j = 1:size(v1P,1)
        for k = 1:size(v1R,1)
            TrialStartR = v1R(k,1);
            TrialStartP = v1P(j,1);
            if TrialStartR == TrialStartP
                v1P(j,2) = 3;
            else
                
            end
        end
    end

    %combine rew and pun array
    v1RPCtmp = [v1R; v1P];
    % Sort based on the first column
    v1RPCtmp = sortrows(v1RPCtmp, 1);
    % Find and remove duplicates based on the first column
    [~, uniqueIdx, ~] = unique(v1RPCtmp(:, 1), 'stable');
    % Create a new array with unique rows
    v1RPC = v1RPCtmp(uniqueIdx, :);
    %Code Lever Press as 4 in second column
    for j = 1:length(var3)
        if any(contains(sesdat.traces(:,1), var3(j)))
            v1L = cell2mat(sesdat.traces(contains(sesdat.traces(:,1), var3),2));
            v1L(:,2) = 4;
        end
    end

    %Code Food outcome as 5 in second column
    for j = 1:length(var4)
        if any(contains(sesdat.traces(:,1), var4(j)))
            v1F = cell2mat(sesdat.traces(contains(sesdat.traces(:,1), var4),2));
            v1F(:,2) = 5;
        end
    end
    
    %Code shock outcome as 6 in second column
    for j = 1:length(var5)
        if any(contains(sesdat.traces(:,1), var5(j)))
            v1S = cell2mat(sesdat.traces(contains(sesdat.traces(:,1), var5),2));
            v1S(:,2) = 6;
        end
    end

    arrays = {v1RPC,v1L,v1F,v1S};
    for j = 1:length(arrays)
        if ~isempty(arrays{j})
            if isempty(v1)
                v1= arrays{j};
            else
                v1 = cat(1, v1, arrays{j});
            end
        end
    end
 
    if ~isempty(v1)
        for k = 1:length(v1(:,1))-1
            if v1(k, 2) == 3 && v1(k+1,1) < v1(k, 1)+15
                    v1(k+ 1,3) = 1;
            elseif v1(k, 2) ~=3 && v1(k+1, 1) < v1(k, 1)+5
                v1(k+1,3) = 2;
            else
                continue
            end
        end
    end      

    % split the v1 array 
    %   trials (1,2,3) go into v2
    %   responses (4,5,6) go into v3
    v2 = [];
    v2 = v1(ismember(v1(:, 2), [5, 6]), :);   %put the RESPONSE times in v2 array
    v2 = sortrows(v2,1);
    
    v3 = [];
    v3 = v1(ismember(v1(:, 2), [1, 2,3]), :);   %put the TRIAL times in v3 array
    v3 = sortrows(v3,1);

    tmpRSP = nan(size(v3,1), 4);

    v4 = [];
    v4 = v1(ismember(v1(:, 2), [4]), :);   %put the lever press times in v3 array
    v4 = sortrows(v4,1);

    %_______________________Code the trials with the latency (column 3) and outcome (column 4)_______________  
    % column4 = (Response in Rew or Pun = 1 Trial omit = 0; In conflict, Response + food = 2; Response + shock = 3)
        
    for j = 1:size(v3,1)
        for k = 1:size(v2)
            TrialStart = v3(j,1);
            Choice_Time = v2(k);
            if Choice_Time-TrialStart > 10 && Choice_Time-TrialStart < 40 && v3(j,3) ==0  
                if v3(j,2) == 1 || v3(j,2) == 2
                    v3(j,3) = Choice_Time-TrialStart-10;
                    v3(j,4) = 1;
                    break
                else % then v1(j,2) should == 3 for conflict
                    if v2(k,2) == 5 % for food outcome
                        v3(j,3) = Choice_Time-TrialStart-10;
                        v3(j,4) = 2;
                        break
                    else % then tmp(k,2) should == 6 for shock outcome
                        v3(j,3) = Choice_Time-TrialStart-10;
                        v3(j,4) = 3;
                        break
                    end
                end
            else
                
            end
            
        end
    end


     %_______________________Code the Responses with the trial type (column 4) _______________  
    % column 4 = (Response in Rew = 1 Pun = 2; Conf = 3)

    for j = 1:size(v2,1)
        Choice_Time = v2(j,1);
        for k = 1:size(v3)
            TrialStart = v3(k);
            if Choice_Time-TrialStart > 10 && Choice_Time-TrialStart < 35 
                v2(j,3) = Choice_Time-TrialStart-10;
                v2(j,4) = v3(k,2);
                break
            end    
        end
    end
    
           
   
%Put everything back into sesdat
    sesdat.traces_updated = [v3;v2;v4];

    %%
    % Count the rewDS, punDS, and conflict trials for the session
    rew_tot = sum(sesdat.traces_updated(:,2) == 1);
    rew_press = sum(sesdat.traces_updated(:,2) == 1 & sesdat.traces_updated(:,4) == 1);
    rew_percent = (rew_press/rew_tot);
    pun_tot = sum(sesdat.traces_updated(:,2) == 2);
    pun_press = sum(sesdat.traces_updated(:,2) == 2 & sesdat.traces_updated(:,4) == 1);
    pun_percent = (pun_press/pun_tot);
    conf_tot = sum(sesdat.traces_updated(:,2) == 3);
    conf_press = sum(sesdat.traces_updated(:,2) == 3 & sesdat.traces_updated(:,4) > 1);
    conf_percent = (conf_press/conf_tot);
    sesdat.responses = [rew_tot rew_press rew_percent;
                       pun_tot pun_press pun_percent;
                       conf_tot conf_press conf_percent];
    
%% 
% Here we perform z-score calulations of the traces. 
% Trace data is taken from 'sesdat.traces_updated' and after conversion
% this data is saved in 'sesdat.traces_z';

% variables to save
    sesdat.traces_z = [];
% get variables
    data = sesdat.traces_updated(:, 5:end);
    times = sesdat.traces_updated(:, 1:4);
    % dat.rat = r;
    % dat.sesdat = sesdat;
       
%define time, baseline
% Ensure that this matches what is extracted in the first script!
    time = linspace(-25, 15, size(data, 2)); %time vector the size of trace
    base = (time >= -25) & (time <= -10); %This is the time period of the trace for which the baseline is calculated
     
% zscore standardisation on df/f
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
    traces_z = [times, zdata];  
    sesdat.traces_z = [sesdat.traces_z;traces_z];

% save file (overwrites previous file, so be careful not to change
% anything)
    save([filePath '\' files(i).name(1:end-4) '.mat'], 'sesdat')

    end
end