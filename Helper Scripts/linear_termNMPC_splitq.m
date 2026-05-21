


%%% Classic NMPC

method = "linear_term";

%%% -------------------- Define Main Objective:

weights = base_weights; % copy nominal weights

% Modfy weight before making quadratic objective:
quad_term = 1;
weights.input("q_plus")   = weights.input("q_plus") *quad_term; % q-split
weights.input("q_minus")  = weights.input("q_minus")*quad_term; % q-split

% Use standard quadratic objective:
make_quadratic_objective % this created the quadratic baseline

% Modify objective further:
linear_weight = 10;

for k = 1:N_horizon
   u_k = C.longshot.input.vars(:, k);
   Du = u_k - ref.input;

   obj = obj + Du(model.ind.input.q_plus) *linear_weight;
   obj = obj + Du(model.ind.input.q_minus)*linear_weight;
end

% Solidify objective:
create_objective_functions % This solidifies the objective as is, creating the needed CasADi graphs for solution algorithms





%%% ------------------- PREPARE DERIVATIVES OF DOP

make_derivatives


%%% ------------------- SOLVE and SAVE:

solve_and_save

