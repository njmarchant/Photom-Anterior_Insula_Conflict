%% --- Statistical Analysis V5: No Toolbox Workaround (CORRECTED) ---
%  Fixed: Uses strcmp() for RatID comparisons to avoid "cell" errors.

fprintf('\n=================================================\n');
fprintf('STARTING ANALYSIS (NO TOOLBOX MODE)\n');
fprintf('Method: Paired T-Tests (Two-tailed) on Subject Means\n');
fprintf('=================================================\n');

% Define Lists
cues_list = {'Rew', 'Pun', 'Conf'};
outcomes_list = {'Resp', 'Omit'};
comparisons = {[1 2], [1 3], [2 3]}; % S1vsS2, S1vsS3, S2vsS3

for c = 1:length(cues_list)
    curr_cue = cues_list{c};
    
    for o = 1:length(outcomes_list)
        curr_out = outcomes_list{o};
        
        fprintf('\n----------------------------------------\n');
        fprintf('ANALYZING: %s - %s\n', curr_cue, curr_out);
        
        % 1. Filter Data for this Condition
        % Note: Cue and Outcome are categorical (from previous script), so == works.
        mask = (T_Stats.Cue == curr_cue) & (T_Stats.Outcome == curr_out);
        sub_data = T_Stats(mask, :);
        
        % 2. Loop through Pairwise Comparisons
        for comp = 1:length(comparisons)
            s_idx_A = comparisons{comp}(1);
            s_idx_B = comparisons{comp}(2);
            
            state_A = sprintf('S%d', s_idx_A);
            state_B = sprintf('S%d', s_idx_B);
            
            % Get unique rats in this subset
            % (Convert to string array temporarily ensures 'unique' behaves simply)
            if iscell(sub_data.RatID)
                rats = unique(string(sub_data.RatID));
            else
                rats = unique(sub_data.RatID);
            end
            
            vals_A = [];
            vals_B = [];
            
            for r = 1:length(rats)
                curr_rat = rats(r); % This is now a string
                
                % --- THE FIX IS HERE ---
                % We convert the table column to string for the comparison to be safe
                % or use strcmp if keeping as cell. 
                % Here I use string() which is robust for both cell and string arrays.
                
                row_A = sub_data(string(sub_data.RatID) == curr_rat & sub_data.State == state_A, :);
                row_B = sub_data(string(sub_data.RatID) == curr_rat & sub_data.State == state_B, :);
                
                % Only proceed if BOTH exist and are not NaN
                if ~isempty(row_A) && ~isempty(row_B)
                    val_a = row_A.Mean_aIC;
                    val_b = row_B.Mean_aIC;
                    
                    if ~isnan(val_a) && ~isnan(val_b)
                        vals_A = [vals_A; val_a]; %#ok<AGROW>
                        vals_B = [vals_B; val_b]; %#ok<AGROW>
                    end
                end
            end
            
            % 3. Run Manual Paired T-Test
            n_samples = length(vals_A);
            
            if n_samples < 3
                fprintf('   %s vs %s: Not enough samples (N=%d)\n', state_A, state_B, n_samples);
                continue;
            end
            
            % Difference
            d = vals_A - vals_B;
            mean_d = mean(d);
            std_d = std(d);
            se_d = std_d / sqrt(n_samples);
            
            % T-Statistic
            t_stat = mean_d / se_d;
            
            % P-Value (Manual lookup via betainc)
            df = n_samples - 1;
            p_val = 2 * (1 - tcdf_manual(abs(t_stat), df)); 
            
            % Check Significance
            sig_star = '';
            if p_val < 0.001, sig_star = '***';
            elseif p_val < 0.01, sig_star = '**';
            elseif p_val < 0.05, sig_star = '*';
            end
            
            fprintf('   %s vs %s (N=%d): Diff=%.3f, p=%.4f %s\n', ...
                state_A, state_B, n_samples, mean_d, p_val, sig_star);
        end
    end
end

% --- HELPER FUNCTION FOR P-VALUES ---
function p = tcdf_manual(t, df)
    x = df ./ (df + t.^2);
    p = 1 - 0.5 * betainc(x, df/2, 0.5);
end