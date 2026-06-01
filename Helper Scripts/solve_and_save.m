



%%% ------------------- SOLVE
switch loop
   case "open"

      % Initial guess (primal):
      C.decision.num = C.guess(ref.state,ref.input);

      % Initial guess (dual):
      C.lambda.vec.num(:) = 0;
      C.mu.vec.num(:) = 0;

      % Set initial state:
      C.dop_parameters.num.measured_state = initial_state.(Case).values;

      % Solve:
      toggle_display_on = true;

      if method == "osm"
         solve_FB
      else
         solve_SQP
      end
      
      

   case "closed"
      toggle_display_on = true;
      simulate
      
end


%%% ------------------- SAVE

      show.(loop)(method).title = method+" ("+loop+" Loop)";
      show.(loop)(method).case = Case;


switch loop
   case "open"

      show.open(method).traj.times = 0:Dt:T_horizon;
      show.open(method).traj.state = full(C.longshot.state.F(C.decision.vec.num,C.dop_parameters.vec.num));
      show.open(method).traj.input = C.decision.num.input;

      if ~success_falg
         show.open(method) = [1 0 0];
      end

   case "closed"

      show.closed(method).traj.times = time_traj;
      show.closed(method).traj.state = state_traj;
      show.closed(method).traj.input = input_traj;
      show.closed(method).traj.iterations = iteration_traj;
      show.closed(method).traj.solve_times = solve_time_traj;
      show.closed(method).traj.success = success_traj;


      %%% Print:
      disp("Stats for "+method+":")
      fprintf("  %-14s -> %8.4f iterations\n", method, mean(show.(loop)(method).traj.iterations(2:end)))
      fprintf("  %-14s -> %8.4f ms\n", method, mean(show.(loop)(method).traj.solve_times(2:end))*1000)

end


%%% Save result to file:
if save_result

   shw = show.(loop)(method);

   if method == "linear_term"
      shw.traj.input = [model.parameters("q_ref") + show.(loop)(method).traj.input(1,:) - show.(loop)(method).traj.input(2,:);
         show.(loop)(method).traj.input(3,:)   ];
   end

   shw.weights.linear_term = linear_weight;
   shw.weights.quadratic_term = quad_term;

   save("shw_"+loop+"_"+method+"_"+Case,"shw")
end


