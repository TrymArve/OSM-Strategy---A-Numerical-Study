


%%% Classic NMPC

method = "linear_term";

%%% -------------------- Define Main Objective:

weights = base_weights; % copy nominal weights

% Modfy weight before making quadratic objective:
weights.input("q")  = weights.input("q")*1; % for non-split

% Use standard quadratic objective:
make_quadratic_objective % this creates the quadratic baseline

% Modify objective further:
linear_weight = 0.01;

for k = 1:N_horizon
   u_k = C.longshot.input.vars(:, k);
   Du = u_k - ref.input;

   obj = obj + abs(Du(model.ind.input.q))*linear_weight;
end

% Solidify objective:
create_objective_functions % This solidifies the objective as is, creating the needed CasADi graphs for solution algorithms





%%% ------------------- PREPARE DERIVATIVES OF DOP

make_derivatives


shw.color = color.(method);

%%% ------------------- SOLVE
switch loop
   case "open"

      % Initial guess (primal):
      C.decision.num = C.guess(ref.state,ref.input);

      % Initial guess (dual):
      C.lambda.vec.num(:) = 0;
      C.mu.vec.num(:) = 0;


      % Set initial state:
      C.dop_parameters.num.measured_state = initial_state.values;

      % Solve:
      toggle_display_on = true;
      solve_SQP

      shw.title = method + " (Open Loop)";
      shw.style = '--';
      shw.traj.times = 0:Dt:T_horizon;
      shw.traj.state = full(C.longshot.state.F(C.decision.vec.num,C.dop_parameters.vec.num));
      shw.traj.input = C.decision.num.input;

      if ~success_falg
         shw.color = [1 0 0];
      end
      
      show.open(method) = shw;

   case "closed"
      simulate

      shw.title = method+" (Closed Loop)";
      shw.style = '-';
      shw.traj.times = time_traj;
      shw.traj.state = state_traj;
      shw.traj.input = input_traj;
      shw.traj.iterations = iteration_traj;
      shw.traj.solve_times = solve_time_traj;

      show.closed(method) = shw;
end


