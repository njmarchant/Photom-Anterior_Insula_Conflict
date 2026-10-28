%% HMM Analysis: Mean CueFull (Responded vs Omitted)
%  Goal: Plot mean 'mean_CueFull' grouped by State on X-axis, Cue in bars.
%  Layout: Subplot 1 = Responded, Subplot 2 = Omitted.

clear all; close all; clc;

%% --- 1. Load Data ---
path_excel = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Merged_dataframe_neural_plus_model.xlsx';

fprintf('Loading Excel Data...\n');
try
    T = readtable(path_excel);
catch ME
    error('Failed to load Excel file.\nError: %s', ME.message);
end

%% --- 2. ROBUST DATA CLEANING (Diagnostic & Normalization) ---
fprintf('Normalizing Data...\n');

% A. Clean Session
T.Session_Clean = strrep(string(T.Session), "'", ""); 

% B. Clean States
clean_states = strrep(string(T.Most_likely_state), "'", ""); 
clean_states = strrep(clean_states, '"', "");  
clean_states = strip(clean_states);            
T.Most_likely_state_Clean = clean_states;

% C. Clean Cues (Map "Rew"->1, "Pun"->2, "Conf"->3)
cue_num = nan(height(T), 1);
raw_cues = lower(string(T.Cue)); 

% Map variations
cue_num(contains(raw_cues, 'rew') | raw_cues == "1") = 1;
cue_num(contains(raw_cues, 'pun') | raw_cues == "2") = 2;
cue_num(contains(raw_cues, 'conf') | raw_cues == "3") = 3;
T.Cue_Num = cue_num;

% D. Clean Outcomes (Map "Omit"->0, "Resp"->1)
outcome_num = nan(height(T), 1);
raw_out = lower(string(T.Outcome_x));

for i = 1:height(T)
    val_str = raw_out(i);
    val_double = str2double(val_str);
    if ~isnan(val_double)
        outcome_num(i) = val_double;
    else
        if contains(val_str, 'omit') || contains(val_str, 'miss')
            outcome_num(i) = 0;
        elseif contains(val_str, 'resp') || contains(val_str, 'press')
            outcome_num(i) = 1;
        end
    end
end
T.Outcome_Num = outcome_num;

% E. Filter for C-sessions
c_mask = startsWith(T.Session_Clean, 'C1', 'IgnoreCase', true);
T_final = T(c_mask, :);

fprintf('Data Normalized. Rows after Session filter: %d\n', height(T_final));

%% --- 3. AGGREGATE DATA ---

[G_rats, RatIDs] = findgroups(T_final.Rat);
unique_rats = unique(G_rats);
n_rats = length(unique_rats);

% Categories
target_states = {'State_1', 'State_2', 'State_3'};
cues_to_find = [1, 2, 3]; 

% Storage: [Rat, Cue, Outcome, State]
RatMeans = nan(n_rats, 3, 2, 3);

for r = 1:n_rats
    rat_mask = (G_rats == unique_rats(r));
    
    for c = 1:3 % Loop Cues
        for o = 1:2 % Loop Outcome (1=Resp, 2=Omit)
            for s = 1:3 % Loop States
                
                mask_cue   = (T_final.Cue_Num == cues_to_find(c));
                mask_state = strcmpi(T_final.Most_likely_state_Clean, target_states{s});
                
                if o == 1 % Resp (>0)
                    mask_out = (T_final.Outcome_Num > 0);
                else      % Omit (==0)
                    mask_out = (T_final.Outcome_Num == 0);
                end
                
                total_mask = rat_mask & mask_cue & mask_state & mask_out;
                data = T_final.mean_CueFull(total_mask);
                
                if ~isempty(data)
                    RatMeans(r, c, o, s) = mean(data, 'omitnan');
                end
            end
        end
    end
end

fprintf('✅ Aggregation complete.\n');

%% --- 4. PREPARE PLOTTING DATA ---

% We need matrices: Rows = States (Groups), Cols = Cues (Bars)
% 1. Responded Data (Outcome index 1)
%    RatMeans is [Rat, Cue, Outcome, State]
%    Average over Rats -> [Cue, Outcome, State]
Mean_Rats = squeeze(mean(RatMeans, 1, 'omitnan')); 
SEM_Rats  = squeeze(std(RatMeans, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(RatMeans),1)));

% Extract specific slices and Transpose so that Rows=States, Cols=Cues
% Current: Mean_Rats(Cue, Outcome, State)
% Target:  (State, Cue)

% -- Responded (Outcome 1) --
Data_Resp = squeeze(Mean_Rats(:, 1, :))'; % Transpose to get [State x Cue]
Err_Resp  = squeeze(SEM_Rats(:, 1, :))';

% -- Omitted (Outcome 2) --
Data_Omit = squeeze(Mean_Rats(:, 2, :))'; % Transpose to get [State x Cue]
Err_Omit  = squeeze(SEM_Rats(:, 2, :))';

%% --- 5. PLOTTING ---

figure('Name', 'CueFull by State (Resp vs Omit)', 'Color', 'w', 'Position', [50, 50, 1200, 500]);

% Bar Colors (Cue Types)
% Rew = Green, Pun = Orange, Conf = Purple/Blue
cue_colors = [0.10, 0.60, 0.00;   % RewDS
              1.00, 0.45, 0.00;   % PunDS
              0.36, 0.32, 0.64];  % Conf

% --- SUBPLOT 1: RESPONDED ---
subplot(1, 2, 1);
b1 = bar(Data_Resp, 'grouped');

% Apply Colors
for k = 1:3
    b1(k).FaceColor = cue_colors(k, :);
end

hold on;
% Error Bars
[ngroups, nbars] = size(Data_Resp);
x = nan(nbars, ngroups);
for i = 1:nbars, x(i,:) = b1(i).XEndPoints; end
errorbar(x', Data_Resp, Err_Resp, 'k', 'linestyle', 'none', 'LineWidth', 1.5);

ylabel('Mean CueFull (Z-Score)');
title('Responded Trials');
xticks(1:3);
xticklabels({'State 1', 'State 2', 'State 3'});
grid on; box off;
% Unified Y-Limits calculation
all_vals = [Data_Resp(:); Data_Omit(:)];
all_errs = [Err_Resp(:); Err_Omit(:)];
y_max = max(all_vals + all_errs);
y_min = min(all_vals - all_errs);
if isempty(y_max) || isnan(y_max), y_max=1; end
if isempty(y_min) || isnan(y_min), y_min=-1; end
ylim([min(0, y_min*1.2), y_max*1.2]);


% --- SUBPLOT 2: OMITTED ---
subplot(1, 2, 2);
b2 = bar(Data_Omit, 'grouped');

% Apply Colors
for k = 1:3
    b2(k).FaceColor = cue_colors(k, :);
end

hold on;
% Error Bars
[ngroups, nbars] = size(Data_Omit);
x = nan(nbars, ngroups);
for i = 1:nbars, x(i,:) = b2(i).XEndPoints; end
errorbar(x', Data_Omit, Err_Omit, 'k', 'linestyle', 'none', 'LineWidth', 1.5);

title('Omitted Trials');
xticks(1:3);
xticklabels({'State 1', 'State 2', 'State 3'});
grid on; box off;
ylim([min(0, y_min*1.2), y_max*1.2]); % Use same Y-scale for comparison

% Legend (Only needed on one plot, or global)
legend({'RewDS', 'PunDS', 'Conflict'}, 'Location', 'northeast');

hold off;
fprintf('✅ Plots generated.\n');