function sorted_population = non_domination_sort(population, num_obj, num_dec)
% Perform non-dominated sorting and calculate crowding distance
% Inputs:
%   population - matrix where each row is an individual with decision variables and objectives
%   num_obj - number of objectives (M)
%   num_dec - number of decision variables (V)
% Outputs:
%   sorted_population - population sorted by front and crowding distance

N = size(population, 1); % population size
front = 1;
F(front).members = [];

% Initialize domination info for each individual
individual(N).n = 0; % domination count
individual(N).p = []; % dominated individuals

for i = 1 : N
    individual(i).n = 0;
    individual(i).p = [];
    for j = 1 : N
        dom_less = 0;
        dom_equal = 0;
        dom_more = 0;
        % Compare objectives between individual i and j
        for k = 1 : num_obj
            obj_i = population(i, num_dec + k);
            obj_j = population(j, num_dec + k);
            if obj_i < obj_j
                dom_less = dom_less + 1;
            elseif obj_i == obj_j
                dom_equal = dom_equal + 1;
            else
                dom_more = dom_more + 1;
            end
        end
        % Check domination relationship
        if dom_less == 0 && dom_equal ~= num_obj
            individual(i).n = individual(i).n + 1; % i is dominated by j
        elseif dom_more == 0 && dom_equal ~= num_obj
            individual(i).p = [individual(i).p j]; % i dominates j
        end
    end
    % Individuals with no dominators belong to first front
    if individual(i).n == 0
        population(i, num_obj + num_dec + 1) = 1; % assign front number
        F(front).members = [F(front).members i];
    end
end

% Identify subsequent fronts
while ~isempty(F(front).members)
    Q = [];
    for i = 1 : length(F(front).members)
        current = F(front).members(i);
        for j = individual(current).p
            individual(j).n = individual(j).n - 1;
            if individual(j).n == 0
                population(j, num_obj + num_dec + 1) = front + 1;
                Q = [Q j];
            end
        end
    end
    front = front + 1;
    F(front).members = Q;
end

% Sort population by front rank
[~, sorted_idx] = sort(population(:, num_obj + num_dec + 1));
sorted_pop = population(sorted_idx, :);

% Calculate crowding distance for each front
current_index = 0;
z = zeros(size(sorted_pop));
for f = 1 : (front - 1)
    front_members = F(f).members;
    if isempty(front_members)
        continue;
    end
    front_size = length(front_members);
    y = sorted_pop(current_index + 1 : current_index + front_size, :);
    current_index = current_index + front_size;
    
    % Initialize crowding distance
    distance = zeros(front_size, 1);
    
    % Calculate crowding distance for each objective
    for obj = 1 : num_obj
        [sorted_obj_vals, obj_idx] = sort(y(:, num_dec + obj));
        f_max = sorted_obj_vals(end);
        f_min = sorted_obj_vals(1);
        y(obj_idx(1), num_obj + num_dec + 1 + obj) = Inf;
        y(obj_idx(end), num_obj + num_dec + 1 + obj) = Inf;
        for j = 2 : front_size - 1
            if f_max == f_min
                y(obj_idx(j), num_obj + num_dec + 1 + obj) = Inf;
            else
                y(obj_idx(j), num_obj + num_dec + 1 + obj) = ...
                    (sorted_obj_vals(j + 1) - sorted_obj_vals(j - 1)) / (f_max - f_min);
            end
        end
        distance = distance + y(:, num_obj + num_dec + 1 + obj);
    end
    
    y(:, num_obj + num_dec + 2) = distance; % store crowding distance
    z(current_index - front_size + 1 : current_index, :) = y(:, 1 : num_obj + num_dec + 2);
end

sorted_populatio_
