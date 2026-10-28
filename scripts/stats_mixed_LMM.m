%% --- Statistical Analysis V4: Linear Mixed Models (Handling NaNs) ---
%  Requires: 'T_Stats' (from the V3 script)

fprintf('\n=================================================\n');
fprintf('STARTING STATISTICAL ANALYSIS (Linear Mixed Models)\n');
fprintf('=================================================\n');

% Define Lists
cues_list = {'Rew', 'Pun', 'Conf'};
outcomes_list = {'Resp', 'Omit'};

% Store significant results
sig_results = {};

for c = 1:length(cues_list)
    curr_cue = cues_list{c};
    
    for o = 1:length(outcomes_list)
        curr_out = outcomes_list{o};
        
        fprintf('\n----------------------------------------\n');
        fprintf('ANALYZING: %s - %s\n', curr_cue, curr_out);
        
        % 1. Filter Data
        % We look for rows matching this Cue and Outcome
        mask = (T_Stats.Cue == curr_cue) & (T_Stats.Outcome == curr_out);
        sub_data = T_Stats(mask, :);
        
        % 2. Clean NaNs
        % LMM handles NaNs by ignoring them, but we remove them here to 
        % count the actual N (number of rats) remaining.
        sub_data = rmmissing(sub_data, 'DataVariables', 'Mean_aIC');
        
        % 3. Check Sufficiency
        % If we have fewer than 2 states represented, we can't compare states.
        unique_states = unique(sub_data.State);
        n_rats = length(unique(sub_data.RatID));
        
        if length(unique_states) < 2
            fprintf('⚠️ SKIPPING: Not enough states to compare (Found: %d states).\n', length(unique_states));
            continue;
        end
        
        fprintf('Data Points: %d | Rats Included: %d\n', height(sub_data), n_rats);
        
        % 4. Run Linear Mixed Model (fitlme)
        % Formula: Activity ~ State + (Random Intercept for RatID)
        try
            lme = fitlme(sub_data, 'Mean_aIC ~ State + (1|RatID)');
            
            % 5. Run ANOVA on the Model
            % This tells us: "Is there a Main Effect of State?"
            anova_res = anova(lme);
            p_val = anova_res.pValue(2); % Index 2 is usually the 'State' term
            f_val = anova_res.FStat(2);
            df = anova_res.DF2(2);
            
            fprintf('MAIN EFFECT OF STATE: F(%d, %.1f) = %.2f, p = %.4f\n', ...
                anova_res.DF1(2), df, f_val, p_val);
            
            % 6. Post-Hoc Comparisons (if Significant or Trending)
            if p_val < 0.05
                fprintf('>>> SIGNIFICANT! Running pairwise comparisons...\n');
                
                % Compare coefficients (State 1 is usually reference)
                disp(dataset2table(lme.Coefficients));
                
                % Store for summary
                sig_results{end+1} = sprintf('%s-%s: p=%.4f', curr_cue, curr_out, p_val);
            end
            
        catch ME
            fprintf('❌ MODEL FAILED: %s\n', ME.message);
        end
    end
end

fprintf('\n=================================================\n');
fprintf('SUMMARY OF SIGNIFICANT FINDINGS (p < 0.05)\n');
if isempty(sig_results)
    fprintf('None.\n');
else
    disp(sig_results');
end
fprintf('=================================================\n');