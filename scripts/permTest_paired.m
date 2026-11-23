function [p_val, observeddifference, n_perm, is_exact] = permTest_paired(sample1, sample2, permutations)
% [p_val, observeddifference, n_perm, is_exact] = permTest_paired(sample1, sample2, permutations)
%
% Paired (within-subject) permutation test at every time point, by sign
% flipping. Row i of sample1 and row i of sample2 must come from the SAME
% subject (e.g. one rat's mean trace in two conditions).
%
% Under the null hypothesis there is no difference between conditions, so
% the sign of each subject's difference (sample1 - sample2) is arbitrary.
% The null distribution of the mean difference is built by randomly
% flipping the sign of each subject's whole difference trace (the same flip
% at every time point, which keeps the temporal structure of each subject's
% trace intact).
%
% In:
%   sample1, sample2 - [n subjects x n timepoints], rows matched by subject
%   permutations     - number of random sign flips (e.g. 1000). If
%                      2^n <= permutations, all 2^n sign patterns are used
%                      instead (exact test).
% Out:
%   p_val              - two-sided p value per time point (1 x n timepoints)
%   observeddifference - mean(sample1 - sample2) per time point
%   n_perm             - number of sign patterns used
%   is_exact           - true if all 2^n patterns were enumerated
%
% p values: exact test  -> proportion of all 2^n patterns (including the
%                          observed one) with |mean diff| >= observed;
%                          the smallest possible p is 2/2^n.
%           random flips -> (count(|null| >= |observed|) + 1) / (permutations + 1).
%
% Nathan Marchant / Claude, Oct 2026

if ~isequal(size(sample1), size(sample2))
    error('permTest_paired: samples must have the same size (rows = the same subjects in the same order).');
end

D = sample1 - sample2;                 % subject x time differences
n = size(D, 1);
if n < 2
    error('permTest_paired: need at least 2 subjects with data in both conditions (n = %d).', n);
end

observeddifference = mean(D, 1, 'omitnan');

if 2^n <= permutations
    % exact: every combination of signs
    is_exact = true;
    n_perm = 2^n;
    bits = dec2bin(0:n_perm-1, n) - '0';          % n_perm x n, 0/1
    signs = 1 - 2*bits;                           % +1 / -1
else
    is_exact = false;
    n_perm = permutations;
    signs = 1 - 2*(rand(n_perm, n) > 0.5);
end

% null distribution of the mean difference: n_perm x time
null_diff = (signs * fillmissing_zero(D)) ./ sum(~isnan(D), 1);

exceed = sum(abs(null_diff) >= abs(observeddifference) - 1e-12, 1);
if is_exact
    p_val = exceed / n_perm;                      % identity pattern is included
else
    p_val = (exceed + 1) / (n_perm + 1);
end
end

function X = fillmissing_zero(X)
% NaN differences contribute nothing to the sum (the mean uses the number
% of non-NaN subjects at that time point).
X(isnan(X)) = 0;
end
