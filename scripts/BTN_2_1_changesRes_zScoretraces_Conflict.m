%% Nathan Marchant July 2024
% Written for the conflict task
% A script to make changes in traces, combine them, or add extra info
% zScoring of the traces is also added at the end of this script
% Updated to dynamically loop through multiple trace lengths

clear all
close all
%% define where the stuff is
% Removed the specific time window from the folder path
tankfolder = 'C:\Photometry\Conflict_06\Pun'; 

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
    if isfile(fullfile(filePath,  [files(i).name]))
        load(fullfile(filePath,  [files(i).name]))
        
        % --- Find all fields in sesdat that match the 'traces_X_Y' pattern ---
        all_fields = fieldnames(sesdat);
        % Filter for fields that start with 'traces_' 
        trace_fields = all_fields(startsWith(all_fields, 'traces_') & ...
                                 ~startsWith(all_fields, 'traces_updated') & ...
                                 ~startsWith(all_fields, 'traces_z'));
        
        % --- Loop through each trace length found in the file ---
        for t_idx = 1:length(trace_fields)
            current_field = trace_fields{t_idx}; % e.g., 'traces_10_45'
            current_traces = sesdat.(current_field);
            
            % Extract the pre and post time from the field name using regular expressions
            tokens = regexp(current_field, 'traces_(\d+)_(\d+)', 'tokens');
            if isempty(tokens)
                continue; % Skip if it doesn't match the exact pattern
            end
            pre_time = str2double(tokens{1}{1});
            post_time = str2double(tokens{1}{2});
            
            fprintf('Processing %s for trace window -%d to +%d...\n', files(i).name, pre_time, post_time);
            
            % Initialize variables for THIS specific trace loop
            v1 = []; v1R = []; v1L = []; v1P = []; v1S = []; v1F = []; v1RPC = [];
            
            %Code Reward cue trial start as 1 in second column
            for j = 1:length(var1)
                if any(contains(current_traces(:,1), var1(j)))
                    v1R = cell2mat(current_traces(contains(current_traces(:,1), var1), 2));
                    v1R(:,2) = 1;
                end
            end
            %Code Punish cue trial start as 2 in second column
            for j = 1:length(var2)
                if any(contains(current_traces(:,1), var2(j)))
                    v1P = cell2mat(current_traces(contains(current_traces(:,1), var2),2));
                    v1P(:,2) = 2;
                end
            end
            %Conflict trial start = change value in second column to 3 for conflict
            for j = 1:size(v1R,1)
                for k = 1:size(v1P,1)
                    TrialStartR = v1R(j,1);
                    TrialStartP = v1P(k,1);
                    if TrialStartR == TrialStartP
                        v1R(j,2) = 3;
                    end
                end
            end
            for j = 1:size(v1P,1)
                for k = 1:size(v1R,1)
                    TrialStartR = v1R(k,1);
                    TrialStartP = v1P(j,1);
                    if TrialStartR == TrialStartP
                        v1P(j,2) = 3;
                    end
                end
            end
            
            %combine rew and pun array
            v1RPCtmp = [v1R; v1P];
            if ~isempty(v1RPCtmp)
                v1RPCtmp = sortrows(v1RPCtmp, 1);
                [~, uniqueIdx, ~] = unique(v1RPCtmp(:, 1), 'stable');
                v1RPC = v1RPCtmp(uniqueIdx, :);
            end
            
            %Code Lever Press as 4 in second column
            for j = 1:length(var3)
                if any(contains(current_traces(:,1), var3(j)))
                    v1L = cell2mat(current_traces(contains(current_traces(:,1), var3),2));
                    v1L(:,2) = 4;
                end
            end
            %Code Food outcome as 5 in second column
            for j = 1:length(var4)
                if any(contains(current_traces(:,1), var4(j)))
                    v1F = cell2mat(current_traces(contains(current_traces(:,1), var4),2));
                    v1F(:,2) = 5;
                end
            end
            %Code shock outcome as 6 in second column
            for j = 1:length(var5)
                if any(contains(current_traces(:,1), var5(j)))
                    v1S = cell2mat(current_traces(contains(current_traces(:,1), var5),2));
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
                    end
                end
            end   
            
            % split the v1 array 
            v2 = v1(ismember(v1(:, 2), [5, 6]), :);   
            v2 = sortrows(v2,1);
            
            v3 = v1(ismember(v1(:, 2), [1, 2,3]), :);   
            v3 = sortrows(v3,1);
            
            v4 = v1(ismember(v1(:, 2), [4]), :);   
            v4 = sortrows(v4,1);
            
            % Code the trials with the latency and outcome
            for j = 1:size(v3,1)
                for k = 1:size(v2,1)
                    TrialStart = v3(j,1);
                    Choice_Time = v2(k,1); % Fixed indexing
                    if Choice_Time-TrialStart > 10 && Choice_Time-TrialStart < 40 && v3(j,3) ==0  
                        if v3(j,2) == 1 || v3(j,2) == 2
                            v3(j,3) = Choice_Time-TrialStart-10;
                            v3(j,4) = 1;
                            break
                        else 
                            if v2(k,2) == 5 
                                v3(j,3) = Choice_Time-TrialStart-10;
                                v3(j,4) = 2;
                                break
                            else 
                                v3(j,3) = Choice_Time-TrialStart-10;
                                v3(j,4) = 3;
                                break
                            end
                        end
                    end
                end
            end
            
            % Code the Responses with the trial type
            for j = 1:size(v2,1)
                Choice_Time = v2(j,1);
                for k = 1:size(v3,1)
                    TrialStart = v3(k,1); % Fixed indexing
                    if Choice_Time-TrialStart > 10 && Choice_Time-TrialStart < 35 
                        v2(j,3) = Choice_Time-TrialStart-10;
                        v2(j,4) = v3(k,2);
                        break
                    end    
                end
            end
            
            % --- Dynamically save updated traces ---
            updated_name = sprintf('traces_updated_%d_%d', pre_time, post_time);
            sesdat.(updated_name) = [v3;v2;v4];
            
                        
            %% Z-Score Calculations
            % get variables dynamically
            data = sesdat.(updated_name)(:, 5:end);
            times = sesdat.(updated_name)(:, 1:4);
               
            % --- Dynamic Baseline Calculation ---
            % Automatically takes the first 5 seconds of the pre-trial window
            time_vector = linspace(-pre_time, post_time, size(data, 2)); 
            base = (time_vector >= -pre_time) & (time_vector <= -pre_time + 5); 
                 
            % zscore standardisation on df/f
            zdata = zeros(size(data));
            zbase = zeros(size(data));

            for m = 1:size(data, 1)
                if sum(~isnan(data(m,base))) < 0.5*sum(base)
                    zdata(m,:) = NaN; zbase(m,:) = NaN; continue
                end
                zb  = mean(data(m, base), 'omitnan');
                zsd = std(data(m, base), 'omitnan');
                for j = 1:size(data,2)
                    zbase(m, j) = (data(m,j) - zb);
                    zdata(m, j) = (data(m,j) - zb) / zsd;
                end
            end
            
            % Dynamically save z-scored traces
            z_name = sprintf('traces_z_%d_%d', pre_time, post_time);
            sesdat.(z_name) = [times, zdata];  
            
        end % End of the trace_fields loop
        %% Count trials and save responses array
            rew_tot = sum(sesdat.(updated_name)(:,2) == 1);
            rew_press = sum(sesdat.(updated_name)(:,2) == 1 & sesdat.(updated_name)(:,4) == 1);
            rew_percent = (rew_press/rew_tot);
            
            pun_tot = sum(sesdat.(updated_name)(:,2) == 2);
            pun_press = sum(sesdat.(updated_name)(:,2) == 2 & sesdat.(updated_name)(:,4) == 1);
            pun_percent = (pun_press/pun_tot);
            
            conf_tot = sum(sesdat.(updated_name)(:,2) == 3);
            conf_press = sum(sesdat.(updated_name)(:,2) == 3 & sesdat.(updated_name)(:,4) > 1);
            conf_percent = (conf_press/conf_tot);
            
            response_name = sprintf('responses');
            sesdat.(response_name) = [rew_tot rew_press rew_percent;
                                      pun_tot pun_press pun_percent;
                                      conf_tot conf_press conf_percent];

        % Save file with all dynamically generated structures inside
        save(fullfile(filePath, files(i).name), 'sesdat')
    end
end