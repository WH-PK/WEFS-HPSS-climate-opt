function new_nest = empty_nests(old_nest, Lb, Ub, m, nd, pa, simu_para)
% Generate new solutions by random walk with probability pa

new_nest = old_nest;
nest = old_nest(:, 1:nd);
n = size(nest, 1);

% Generate random mask for abandoned nests
K = rand(size(nest)) > pa;

% Random steps between two random solutions
stepsize = rand * (nest(randperm(n), :) - nest(randperm(n), :));

% Update solutions with random walk
new_nest(:, 1:nd) = nest + stepsize .* K;

for ii = 1:n
    s = new_nest(ii, 1:nd);
    % Repair to keep solutions within bounds
    new_nest(ii, 1:nd) = repair_operator(s, Lb, Ub);
    % Evaluate objective functions
    f = fobj(new_nest(ii, 1:nd), simu_para);
    new_nest(ii, nd+1 : nd+m) = f;
end
end
