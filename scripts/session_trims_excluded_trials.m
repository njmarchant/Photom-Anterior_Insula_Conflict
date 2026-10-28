% Define paths
dataFolder = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data'; % Ensure it ends with a slash
csvFile = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data\Conflict_02_excluded_trials.csv';

% 1. Load the CSV file
% Assuming the CSV has headers: Sess, Rat, Detail, number1, number2
opts = detectImportOptions(csvFile);
% Force specific columns to be treated as strings for easier comparison
opts = setvartype(opts, {'Sess', 'Rat', 'Detail'}, 'string');
exclusionList = readtable(csvFile, opts);

% 2. Get list of all .mat files in the data folder
filePattern = fullfile(dataFolder, '*.mat');
files = dir(filePattern);

% 3. Loop through each file in the folder
for i = 1:length(files)
    filename = files(i).name;
    
    % Split filename by '-' and '_'
    names = strsplit(filename, {'-', '_'});
    
    % Extract Session and Rat ID
    % names{5} is Session (e.g., 'C13')
    % names{7} is Rat (e.g., 'R09.mat'). We must strip the '.mat' extension
    sessionID = names{5};
    ratID = strrep(names{7}, '.mat', ''); 
    
    % Find if this Session and Rat combination exists in the CSV
    matchIdx = find((exclusionList.Sess == sessionID) & (exclusionList.Rat == ratID));
    
    % If a match is found in the CSV, process the file
    if ~isempty(matchIdx)
        filePath = fullfile(dataFolder, filename);
        
        % Load the .mat file (loads into a struct 'data')
        data = load(filePath);
        
        % Check if 'sesdat' is actually in the file
        if isfield(data, 'sesdat')
            sesdat = data.sesdat;
            isModified = false;
            
            % Loop through all matched rows (in case a Rat/Session has multiple exclusions)
            for j = 1:length(matchIdx)
                row = exclusionList(matchIdx(j), :);
                detailAction = lower(row.Detail); % 'end' or 'trim'
                num1 = row.number1;
                num2 = row.number2;
                
                % Process first trace: traces_z_10_45
                if isfield(sesdat, 'traces_z_10_45')
                    timestamps1 = sesdat.traces_z_10_45(:, 1);
                    
                    if detailAction == "end"
                        excludeRows = timestamps1 >= num1;
                    elseif detailAction == "trim"
                        excludeRows = (timestamps1 >= num1) & (timestamps1 <= num2);
                    else
                        excludeRows = false(size(timestamps1));
                    end
                    
                    % Replace column 2 values with NaN
                    sesdat.traces_z_10_45(excludeRows, 5) = 0;
                    isModified = true;
                end
                
                % Process second trace: traces_z_25_15
                if isfield(sesdat, 'traces_z_25_15')
                    timestamps2 = sesdat.traces_z_25_15(:, 1);
                    
                    if detailAction == "end"
                        excludeRows = timestamps2 >= num1;
                    elseif detailAction == "trim"
                        excludeRows = (timestamps2 >= num1) & (timestamps2 <= num2);
                    else
                        excludeRows = false(size(timestamps2));
                    end
                    
                    % Replace column 2 values with NaN
                    sesdat.traces_z_25_15(excludeRows, 5) = 0;
                    isModified = true;
                end
            end
            
            % If data was changed, save the updated struct back to the file
            if isModified
                % Use -append to update 'sesdat' without overwriting other variables 
                % that might be living in the .mat file
                save(filePath, 'sesdat', '-append');
                fprintf('Successfully processed and updated: %s\n', filename);
            end
        end
    end
end

fprintf('Data exclusion processing complete.\n');