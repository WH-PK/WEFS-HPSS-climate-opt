function selected_pop = replace(nest, num_obj, num_dec, pop_size)
% Select individuals based on rank and crowding distance until population size is reached
% Inputs:
%   nest - current population matrix including decision vars, objectives, rank, crowding distance
%   num_obj - number of objectives
%   num_dec - number of decision variables
%   pop_size - desired population size to select
% Output:
%   selected_pop - population selected after replacement

N = size(nest, 1);

% Sort population by rank (ascending)
[~, index] = sort(nest(:, num_obj + num_dec + 1));
sorted_pop = nest(index, :);

max_rank = max(nest(:, num_obj + num_dec + 1)); % highest rank value
prev_idx = 0;

for rank_i = 1 : max_rank
    % Find last individual index with current rank
    current_idx = find(sorted_pop(:, num_obj + num_dec + 1) == rank_i, 1, 'last');
    
    if current_idx > pop_size
        % If current index exceeds population size limit,
        % select remaining slots based on crowding distance within this rank
        remaining = pop_size - prev_idx;
        candidates = sorted_pop(prev_idx + 1 : current_idx, :);
        
        % Sort candidates by crowding distance descending
        [~, dist_idx] = sort(candidates(:, num_obj + num_dec + 2), 'descend');
        
        % Select individuals with highest crowding distance
        selected_pop = [sorted_pop(1:prev_idx, :); candidates(dist_idx(1:remaining), :)];
        return;
        
    elseif current_idx < pop_size
        % If current index is less than pop size, keep all individuals up to current index
        % and continue to next rank
        prev_idx = current_idx;
    else
        % If exactly equal to pop size, keep all and return
        selected_pop = sorted_pop(1:current_idx, :);
        return;
    end
end
