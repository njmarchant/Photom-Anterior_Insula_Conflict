%% BTN_3_1_Trials_Operant_punDS.m  --  Conflict 02bc (operant)
% Punishment phase: rewDS vs punDS trials, responded and omitted.
% Subject means with a minimum-trial threshold.
%
% Early / late punishment sessions are defined PER RAT from the
% Master Lab Journal (Master_Labjournal_Sessions.csv), because rats did
% not all complete the same number of punishment sessions:
%   R09 R10 R13 R14 R16 : P01-P15  (cohort 1, started 07/03/2024)
%   R12 R15             : P01-P10  (started 14/03/2024)
%   R11                 : P01-P06  (started 29/03/2024)
%   R17-R24             : P01-P10  (cohort 2, started 27/05/2024)
%
% 'Pun Early' = each rat's first n_sessions punishment sessions
% 'Pun Late'  = each rat's last  n_sessions punishment sessions
% 'Pun All'   = every punishment session

%% 1. Configuration & Setup
clear all
tankfolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\punDS_(10-45)';
filePath = fullfile(tankfolder);

% --- SWITCH HERE ---------------------------------------------------------
condition  = 'Pun Early';   % 'Pun Early' | 'Pun Late' | 'Pun All'
n_sessions = 3;            % sessions per block (first N / last N)
% -------------------------------------------------------------------------
s = char(condition);

% Rats included. R18 and R21 removed (no reliable signal on daily traces).
Rat = {'R09','R10','R11','R12','R13','R14','R15','R16','R17', ...
       'R19','R20','R22','R23','R24'};

% Number of punishment sessions per rat, from the Master Lab Journal
nPun = containers.Map( ...
    {'R09','R10','R11','R12','R13','R14','R15','R16', ...
     'R17','R18','R19','R20','R21','R22','R23','R24'}, ...
    [ 15,   15,    6,   10,   15,   15,   10,   15, ...
      10,   10,   10,   10,   10,   10,   10,   10 ]);

% Analysis Parameters
min_trials = 1;  % Minimum number of trials required per rat to be included

% Colours (RGB / 255)
c_rewDS = [0.12, 0.80, 0.01];
c_punDS = [0.87, 0.01, 0.12];
c_conf  = [0.01, 0.11, 0.86];
c_perm  = [0.5, 0.5, 0.5];

%% 2. Build per-rat session lists
fprintf('Condition: %s (n_sessions = %d)\n', s, n_sessions);
ratSessions = struct();
for r = 1:numel(Rat)
    n = nPun(Rat{r});
    switch condition
        case 'Pun Early'
            idx = 1:min(n_sessions, n);
        case 'Pun Late'
            idx = max(1, n - n_sessions + 1):n;
        case 'Pun All'
            idx = 1:n;
        otherwise
            error('condition must be ''Pun Early'', ''Pun Late'' or ''Pun All''.');
    end
    if ~strcmp(condition, 'Pun All') && 2*n_sessions > n
        warning('%s has only %d punishment sessions: early and late blocks overlap.', ...
            Rat{r}, n);
    end
    ratSessions.(Rat{r}) = arrayfun(@(k) sprintf('P%02d', k), idx, 'UniformOutput', false);
    fprintf('  %s: %s\n', Rat{r}, strjoin(ratSessions.(Rat{r}), ', '));
end

%% 3. Initialize Data Structures
RatData = struct();
for r = 1:length(Rat)
    RatData.(Rat{r}).Rew_Trial_Press = [];
    RatData.(Rat{r}).Pun_Trial_Press = [];
    RatData.(Rat{r}).Rew_Trial_Omit  = [];
    RatData.(Rat{r}).Pun_Trial_Omit  = [];
    RatData.(Rat{r}).Sessions_Found  = {};
end

%% 4. Load and Extract Traces
fprintf('Loading and extracting data...\n');
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]);
files(ismember({files.name}, {'.', '..'})) = [];

