%% Collate and Clean Z-Score Data for Alcohol Tests (UPDATED FOR DUAL SESSIONS)
close all; clear;

dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\alc_tests_(10-45)';
outputFolder = fullfile(dataFolder, 'combined_v2');
outputFileName = 'collated_ALC_TESTS_data_cleaned.mat';

collated_table = table();
filesAndFolders = dir(fullfile(dataFolder, '*.mat'));
files = filesAndFolders(~[filesAndFolders.isdir]);

disp(['Found ' num2str(length(files)) ' .mat files to process...']);

for i = 1:length(files)
    fprintf('Processing file %d of %d: %s...', i, length(files), files(i).name);
    load(fullfile(dataFolder, files(i).name), 'sesdat');
    
    if isfield(sesdat, 'zmean_table') && ~isempty(sesdat.zmean_table)
        temp_table = sesdat.zmean_table;
        
        % --- NEW: Extract Date ---
        if isfield(sesdat, 'date')
            temp_date = string(sesdat.date);
        else
            temp_date = "UnknownDate";
        end
        temp_table.Date = repmat(temp_date, height(temp_table), 1);
        
        collated_table = [collated_table; temp_table];
        fprintf(' Appended.\n');
    else
        fprintf(' WARNING: zmean_table not found or empty.\n');
    end
end

disp('All files processed. Now cleaning and sorting dates...');

if ~isempty(collated_table)
    
    % 1. Fix Rat strings
    if iscell(collated_table.Rat) || isstring(collated_table.Rat)
        collated_table.Rat = strrep(collated_table.Rat, '''', '');
    end
    
    % 2. Fix Cues and Responses
    if ismember('Cue', collated_table.Properties.VariableNames)
        cueCol = 'Cue';
    else
        cueCol = 'TrialType';
    end
    collated_table.(cueCol) = strrep(collated_table.(cueCol), 'rewDS', 'reward');
    collated_table.(cueCol) = strrep(collated_table.(cueCol), 'punDS', 'punish');
    collated_table.(cueCol) = strrep(collated_table.(cueCol), 'conf', 'conflict');

    if ismember('Response', collated_table.Properties.VariableNames)
        for j = 1:height(collated_table)
            currentCue = string(collated_table{j, cueCol});
            currentResp = string(collated_table.Response{j});
            if strcmp(currentResp, 'Response')
                if strcmp(currentCue, 'reward'), collated_table.Response{j} = 'Response-Pellet';
                elseif strcmp(currentCue, 'punish'), collated_table.Response{j} = 'Response-Shock';
                end
            end
        end
    end

    % --- NEW: SESSION ID GENERATION LOGIC ---
    % Rename old 'Session' to 'Session_Type'
    collated_table.Properties.VariableNames{'Session'} = 'Session_Type';
    
    % Convert dates to datetime for perfect chronological sorting
    try
        real_dates = datetime(collated_table.Date);
    catch
        real_dates = collated_table.Date; % Fallback if format is weird
    end
    collated_table.RealDate = real_dates;
    
    % Sort perfectly by Rat -> Session -> Chronological Date -> Trial Timestamp
    collated_table = sortrows(collated_table, {'Rat', 'Session_Type', 'RealDate', 'Timestamp'});
    
    % Generate Session_ID (e.g., 'Saline_1', 'Saline_2')
    collated_table.Session_ID = collated_table.Session_Type; % Init
    rats = unique(collated_table.Rat);
    session_types = unique(collated_table.Session_Type);
    
    for r = 1:length(rats)
        for s = 1:length(session_types)
            % Find rows for this Rat and this Session Type
            idx = strcmp(collated_table.Rat, rats{r}) & strcmp(collated_table.Session_Type, session_types{s});
            if any(idx)
                % Find the unique dates they ran this session
                unique_dates = unique(collated_table.RealDate(idx));
                for d = 1:length(unique_dates)
                    % Assign _1 or _2 chronologically
                    date_idx = idx & (collated_table.RealDate == unique_dates(d));
                    new_id = sprintf('%s_%d', session_types{s}, d);
                    collated_table.Session_ID(date_idx) = {new_id};
                end
            end
        end
    end
    collated_table.RealDate = []; % Clean up temp variable
    
    % Reorder columns nicely
    collated_table = movevars(collated_table, 'Session_ID', 'After', 'Session_Type');
    collated_table = movevars(collated_table, 'Date', 'After', 'Session_ID');

    %% Save Data
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    
    % Save structure
    collatedData = struct();
    collatedData.collated_zmean_table = collated_table;
    save(fullfile(outputFolder, outputFileName), 'collatedData');
    
    % Save CSV
    csvFileName = strrep(outputFileName, '.mat', '.csv');
    writetable(collated_table, fullfile(outputFolder, csvFileName));
    
    fprintf('CSV exported for Python to: %s\n', fullfile(outputFolder, csvFileName));
end
disp('Collation complete!');