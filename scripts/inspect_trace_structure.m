%% inspect_trace_structure.m
% =========================================================================
% Run this FIRST. It prints the actual layout of one session's traces and
% the matching CSV rows, so we stop guessing at column meanings.
%
% Paste the output back and the loader can be fixed exactly rather than
% heuristically.
% =========================================================================

clear; clc;

path_data  = 'C:\Photometry\Conflict_02 Photom\Conflict_02bc\Extracted_Data';
path_excel = ['C:\Photometry\Conflict_02 Photom\Conflict_02bc\' ...
              'collated_2026_conflict_data_with_Probabilities_065_Past_PelletShock_v5.csv'];

T = readtable(path_excel);
files = dir(fullfile(path_data, '*.mat'));

fprintf('\n=== CSV ===\n');
fprintf('Rows: %d\n', height(T));
fprintf('Columns: %s\n', strjoin(T.Properties.VariableNames, ', '));
fprintf('\nFirst 5 rows of the key columns:\n');
keep = intersect({'Rat','Session','Trial','Cue','Outcome','Latency', ...
                  'Inferred_State'}, T.Properties.VariableNames, 'stable');
disp(head(T(:,keep), 5));

fprintf('Inferred_State class: %s\n', class(T.Inferred_State));
if isnumeric(T.Inferred_State)
    fprintf('Inferred_State values: ');
    fprintf('%g ', unique(T.Inferred_State(~isnan(T.Inferred_State)))'); fprintf('\n');
    fprintf('NaN (no confident state): %d of %d (%.1f%%)\n', ...
        sum(isnan(T.Inferred_State)), height(T), ...
        100*sum(isnan(T.Inferred_State))/height(T));
end

fprintf('\n=== .mat FILES ===\n');
fprintf('Found %d files in %s\n', numel(files), path_data);

% --- walk files until we find one that matches the CSV --------------------
shown = 0;
for i = 1:numel(files)
    S = load(fullfile(path_data, files(i).name));
    if ~isfield(S,'sesdat'), continue; end
    sesdat = S.sesdat;

    if shown == 0
        fprintf('\nsesdat fields: %s\n', strjoin(fieldnames(sesdat)', ', '));
    end

    if ~isfield(sesdat,'traces_z_10_45'), continue; end
    tr = sesdat.traces_z_10_45;

    mask = strcmp(string(T.Rat), string(sesdat.rat)) & ...
           strcmp(string(T.Session), string(sesdat.ses));
    if ~any(mask), continue; end

    sdat = T(mask,:);
    shown = shown + 1;

    fprintf('\n--- Example matched session: %s | file %s ---\n', ...
        files(i).name, string(sesdat.ses));
    fprintf('Rat = %s   Session = %s\n', string(sesdat.rat), string(sesdat.ses));
    fprintf('traces size: %d rows x %d cols  (cols 5:end = %d samples)\n', ...
        size(tr,1), size(tr,2), size(tr,2)-4);
    fprintf('CSV rows for this session: %d\n', height(sdat));

    fprintf('\nFirst 8 rows, columns 1:6:\n');
    disp(tr(1:min(8,size(tr,1)), 1:min(6,size(tr,2))));

    fprintf('Per-column summary (cols 1:4):\n');
    for c = 1:min(4,size(tr,2))
        v = tr(:,c);
        isInt = all(abs(v - round(v)) < 1e-6 & isfinite(v));
        fprintf(['  col %d: min=%10.3f  max=%10.3f  n_unique=%4d  ' ...
                 'integer=%d  values(1:6)= %s\n'], c, min(v), max(v), ...
            numel(unique(v)), isInt, mat2str(round(v(1:min(6,numel(v)))',3)));
    end

    fprintf('\nCSV Trial values (first 10): %s\n', ...
        mat2str(sdat.Trial(1:min(10,height(sdat)))'));
    fprintf('CSV Trial range: %d to %d\n', min(sdat.Trial), max(sdat.Trial));

    % Which trace column, if any, corresponds to the CSV trial number?
    fprintf('\nOverlap of each trace column with CSV Trial values:\n');
    for c = 1:min(4,size(tr,2))
        v = round(tr(:,c));
        fprintf('  col %d: %d of %d rows found in sdat.Trial\n', ...
            c, sum(ismember(v, sdat.Trial)), size(tr,1));
    end
    rowIdxHit = sum(ismember((1:size(tr,1))', sdat.Trial));
    fprintf('  row position: %d of %d found in sdat.Trial\n', ...
        rowIdxHit, size(tr,1));

    % How many rows would the cue filter remove in this session?
    nDrop = sum(~ismember(tr(:,2), [1 2 3]));
    fprintf('\nCue filter (col 2 in [1 2 3]) would drop %d of %d rows here.\n', ...
        nDrop, size(tr,1));
    fprintf('Unique values in col 2: %s\n', mat2str(unique(tr(:,2))'));
    fprintf('Unique values in col 4: %s\n', mat2str(unique(tr(:,4))'));

    if shown >= 2, break; end
end

if shown == 0
    fprintf(2, ['\nNo .mat file matched the CSV on Rat AND Session.\n' ...
        'That is the root problem. Compare these:\n']);
    for i = 1:min(5,numel(files))
        S = load(fullfile(path_data, files(i).name));
        if isfield(S,'sesdat')
            fprintf('  MAT  rat=%-12s ses=%-12s\n', ...
                string(S.sesdat.rat), string(S.sesdat.ses));
        end
    end
    u = unique(T(:,{'Rat','Session'}));
    fprintf('  ---\n');
    for i = 1:min(5,height(u))
        fprintf('  CSV  rat=%-12s ses=%-12s\n', ...
            string(u.Rat(i)), string(u.Session(i)));
    end
end

fprintf('\nDone.\n');