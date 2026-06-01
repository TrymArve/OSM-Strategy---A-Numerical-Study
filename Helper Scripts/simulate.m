
% Reset solver:
if reset_CL_guess
   % Initial guess (primal):
   C.decision.num = C.guess(ref.state,ref.input);

   % Initial guess (dual):
   C.lambda.vec.num(:) = 0;
   C.mu.vec.num(:) = 0;
end


time_traj = 0;
state_traj = initial_state.(Case).values;
input_traj = [];
iteration_traj = [];
solve_time_traj = [];
success_traj = [];

condition.(method) = {};

state = state_traj;




fprintf('Simulating ... '); time_simulation = tic;

while time_traj(end) < sim.T

   %%%%% Find contorl signal
   C.dop_parameters.num.measured_state = state_traj(:,end);

   % solver dependent
   time_solve = tic;
   switch method
      case {"classic","aggressive","aggressive_2","linear_term"}
         solve_SQP
         % condition.(method)(end+1) = {condition_number_W}; % only if checking the condition number...
      case "osm"
         solve_FB
      otherwise
         error('USER ERROR: Incorrect method, no control law can be computed')
   end
   solve_time_traj(end+1) = toc(time_solve);
   iteration_traj(end+1) = n_iterations;
   success_traj(end+1) = success_falg;

   u = C.decision.num.input(:,1);
   
   % Simulate
   state = full(sim.disc.F(state,u,model.parameters.values,[],C.dop_parameters.num.Dt));
   new_time = time_traj(end) + C.dop_parameters.num.Dt;

   % Store
   input_traj(:,end+1) = u; %#ok<*SAGROW>
   state_traj(:,end+1) = state;
   time_traj(end+1) = new_time;
   

   % Shifting Procedure:
   C.decision.num.state = C.decision.num.state(:,[2:end end]);
   C.decision.num.input = C.decision.num.input(:,[2:end end]);
   C.decision.num.aux   = C.decision.num.aux(  :,[2:end end]);
   C.lambda.num.gap     = C.lambda.num.gap(    :,[2:end end]);
   if size(C.lambda.num.col,2) > 0
   C.lambda.num.col     = C.lambda.num.col(    :,[2:end end]);
   end
   C.mu.num.bounds      = C.mu.num.bounds(     :,[2:end end]);
end

disp("done. " + sec2str(toc(time_simulation)))