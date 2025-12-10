%% NM updated for Conflict experiment 
%% UPDATED: Vectorized Extraction & Function-Based Plotting + Individual Session Plots
clear all
tankfolder = 'C:\Photometry\Conflict_04\Pun_(10-40)';
condition = 'Pun Late';
filePath = fullfile(tankfolder);

% --- Initialize Containers ---
Rew_Trial = [];
Rew_Trial_Omit = [];
Pun_Trial = [];
Pun_Trial_Omit = [];

% --- Session and Rat Definitions ---
if strcmp(condition,'Pun Early')
    included_sessions = {'P01','P02','P03'}; % 
else
    included_sessions = {'P04','P05','P06','P07'};
end
s = char(condition);

% Conf 04 Rats (Excluded R02, R09)
Rat = {'R01','R02','R05','R06','R07','R08','R09','R10','R11','R12','R13','R14'};
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];

%% 1. Vectorized Data Extraction & Individual Plotting
fprintf('Starting data extraction...\n');

for i = 1:length(files) 
    % Load data
    load(fullfile(filePath,  [files(i).name]), 'sesdat');
    
    rat = sesdat.rat;
    session = sesdat.ses;
    traces = sesdat.traces_z; % Extract for cleaner code
    
    % Check if this specific Rat and Session are in our include list
    if ismember(rat, Rat) && any(strcmp(session, included_sessions))
        fprintf('Processing %s - %s\n', rat, session);
        
        % --- Create Logical Masks ---
        valid_rows   = ~isnan(traces(:, 5));
        is_rew_block = traces(:, 2) == 1;
        is_pun_block = traces(:, 2) == 2;
        is_response  = traces(:, 4) == 1;
        is_omit      = traces(:, 4) == 0;
        
        % --- Extract Data for this specific file ---
        % We extract to temporary variables first to use for plotting,
        % then append to the main lists.
        curr_Rew_Resp = traces(valid_rows & is_rew_block & is_response, 5:end);
        curr_Rew_Omit = traces(valid_rows & is_rew_block & is_omit, 5:end);
        curr_Pun_Resp = traces(valid_rows & is_pun_block & is_response, 5:end);
        curr_Pun_Omit = traces(valid_rows & is_pun_block & is_omit, 5:end);
        
        % --- Append to Global Containers ---
        Rew_Trial      = [Rew_Trial;      curr_Rew_Resp];
        Rew_Trial_Omit = [Rew_Trial_Omit; curr_Rew_Omit];
        Pun_Trial      = [Pun_Trial;      curr_Pun_Resp];
        Pun_Trial_Omit = [Pun_Trial_Omit; curr_Pun_Omit];

        % =========================================================
        % NEW SECTION: Individual Session Plot
        % =========================================================
        
        % Define local time vector (adjust based on your column count)
        local_time = linspace(-10, 40, size(traces, 2) - 4); 
        
        figure('Name', [rat ' - ' session], 'NumberTitle', 'off', 'Color', 'w');
        hold on;
        title([rat ' | ' session ' | ' condition]);
        xlabel('Time (s)'); ylabel('Z-Score');
        
        % Plot lines (checking if data exists to avoid errors)
        h = []; lbl = {}; % Handles and Labels for legend
        
        if ~isempty(curr_Rew_Resp)
            h(end+1) = plot(local_time, mean(curr_Rew_Resp, 1), 'Color', [0.10, 0.60, 0.00], 'LineWidth', 2); % Green
            lbl{end+1} = ['Rew Resp (n=' num2str(size(curr_Rew_Resp,1)) ')'];
        end
        
        if ~isempty(curr_Rew_Omit)
            h(end+1) = plot(local_time, mean(curr_Rew_Omit, 1), 'Color', [0.00, 0.62, 1.00], 'LineWidth', 2); % Blue
            lbl{end+1} = ['Rew Omit (n=' num2str(size(curr_Rew_Omit,1)) ')'];
        end
        
        if ~isempty(curr_Pun_Resp)
            h(end+1) = plot(local_time, mean(curr_Pun_Resp, 1), 'Color', [1.0, 0, 0], 'LineWidth', 2); % Red
            lbl{end+1} = ['Pun Resp (n=' num2str(size(curr_Pun_Resp,1)) ')'];
        end
        
        if ~isempty(curr_Pun_Omit)
            h(end+1) = plot(local_time, mean(curr_Pun_Omit, 1), 'Color', [1.00, 0.50, 0.50], 'LineWidth', 2); % Pink
            lbl{end+1} = ['Pun Omit (n=' num2str(size(curr_Pun_Omit,1)) ')'];
        end
        
        % Add zero lines for reference
        y_lims = ylim;
        line([0, 0], y_lims, 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'HandleVisibility', 'off');
        line([local_time(1), local_time(end)], [0, 0], 'Color', [0.5 0.5 0.5], 'LineStyle', ':', 'HandleVisibility', 'off');
        
        legend(h, lbl, 'Location', 'best');
        hold off;
        % =========================================================
    end
end
fprintf('✅ Data extraction complete.\n');