for i = 1:length(files)
    load(fullfile(filePath, files(i).name), 'sesdat');
    if ~exist('sesdat', 'var'), continue; end

    rat     = char(strrep(string(sesdat.rat), '''', ''));
    session = char(strtrim(string(sesdat.ses)));

    % Inclusion: rat in list AND session in that rat's block
    if ~isfield(ratSessions, rat) || ~ismember(session, ratSessions.(rat))
        clear sesdat; continue;
    end

    % Older Conflict 02 folders use traces_z; newer extractions use traces_z_10_45
    if isfield(sesdat, 'traces_z_10_45')
        tr = sesdat.traces_z_10_45;
    else
        tr = sesdat.traces_z;
    end

    fprintf('  -> Adding %s - %s\n', rat, session);
    RatData.(rat).Sessions_Found{end+1} = session;

    valid_rows = ~isnan(tr(:, 5));   % Ignore rows with NaN
    is_press   = tr(:, 4) == 1;      % Col 4 = 1 (Press)
    is_omit    = tr(:, 4) == 0;      % Col 4 = 0 (Omitted)
    is_rew     = tr(:, 2) == 1;      % Col 2 = 1 (Reward Cue)
    is_pun     = tr(:, 2) == 2;      % Col 2 = 2 (Punishment Cue)

    % Responded trials: -10 to +10 s (cols 5:323)
    RatData.(rat).Rew_Trial_Press = [RatData.(rat).Rew_Trial_Press; tr(valid_rows & is_rew & is_press, 5:323)];
    RatData.(rat).Pun_Trial_Press = [RatData.(rat).Pun_Trial_Press; tr(valid_rows & is_pun & is_press, 5:323)];

    % Omitted trials: full -10 to +45 s window
    RatData.(rat).Rew_Trial_Omit  = [RatData.(rat).Rew_Trial_Omit;  tr(valid_rows & is_rew & is_omit, 5:end)];
    RatData.(rat).Pun_Trial_Omit  = [RatData.(rat).Pun_Trial_Omit;  tr(valid_rows & is_pun & is_omit, 5:end)];

    clear sesdat
end

% --- QC: report expected sessions that were not found in the folder ---
fprintf('\nSession check:\n');
for r = 1:numel(Rat)
    missing = setdiff(ratSessions.(Rat{r}), RatData.(Rat{r}).Sessions_Found);
    if ~isempty(missing)
        fprintf('  [!] %s missing: %s\n', Rat{r}, strjoin(missing, ', '));
    end
end

%% 5. Calculate Subject Means with Minimum Trial Constraint
fprintf('Calculating Subject Means (Minimum %d trials required)...\n', min_trials);
conds = {'Rew_Trial_Press', 'Pun_Trial_Press', 'Rew_Trial_Omit', 'Pun_Trial_Omit'};
GroupData = struct();
for c = 1:numel(conds), GroupData.(conds{c}) = []; end

for i = 1:length(Rat)
    for c = 1:numel(conds)
        traces = RatData.(Rat{i}).(conds{c});
        if size(traces, 1) >= min_trials
            GroupData.(conds{c}) = [GroupData.(conds{c}); mean(traces, 1, 'omitnan')];
        end
    end
end

for c = 1:numel(conds)
    fprintf('  %-16s n = %d rats\n', conds{c}, size(GroupData.(conds{c}), 1));
end

%% 6. Plotting via Function Call
fprintf('Generating Plots...\n');

if ~isempty(GroupData.Rew_Trial_Press)
    time_press = linspace(-10, 10, size(GroupData.Rew_Trial_Press, 2));
else
    error('No Responded trials met the minimum criteria. Check extraction parameters.');
end

if ~isempty(GroupData.Pun_Trial_Omit)
    time_omit = linspace(-10, 45, size(GroupData.Pun_Trial_Omit, 2));
else
    error('No Omit trials met the minimum criteria. Check extraction parameters.');
end

% Stats
p_val = 0.05;
thres = 8;

% Pressed Reward vs Pressed Punishment
y_limits = [-2 3];
plot_title = ['Responses - ', s];
sig_windows_1 = createComparisonPlot( ...
    GroupData.Rew_Trial_Press, GroupData.Pun_Trial_Press, ...
    'rewDS Responded', 'punDS Responded', ...
    c_rewDS, c_punDS, c_perm, ...
    plot_title, time_press, p_val, thres, y_limits);

% Omitted Reward vs Omitted Punishment
y_limits = [-2 4];
plot_title = ['Omissions - ', s];
sig_windows_2 = createComparisonPlot( ...
    GroupData.Rew_Trial_Omit, GroupData.Pun_Trial_Omit, ...
    'rewDS Omitted', 'punDS Omitted', ...
    c_rewDS, c_punDS, c_perm, ...
    plot_title, time_omit, p_val, thres, y_limits);

disp('Significant Time Windows:');
disp(sig_windows_1);
disp(sig_windows_2);

fprintf('Script Complete.\n');