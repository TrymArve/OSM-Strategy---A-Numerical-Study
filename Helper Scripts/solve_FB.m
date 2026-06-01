
total_time = tic;



% Prepare stuff
success_falg = 0;
current_HC = C.HC(C.decision.vec.num,C.lambda.vec.num,C.mu.vec.num,C.dop_parameters.vec.num);
current_obj = C.obj(C.decision.vec.num,C.dop_parameters.vec.num);
current_merit = halt.merit(C.decision.vec.num, C.lambda.vec.num, C.mu.vec.num, C.dop_parameters.vec.num);




if toggle_display_on

   disp(" ")
   disp("|| \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")
   disp('|| Running FB method ...');


   HC_vals = current_HC.evaluate();
   fprintf("|| \n");
   % fprintf("|| || \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
   fprintf("|| || %s\n", "Initial Guess:");
   fprintf("|| ||      --- m-∇𝓛  : %.3e\n", HC_vals(1));
   fprintf("|| ||      ---    g  : %.3e\n", HC_vals(2));
   fprintf("|| ||      ---    h⁺ : %.3e\n", HC_vals(3));
   fprintf("|| ||      ---    μ  : %.3e\n", HC_vals(4));
   fprintf("|| ||      ---    ☉  : %.3e\n", HC_vals(5));
   % fprintf("|| || ////////////////////////////////\n");
   fprintf("|| \n");


end


allowable_illegal_steps = 5;
n_illegal_steps_left = allowable_illegal_steps;


for i = 1:sqp_max_iter


   %%% --------------------------------- CHECK CONVERGENCE:

   if all(current_HC.evaluate() < tol.values)
      success_falg = true;
      i = i-1; %#ok<FXSET>
      if i == 0
         termination_msg  = "Already Solved.";
      else
         termination_msg = "FB Converged!";
      end
      break;
   end





   %%% --------------------------------- FIND NEWTON STEP:

   res = halt.res(C.decision.vec.num, C.lambda.vec.num, C.mu.vec.num, C.dop_parameters.vec.num);
   Jr  = halt.Jr( C.decision.vec.num, C.lambda.vec.num, C.mu.vec.num, C.dop_parameters.vec.num);


   % warning('off', 'MATLAB:nearlySingularMatrix');
   Ds = -Jr \ res;
   % warning('on', 'MATLAB:nearlySingularMatrix');


   %%%% Extract Newton step:
   Delta = halt.extract_newton_step(Ds);


   %%% --------------------------------- LINESEARCH:

   %%%%%%%%%%%% Prepare Old values:
   

   % Prepare loop
   a_min = 1e-13;
   a_rate = 0.5;
   expon = floor(log(a_min)/log(a_rate));
   a_range = [a_rate.^(0:expon) a_min];

   for a = a_range

      update.decision = C.decision.vec.num + a*Delta.decision;
      update.lambda = C.lambda.vec.num + a*Delta.lambda;
      update.mu = C.mu.vec.num + a*Delta.mu;

      new_merit = halt.merit(update.decision,update.lambda,update.mu,C.dop_parameters.vec.num);

      accept = new_merit <= current_merit;

      if accept
         C.decision.vec.num = update.decision;
         C.lambda.vec.num   = update.lambda;
         C.mu.vec.num       = update.mu;
         break;
      end

   end

   current_merit = new_merit;
   current_HC  = C.HC(C.decision.vec.num,C.lambda.vec.num,C.mu.vec.num,C.dop_parameters.vec.num);
   current_obj = C.obj(C.decision.vec.num,C.dop_parameters.vec.num);


   if ~accept
      success_falg = false;
      warning(" FB (iter: " + i + ") Did not find step length (tried a="+a+") ("+n_illegal_steps_left+" illegal steps left)")
      if n_illegal_steps_left == 0
         termination_msg = "(Terminated) Could not find descent step length more than "+allowable_illegal_steps+" times.";
         break
      else
         n_illegal_steps_left = n_illegal_steps_left - 1;
      end
         
   end




   if toggle_display_on
      % ------------------------------------------------------------
      % Display one-line iteration statistics
      % ------------------------------------------------------------
      new_HC_vals = current_HC.evaluate();

      fprintf("|| (i)%4d (a)%10.3e (Φ)%12.5e (L₁)%12.5e (d∞)%12.3e (∇𝓛)%12.3e (g)%12.3e (h⁺)%12.3e (μ⁺)%12.3e (☉)%12.3e\n", ...
         i, ...
         a, ...
         current_obj, ...
         current_merit, ...
         norm(Delta.decision, inf), ...
         new_HC_vals(1), ...
         new_HC_vals(2), ...
         new_HC_vals(3), ...
         new_HC_vals(4), ...
         new_HC_vals(5));
   end



end

n_iterations = i;
C.equality.vec.num = current_HC.g;
C.inequality.vec.num = C.h(C.decision.vec.num,C.dop_parameters.vec.num);


if ~success_falg && n_iterations == sqp_max_iter && n_illegal_steps_left >= 0
   termination_msg = "FB did not converge... (maximum iterations reached: "+sqp_max_iter+")";
end


if toggle_display_on

   HC_vals = current_HC.evaluate();

        disp( "|| ---------------------------------------------")
      fprintf("|| \n");
      fprintf("|| || === TERMINATION STATUS ===\n")
         disp("|| ||   - STATUS: "+termination_msg);
      fprintf("|| ||   - N. iterations: %d\n", n_iterations);
      fprintf("|| ||   -     Objective: %d\n", current_obj);
      fprintf("|| ||   - Halting Conditions:\n");
      fprintf("|| ||      --- m-∇𝓛  -> %.3e\n", HC_vals(1));
      fprintf("|| ||      ---    g  -> %.3e\n", HC_vals(2));
      fprintf("|| ||      ---    h⁺ -> %.3e\n", HC_vals(3));
      fprintf("|| ||      ---    μ  -> %.3e\n", HC_vals(4));
      fprintf("|| ||      ---    ☉  -> %.3e\n", HC_vals(5));
      fprintf("|| \n");
        disp(['||  ... done.  Total Solve Time: ',sec2str(toc(total_time))])
        disp( "|| //////////////////////////////////////////////////////////")
        disp( " ")
end

temp_tol = tol.values;
if norm(C.equality.vec.num,1) > temp_tol(2)
   % Equality (and thus model dynamics) is not satisfied, which mean that the solution is garbage.
   C.decision.vec.num(:) = nan;
   error("Garbage !! The dynamic constraints are not satisfied...")
end