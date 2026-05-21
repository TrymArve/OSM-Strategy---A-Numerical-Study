


%%% Classic NMPC

method = "classic";

%%% -------------------- Define Main Objective:

weights = base_weights; % copy nominal weights

% Use standard quadratic objective:
quad_term = 1;
make_quadratic_objective % this created the quadratic baseline

% Modify objective:
linear_weight = 0;
% Do not modify objective further... (here we could add other stuff, like liear terms)

% Solidify objective:
create_objective_functions % This solidifies the objective as is, creating the needed CasADi graphs for solution algorithms





%%% ------------------- PREPARE DERIVATIVES OF DOP

make_derivatives




%%% ------------------- SOLVE and SAVE:

solve_and_save

