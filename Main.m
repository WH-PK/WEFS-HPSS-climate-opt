%% Improved Multi-Objective Cuckoo Search Algorithm for WEFS Operation Optimization
% Author: Updated version

function main_optimization(simu_para, Lb, Ub, IRRCOE, IRRTZ, IRRLZ, IRRCZ, IRRVZ)

rng(Set random seeds); % Set random seed for reproducibility

clearvars -except simu_para Lb Ub IRRCOE IRRTZ IRRLZ IRRCZ IRRVZ
clc; close all

%% Input inflow and coefficient data passed via 'simu_para' structure
% simu_para{1} = lgZV1; simu_para{2} = lgZQ1;
% simu_para{3} = lgZV2; simu_para{4} = lgZQ2;
% simu_para{5} = inflow1; simu_para{6} = inflow2;
% simu_para{7-10} = QJR, QJ1, QJ2, QJ3;
% simu_para{11-14} = V_upper1, V_lower1, V_upper2, V_lower2;
% simu_para{15} = IRRCOE;
% simu_para{16-17} = lgHN1, lgHN2;

%% Basic algorithm parameters
NumPop = Algorithm parameters1;            % Population size
NumDec = Algorithm parameters2;       % Number of decision variables
NumObj = Algorithm parameters3;             % Number of objective functions

%% Compute irrigation demands (converted to m³/s)
DT = 60 * 60 * 24 * 30.4;    % Time in seconds for a month
DW = 1e8;                    % Conversion factor
QRM1 = ((IRRTZ * DW) * (IRRCOE(1,:) / 100)) / DT;
QRM2 = ((IRRLZ * DW) * (IRRCOE(2,:) / 100)) / DT;
QRM3 = ((IRRCZ * DW) * (IRRCOE(3,:) / 100)) / DT;
QRM4 = ((IRRVZ * DW) * (IRRCOE(4,:) / 100)) / DT;

%% Update upper bounds with demand constraints
Ub(end-47:end) = [QRM1, QRM2, QRM3, QRM4];

%% Initialize population
nest = zeros(NumPop, NumDec + NumObj);
for jj = 1:NumPop
    nest(jj,1:NumDec) = Lb + (Ub - Lb) .* rand(size(Lb));
    nest(jj,1:NumDec) = repair_operator(nest(jj,1:NumDec), Lb, Ub); % Boundary repair
    nest(jj,NumDec+1:NumDec+NumObj) = fobj(nest(jj,1:NumDec), simu_para); % Objective eval
end
nest = non_domination_sort(nest, NumObj, NumDec);

%% Optimization loop
max_gen = Number of iterations;
for count = 1:max_gen
    new_nest1 = get_cuckoos(nest, nest(1,1:NumDec), Lb, Ub, NumObj, NumDec, simu_para);
    pa = 0.5 - count * (0.5 - 0.05) / max_gen;
    new_nest2 = empty_nests(nest, Lb, Ub, NumObj, NumDec, pa, simu_para);
    Tempnest = [nest; new_nest1; new_nest2];
    Tempnest = non_domination_sort(Tempnest, NumObj, NumDec);
    nest = replace(Tempnest, NumObj, NumDec, NumPop);
    disp([num2str(count), ' - iteration completed']);
end

%% Remove duplicates, extract Pareto solutions
nest = unique(nest, 'rows');
nest_Pareto = nest(:, 1:NumDec);
f_Pareto = nest(:, NumDec+1:NumDec+NumObj);
plot(-f_Pareto(:,1), -f_Pareto(:,2), 'bo');

%% Extract and compile results
[mm, ~] = size(nest_Pareto);
results = zeros(mm, 74);
results1 = zeros(mm, 10);
for kk = 1:mm
    x = nest_Pareto(kk,:);
    results1(kk,:) = extract_results(x, simu_para);
    results(kk,:) = [x, abs(f_Pareto(kk,:))];
    disp(['Result ', num2str(kk)]);
end

toc

end