function new_nest = get_cuckoos(old_nest, best, Lb, Ub, NumObj, NumDec, simu_para)
% Generate new solutions (cuckoos) using Lévy flights

new_nest = old_nest;
nest = old_nest(:, 1:NumDec);
n = size(nest, 1);

beta = 3/2;
sigma = (gamma(1+beta) * sin(pi*beta/2) / (gamma((1+beta)/2) * beta * 2^((beta-1)/2)))^(1/beta);

for j = 1:n
    s = nest(j,:);
    u = randn(size(s)) * sigma;
    v = randn(size(s));
    step = u ./ abs(v).^(1/beta);
    stepsize = 0.01 * step .* (s - best);
    s = s + stepsize .* randn(size(s));

    % Repair to ensure feasibility
    nest(j,:) = repair_operator(s, Lb, Ub);

    % Evaluate objective functions
    f = fobj(nest(j,:), simu_para);

    % Update new population
    new_nest(j, 1:NumDec) = nest(j,:);
    new_nest(j, NumDec+1 : NumDec+NumObj) = f;
end
end