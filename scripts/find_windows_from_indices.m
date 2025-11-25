% --- LOCAL HELPER FUNCTION to find time windows ---
function windows = find_windows_from_indices(indices, time_vector)
    if isempty(indices)
        windows = [];
        return;
    end
    
    breaks = find([true, diff(indices) > 1, true]);
    windows = zeros(length(breaks) - 1, 2);
    for i = 1:length(breaks)-1
        start_idx = indices(breaks(i));
        end_idx = indices(breaks(i+1)-1);
        windows(i, :) = [time_vector(start_idx), time_vector(end_idx)];
    end
end