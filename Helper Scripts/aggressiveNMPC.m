


%%% Classic NMPC

method = "aggressive";

%%% -------------------- Define Main Objective:

weights = base_weights; % copy nominal weights

% Modfy weight before making quadratic objective:
quad_term = 11;
weights.input("q")  = weights.input("q")*quad_term; % Much more aggressive tuning to dampen use of q

% Use standard quadratic objective:
make_quadratic_objective % this created the quadratic baseline

% Modify objective further:
linear_weight = 0;
% don't...

% Solidify objective:
create_objective_functions % This solidifies the objective as is, creating the needed CasADi graphs for solution algorithms





%%% ------------------- PREPARE DERIVATIVES OF DOP

make_derivatives



%%% ------------------- SOLVE and SAVE:

solve_and_save

