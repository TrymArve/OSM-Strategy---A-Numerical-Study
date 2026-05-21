
total_time = tic;

Termination_MSG = @(allowable_illegal_steps) "(Terminated) Could not produce proper step more than "+allowable_illegal_steps+" times.";


% Prepare stuff
success_falg = 0;
current_KKT = C.KKT(C.decision.vec.num,C.lambda.vec.num,C.mu.vec.num,C.dop_parameters.vec.num);
current_obj = C.obj(C.decision.vec.num,C.dop_parameters.vec.num);





if toggle_display_on

   disp(" ")
   disp("|| \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")
   disp('|| Running SQP ...');


   KKT_vals = current_KKT.evaluate();
   fprintf("|| \n");
   % fprintf("|| || \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
   fprintf("|| || %s\n", "Initial Guess:");
   fprintf("|| ||      --- ∇𝓛  : %.3e\n", KKT_vals(1));
   fprintf("|| ||      ---  g  : %.3e\n", KKT_vals(2));
   fprintf("|| ||      ---  h⁺ : %.3e\n", KKT_vals(3));
   fprintf("|| ||      ---  μ  : %.3e\n", KKT_vals(4));
   fprintf("|| ||      ---  ☉  : %.3e\n", KKT_vals(5));
   % fprintf("|| || ////////////////////////////////\n");
   fprintf("|| \n");


end


allowable_illegal_steps = 5;
n_illegal_steps_left = allowable_illegal_steps;


for i = 1:sqp_max_iter


   %%% --------------------------------- CHECK CONVERGENCE:

   if all(current_KKT.evaluate() < tol.values)
      success_falg = true;
      i = i-1; %#ok<FXSET>
      if i == 0
         termination_msg  = "Already Optimal.";
      else
         termination_msg = "SQP Converged!";
      end
      break;
   end





   %%% --------------------------------- FIND NEWTON STEP:


   % What I need to solve:
   %
   %     min.  phi(x) = (1/2)*x'W*x + J'*x
   %     s.t:
   %              G*x + g  = 0
   %              H*x + h >= 0
   %          %}


   % What quadprog solves:
   %
   %     min.  phi(x) = (1/2)*x'H*x + f'*x
   %     s.t:
   %            Aeq*x - beq  = 0
   %           -Ain*x + bin >= 0
   %          %}

   %{
Thus:
      H =  W,    f =  J

    Aeq =  G,  beq = -g
    Ain = -H,  bin =  h

   %}

   %%%%% Give simple names:
   W = C.d2Lag( ...
      C.decision.vec.num, ...
      C.lambda.vec.num, ...
      C.mu.vec.num, ...
      C.dop_parameters.vec.num);
   J = C.dobj(C.decision.vec.num,C.dop_parameters.vec.num);
   G = C.dg(C.decision.vec.num,C.dop_parameters.vec.num);
   g = -C.g(C.decision.vec.num,C.dop_parameters.vec.num);
   H = -C.dh(C.decision.vec.num,C.dop_parameters.vec.num);
   h = C.h(C.decision.vec.num,C.dop_parameters.vec.num);

   %%%% Ensure Positive Definiteness
   W = make_posdef(W); %+ eye(size(W))*0.0;

   %%%% Solve QP subproblem:
   [ws,~,QP_success,c,lag_mult] = quadprog(W,J,H,h,G,g,[],[],ws);
   if QP_success ~= 1
      disp(" ")
      disp("||   QP-ERROR flag: "+QP_success)
      warning("QP SUBPROBLEM ERROR: "+c.message)
      if n_illegal_steps_left == 0
         termination_msg = Termination_MSG(allowable_illegal_steps);
         break
      else
         n_illegal_steps_left = n_illegal_steps_left - 1;
      end
   end


         
   

   %%%% Extract Newton step:
   Delta.decision     =  ws.X;
   lambda = -lag_mult.eqlin(1: C.lambda.len);   % negate this (since the lagrangian definition of quadprog uses opposite sign from our definition)
   mu     =  lag_mult.ineqlin(1: C.mu.len);     % do not negate this
   Delta.lambda = lambda - C.lambda.vec.num;
   Delta.mu     = mu - C.mu.vec.num;




   %%% --------------------------------- LINESEARCH:

   %%%%%%%%%%%% Prepare Old values:
   nu = norm([C.lambda.vec.num;C.mu.vec.num;lambda;mu],inf);% exact penalty parameter
   current_L1 = current_obj + nu*norm(current_KKT.g,1) + nu*norm(current_KKT.h,1);

   % Prepare loop
   a_min = 1e-13;
   a_rate = 0.5;
   expon = floor(log(a_min)/log(a_rate));
   a_range = [a_rate.^(0:expon) a_min];

   for a = a_range

      update.decision = C.decision.vec.num + a*Delta.decision;
      update.lambda = C.lambda.vec.num + a*Delta.lambda;
      update.mu = C.mu.vec.num + a*Delta.mu;

      %%%% L1 - exact penalty
      new_KKT = C.KKT(update.decision,update.lambda,update.mu,C.dop_parameters.vec.num);
      new_obj = C.obj(update.decision,C.dop_parameters.vec.num);
      new_L1 = new_obj + nu*norm(new_KKT.g,1) + nu*norm(new_KKT.h,1);

      accept = new_L1 <= current_L1;

      if accept
         C.decision.vec.num = update.decision;
         C.lambda.vec.num   = update.lambda;
         C.mu.vec.num       = update.mu;
         break;
      end

   end


   current_KKT = new_KKT;
   current_obj = new_obj;


   if ~accept
      success_falg = false;
      warning(" SQP (iter: " + i + ") Did not find step length (tried a="+a+") ("+n_illegal_steps_left+" illegal steps left)")
      if n_illegal_steps_left == 0
         termination_msg = Termination_MSG(allowable_illegal_steps);
         break
      else
         n_illegal_steps_left = n_illegal_steps_left - 1;
      end
         
   end




   if toggle_display_on
      % ------------------------------------------------------------
      % Display one-line iteration statistics
      % ------------------------------------------------------------
      new_KKT_vals = new_KKT.evaluate();

      fprintf("|| (i)%4d (a)%10.3e (Φ)%12.5e (L₁)%12.5e (d∞)%12.3e (∇𝓛)%12.3e (g)%12.3e (h⁺)%12.3e (μ⁺)%12.3e (☉)%12.3e\n", ...
         i, ...
         a, ...
         new_obj, ...
         new_L1, ...
         norm(Delta.decision, inf), ...
         new_KKT_vals(1), ...
         new_KKT_vals(2), ...
         new_KKT_vals(3), ...
         new_KKT_vals(4), ...
         new_KKT_vals(5));
   end



