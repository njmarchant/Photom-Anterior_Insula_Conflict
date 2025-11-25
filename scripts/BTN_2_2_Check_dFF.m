%% Plot Full Session Traces with Events
% This script iterates through a folder of session files.
% For each session, it plots the entire 'lp_dFF' trace and overlays
% event markers taken from column 1 of 'traces_z'.
% --- Initialization ---
clear all;
close all;
% Define the folder to iterate through
tankfolder = 'C:\Photometry\Conflict_04\Pun';
filePath = fullfile(tankfolder);
filesAndFolders = dir(fullfile(filePath));
files = filesAndFolders(~[filesAndFolders.isdir]); 
files(ismember({files.name}, {'.', '..'})) = [];
fprintf('Loading data from folder: %s\n', tankfolder);
% --- Loop Through Files and Plot ---
for i = 1:length(files) %iterate through experiment folder
    fprintf('Processing file: %s\n', files(i).name);
    load(fullfile(filePath,  [files(i).name])) % This should load 'sesdat'
    
    % Check if 'sesdat' was loaded
    if ~exist('sesdat', 'var')
        fprintf('Warning: Skipping file %s. No "sesdat" variable found.\n', files(i).name);
        clear sesdat; % Clear in case it's a partial load
        continue;
    end
    
    % --- Check for Required Data Fields ---
    % MODIFIED: Check for 'conversion' instead of 'fs'
    if ~isfield(sesdat, 'lp_dFF') || ~isfield(sesdat, 'traces_z') || ~isfield(sesdat, 'conversion')
        fprintf('Warning: Skipping %s. Missing required fields (lp_dFF, traces_z, or conversion).\n', files(i).name);
        clear sesdat;
        continue;
    end
    
    % --- Extract Data ---
    dffTrace = sesdat.lp_dFF;
    eventData = sesdat.traces_z;
    % MODIFIED: Use 'conversion' as the sampling rate
    fs = sesdat.conversion; % Sampling rate
    ratName = sesdat.rat;
    
    % Get session name (if it exists, for a better title)
    if isfield(sesdat, 'ses')
        sessionName = sesdat.ses;
    else
        sessionName = files(i).name; % Use filename as fallback
    end
    
    % Check if data is empty
    if isempty(dffTrace) || isempty(eventData)
        fprintf('Warning: Skipping %s. Empty trace or event data.\n', files(i).name);
        clear sesdat;
        continue;
    end
    
    % MODIFIED: Get filtered event timestamps
    % Only get timestamps from column 1 WHERE column 2 == 1
    eventRows = eventData(:, 2) == 1;
    eventTimestamps = eventData(eventRows, 1);
    
    % Create time vector for dF/F trace
    numSamples = length(dffTrace);
    timeVector = (0:numSamples-1) / fs;
    
    % MODIFIED: Truncate first 60 seconds
    secondsToCut = 60;
    startSample = round(secondsToCut * fs) + 1; % +1 for 1-based indexing
    
    % Ensure trace is long enough to cut
    if startSample > length(dffTrace) || startSample > length(timeVector)
        fprintf('Warning: Skipping %s. Trace is shorter than 60 seconds.\n', files(i).name);
        clear sesdat;
        continue;
    end
    
    % Create truncated data and time vectors
    dffTrace_trunc = dffTrace(startSample:end);
    timeVector_trunc = timeVector(startSample:end);
    
    % --- Create Plot for this Session ---
    % Each session gets its own figure
    figure('Name', sprintf('Rat %s - %s', ratName, sessionName), 'Position', [100, 100, 1200, 600]);
    hold on;
    
    % MODIFIED: Plot truncated dF/F trace
    plot(timeVector_trunc, dffTrace_trunc, 'b-', 'LineWidth', 1); % Blue for trace
    
    % Plot event lines
    ax = gca;
    yLimits = ax.YLim;
    eventLineHandle = []; % For legend
    
    for k = 1:length(eventTimestamps)
        eventTime = eventTimestamps(k);
        % MODIFIED: Check if event is within the *truncated* time range
        if eventTime >= timeVector_trunc(1) && eventTime <= timeVector_trunc(end)
            h = line([eventTime, eventTime], yLimits, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 0.5);
            if isempty(eventLineHandle)
                eventLineHandle = h; % Store handle for first line for the legend
            end
        end
    end
    
    hold off;
    
    % Add labels and title
    title(sprintf('Full Session dF/F (from 60s): Rat %s - %s', ratName, sessionName), 'Interpreter', 'none');
    xlabel('Time (s)');
    ylabel('lp_dFF (Z-score or dF/F)');
    
    if ~isempty(eventLineHandle)
        legend(eventLineHandle, 'Event (traces\_z col 2 == 1)', 'Location', 'northwest');
    end
    grid on;
    
    clear sesdat; % Clear for the next loop iteration
end % End of file loop
fprintf('All files processed.\n');