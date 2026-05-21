
if isempty(C.objective)
   error("USER ERROR: the objective must be dfined before generating the derivatives.")
end





%%% --------------------------------------------- CONSTRUCT DERIVATIVES
fprintf('Making derivatives ... ');deriv_time = tic;






%%%%%%%%%% Give simple names for readibility:

% Desicion variables
decision = C.decision.vec.cas;

% Constraints
g = C.equality.vec.cas;
h = C.inequality.vec.cas;

% Multipliers
lambda = C.lambda.vec.cas; %#ok<*PROP>
mu =  C.mu.vec.cas;

% Objective
obj = C.objective.decision.expr;

% DOP-parameters
par = C.dop_parameters.vec.cas;




%%%%%%%%%%%% Construct Derivatives:

% Constraint Jacobians
dg = jacobian(g,decision);
dh = jacobian(h,decision);

% Objective Derivatives:
[d2obj,dobj] = hessian(obj,decision);
dobj = dobj'; % transpose, since hessian() provides the gradient, not the jacobian


% Lagrangian:
Lag = obj - lambda'*g - mu'*h;
[d2Lag,dLag] = hessian(Lag,decision);
dLag = dLag'; % transpose, since hessian() provides the gradient, not the jacobian





%%%%%%%%%%%% Make Casadi Functions:

% Equality
F_g     = casadi.Function(idstring('F_g'), {decision,par},{g},   {'decision','opt_par'},{'g'});
F_dg    = casadi.Function(idstring('F_dg'),{decision,par},{dg},  {'decision','opt_par'},{'dg'});

% Inequality
F_h     = casadi.Function(idstring('F_h'), {decision,par},{h},   {'decision','opt_par'},{'h'});
F_dh    = casadi.Function(idstring('F_dh'),{decision,par},{dh},  {'decision','opt_par'},{'dh'});


% Objective
F_obj    = casadi.Function(idstring('F_obj'),  {decision,par},{obj},  {'decision','opt_par'},{'obj'});
F_dobj   = casadi.Function(idstring('F_dobj'), {decision,par},{dobj}, {'decision','opt_par'},{'dobj'});
F_d2obj  = casadi.Function(idstring('F_d2obj'),{decision,par},{d2obj},{'decision','opt_par'},{'d2obj'});

% Lagrangian
F_Lag    = casadi.Function(idstring('F_Lag'),  {decision,lambda,mu,par},{Lag},  {'decision','lambda','mu','opt_par'},{'Lag'});
F_dLag   = casadi.Function(idstring('F_dLag'), {decision,lambda,mu,par},{dLag}, {'decision','lambda','mu','opt_par'},{'dLag'});
F_d2Lag  = casadi.Function(idstring('F_d2Lag'),{decision,lambda,mu,par},{d2Lag},{'decision','lambda','mu','opt_par'},{'d2Lag'});






%%%%%%%%%%% Callable functions:

C.g       = @(decision,par) full(F_g(decision,par));
C.dg      = @(decision,par) full(F_dg(decision,par));

C.h       = @(decision,par) full(F_h(decision,par));
C.dh      = @(decision,par) full(F_dh(decision,par));

C.obj     = @(decision,par) full(F_obj(decision,par));
C.dobj    = @(decision,par) full(F_dobj(decision,par));
C.d2obj   = @(decision,par) full(F_d2obj(decision,par));

C.Lag     = @(decision,lambda,mu,par) full(F_Lag(decision,lambda,mu,par));
C.dLag    = @(decision,lambda,mu,par) full(F_dLag(decision,lambda,mu,par));
C.d2Lag   = @(decision,lambda,mu,par) full(F_d2Lag(decision,lambda,mu,par));

KKT.decision = decision;
KKT.lambda = lambda;
KKT.mu = mu;
KKT.par = par;

KKT.dLag  = dLag';
KKT.g     = g;
KKT.h     = min(h, 0);
KKT.dual  = min(mu, 0);
KKT.complementarity = h .* mu;

KKT.evaluate = [norm(KKT.dLag            ,1);
                norm(KKT.g               ,1);
                norm(KKT.h               ,1);
                norm(KKT.dual            ,1);
                norm(KKT.complementarity ,1)];


F_KKT = casadi.Function(idstring('F_KKT'),KKT,{'decision','lambda','mu','par'},{'dLag','g','h','dual','complementarity','evaluate'});
C.KKT = @(decision,lambda,mu,par) full_struct(F_KKT.call(struct('decision',decision,'lambda',lambda,'mu',mu,'par',par)));


disp(['done. ',sec2str(toc(deriv_time))])