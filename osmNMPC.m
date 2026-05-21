


%%% Classic NMPC

method = "osm";

%%% -------------------- Define Main Objective:

weights = base_weights; % copy nominal weights

% Use standard quadratic objective:
quad_term = 1;
make_quadratic_objective % this created the quadratic baseline

% Modify objective:
linear_term = 0;
% Do not modify objective further... (here we could add other stuff, like linear terms)

% Solidify objective:
create_objective_functions % This solidifies the objective as is, creating the needed CasADi graphs for solution algorithms


% Make the sensitivity matrices
make_sensitivity
modify_sensitivity


%%% ------------------- PREPARE DERIVATIVES OF DOP

make_halting_vector




%%% ------------------- SOLVE and SAVE:

solve_and_save