end

n_iterations = i;
C.equality.vec.num = current_KKT.g;
C.inequality.vec.num = C.h(C.decision.vec.num,C.dop_parameters.vec.num);


if ~success_falg && n_iterations == sqp_max_iter && n_illegal_steps_left >= 0
   termination_msg = "SQP did not converge... (maximum iterations reached: "+sqp_max_iter+")";
end


if toggle_display_on

   KKT_vals = new_KKT.evaluate();

        disp( "|| ---------------------------------------------")
      fprintf("|| \n");
      fprintf("|| || === TERMINATION STATUS ===\n")
         disp("|| ||   - STATUS: "+termination_msg);
      fprintf("|| ||   - N. iterations: %d\n", n_iterations);
      fprintf("|| ||   -     Objective: %d\n", new_obj);
      fprintf("|| ||   - KKT Values:\n");
      fprintf("|| ||      --- ∇𝓛  -> %.3e\n", KKT_vals(1));
      fprintf("|| ||      ---  g  -> %.3e\n", KKT_vals(2));
      fprintf("|| ||      ---  h⁺ -> %.3e\n", KKT_vals(3));
      fprintf("|| ||      ---  μ  -> %.3e\n", KKT_vals(4));
      fprintf("|| ||      ---  ☉  -> %.3e\n", KKT_vals(5));
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