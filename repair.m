function new_nest = repair_operator(nest, Lb, Ub)
% Repair operator based on feasible space search

a = 1:Parameters;
n = length(a);

% Boundary check and correction
nest = simplebounds(nest, Lb, Ub);

% Extract variable groups
z1 = nest(1:Parameters1);
z2 = nest(Parameters2:Parameters3);
z3 = nest(Parameters4:Parameters5);
z4 = nest(Parameters6:Parameters7);
z5 = nest(Parameters8:Parameters9);
z6 = nest(Parameters10:Parameters11);

% Combine all variables into the repaired solution
new_nest = [z1, z2, z3, z4, z5, z6];
end