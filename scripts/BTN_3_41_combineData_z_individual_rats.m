%% Nathan Marchant May 2025
% Written for Pavlovian conflict task
% Includes: Plots individual rat averages instead of grand average ---


% --- Initialization ---
clear all;
close all; % Good practice to close figures

% --- Define the folder containing your extracted .mat files ---
dataFolder = 'C:\Photometry\PavConf\Conflict_Extracted\Pavlovian conditioning conflict'; % <--- SET YOUR FOLDER PATH HERE
files = dir(fullfile(dataFolder, '*.mat')); % Get a list of all .mat files

% --- Extract all unique rat IDs from filenames ---
rat_ids_from_files = {};
for k = 1:length(files)
    % Use regexp to find the rat ID (e.g., R10) in '...data_R10.mat'
    token = regexp(files(k).name, 'data_(R\d+)\.mat$', 'tokens', 'once');
    if ~isempty(token)
        rat_ids_from_files{end+1} = token{1};
    end
end
unique_rats = unique(rat_ids_from_files);
fprintf('Found %d unique rats: %s\n', length(unique_rats), strjoin(unique_rats, ', '));

% --- Process data for each rat individually ---
ratData = struct();
time_vector = []; % To store the time vector from the first valid file

for i = 1:length(unique_rats)
    current_rat_id = unique_rats{i};
    fprintf('\nProcessing data for rat: %s\n', current_rat_id);
    
    % Initialize arrays for the current rat
    rat_CSP = [];
    rat_CSM = [];
    rat_CSPun = [];
    
    % Find all files for the current rat and collate their data
    for k = 1:length(files)
        if contains(files(k).name, ['data_' current_rat_id '.mat'])
            fprintf(' -> Loading file: %s\n', files(k).name);
            load(fullfile(dataFolder, files(k).name)); % loads sesdat
            
            if exist('sesdat', 'var') && isfield(sesdat, 'traces_z') && ~isempty(sesdat.traces_z)
                % Extract trials for this file based on the cue type in column 2
                csp_indices = sesdat.traces_z(:, 2) == 1;
                csm_indices = sesdat.traces_z(:, 2) == 2;
                cspun_indices = sesdat.traces_z(:, 2) == 3;
                
                % Append trace data (from column 3 onwards)
                rat_CSP = [rat_CSP; sesdat.traces_z(csp_indices, 3:end)];
                rat_CSM = [rat_CSM; sesdat.traces_z(csm_indices, 3:end)];
                rat_CSPun = [rat_CSPun; sesdat.traces_z(cspun_indices, 3:end)];
                
                % Store time vector from the first valid file we find
                if isempty(time_vector) && ~isempty(sesdat.traces_z)
                    % The trace data starts at column 3, so there are 2 fewer columns than the total
                    time_vector = linspace(-10, 40, size(sesdat.traces_z, 2) - 2);
                end
            end
            clear sesdat;
        end
    end
    
    % --- Data Cleaning for the current rat ---
    % 1. Handle NaNs
    rat_CSP(any(isnan(rat_CSP), 2), :) = [];
    rat_CSM(any(isnan(rat_CSM), 2), :) = [];
    rat_CSPun(any(isnan(rat_CSPun), 2), :) = [];
    
    % 2. Handle Outliers (remove trials where the mean is outside +/- 20)
    if ~isempty(rat_CSP), rat_CSP(abs(mean(rat_CSP, 2)) > 20, :) = []; end
    if ~isempty(rat_CSM), rat_CSM(abs(mean(rat_CSM, 2)) > 20, :) = []; end
    if ~isempty(rat_CSPun), rat_CSPun(abs(mean(rat_CSPun, 2)) > 20, :) = []; end
    
    % --- Calculate and store mean traces for the current rat ---
    if ~isempty(rat_CSP), ratData.(current_rat_id).CSP_mean = mean(rat_CSP, 1); end
    if ~isempty(rat_CSM), ratData.(current_rat_id).CSM_mean = mean(rat_CSM, 1); end
    if ~isempty(rat_CSPun), ratData.(current_rat_id).CSPun_mean = mean(rat_CSPun, 1); end
end

% --- Plotting section for individual rats ---
if isempty(time_vector)
    error('Could not determine time vector. No valid data files found or processed.');
end

% Get a unique color map for the rats
rat_colors = lines(length(unique_rats));

% --- Plot for CSP ---
figure('Name', 'CSP Traces per Rat', 'NumberTitle', 'off');
hold on;
legend_handles_csp = [];
legend_labels_csp = {};
for i = 1:length(unique_rats)
    rat_id = unique_rats{i};
    if isfield(ratData, rat_id) && isfield(ratData.(rat_id), 'CSP_mean')
        h = plot(time_vector, ratData.(rat_id).CSP_mean, 'Color', rat_colors(i,:), 'LineWidth', 1.5);
        legend_handles_csp = [legend_handles_csp, h];
        legend_labels_csp{end+1} = rat_id;
    end
end
title('CSP - Individual Rats');
xlabel('Time from Cue Onset (s)');
ylabel('Z-Score');
if ~isempty(legend_handles_csp)
    legend(legend_handles_csp, legend_labels_csp, 'Location', 'northwest');
end
line([0 0], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line([20 20], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line(xlim, [0 0], 'Color', 'k', 'LineStyle', '-');
hold off;
box on;

% --- Plot for CSM ---
figure('Name', 'CSM Traces per Rat', 'NumberTitle', 'off');
hold on;
legend_handles_csm = [];
legend_labels_csm = {};
for i = 1:length(unique_rats)
    rat_id = unique_rats{i};
    if isfield(ratData, rat_id) && isfield(ratData.(rat_id), 'CSM_mean')
        h = plot(time_vector, ratData.(rat_id).CSM_mean, 'Color', rat_colors(i,:), 'LineWidth', 1.5);
        legend_handles_csm = [legend_handles_csm, h];
        legend_labels_csm{end+1} = rat_id;
    end
end
title('CSM - Individual Rats');
xlabel('Time from Cue Onset (s)');
ylabel('Z-Score');
if ~isempty(legend_handles_csm)
    legend(legend_handles_csm, legend_labels_csm, 'Location', 'northwest');
end
line([0 0], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line([20 20], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line(xlim, [0 0], 'Color', 'k', 'LineStyle', '-');
hold off;
box on;

% --- Plot for CSPun ---
figure('Name', 'CSPun Traces per Rat', 'NumberTitle', 'off');
hold on;
legend_handles_cspun = [];
legend_labels_cspun = {};
for i = 1:length(unique_rats)
    rat_id = unique_rats{i};
    if isfield(ratData, rat_id) && isfield(ratData.(rat_id), 'CSPun_mean')
        h = plot(time_vector, ratData.(rat_id).CSPun_mean, 'Color', rat_colors(i,:), 'LineWidth', 1.5);
        legend_handles_cspun = [legend_handles_cspun, h];
        legend_labels_cspun{end+1} = rat_id;
    end
end
title('CSPun - Individual Rats');
xlabel('Time from Cue Onset (s)');
ylabel('Z-Score');
if ~isempty(legend_handles_cspun)
    legend(legend_handles_cspun, legend_labels_cspun, 'Location', 'northwest');
end
line([0 0], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line([20 20], ylim, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
line(xlim, [0 0], 'Color', 'k', 'LineStyle', '-');
hold off;
box on;

fprintf('\nPlotting complete.\n');
