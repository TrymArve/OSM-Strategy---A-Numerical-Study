
if isempty(C.objective)
   error("USER ERROR: the objective must be dfined before generating the derivatives.")
end



fprintf("Making halting-vector ... "); halt_time = tic;



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
dobj = jacobian(obj,decision);



%%%%%%%%%%%%% Modify objective gradient:


%%%% Define some variables
inputs      = C.decision.cas.input;
outputs     = C.longshot.outpu.vars;
input_inds  = reshape([C.decision.ind.input{:}],[],1);
state_inds  = reshape([C.decision.ind.state{:}],[],1);
aux_inds    = reshape([C.decision.ind.aux{:}],[],1);
output_vars = reshape(C.longshot.outpu.vars,N_horizon*model.dim.outpu,1);
output_expr = reshape(C.longshot.outpu.expr,N_horizon*model.dim.outpu,1);


%%%%% Get expressions of outputs:

%{
The expressions of output variables needs to be used to get teh Jacobians
and then the gradients are constructed using the chainrule with the output
sesitivity !! This is because the proper output sensitivity must be used,
which is a propogated sensitivity, instead of the diagonal one. This
appears as eq. (13), using "dc" sensitivites that over-lap with the "ss"
sensitivities at feasible solutions.
%}

obj_output = C.objective.output.expr; % Objective
g_output = C.equality.vec.cas;        % Equality (have not added support for equality constraints... only have gap and col constraints, which are not output dependent)
h_output   = C.constraints.inequality.output;  % Inequality
% OBS: note that if adding equality constraints (g = 0) that are not
% dynamic constraints, then the equalities should also be computed using
% the output dependent expressions. 

% Modified Objective Gradient:
Jobj_u = jacobian(obj_output,inputs);
Jobj_y = jacobian(obj_output,outputs);
dobj_u_modified = Jobj_u + Jobj_y*D_modified;
% % Equality:
Jg_u = jacobian(g_output,inputs);
Jg_y = jacobian(g_output,outputs);
dg_u_true = Jg_u + Jg_y*D_true;
% Modified Inequality Gradient:
Jh_u = jacobian(h_output,inputs);
Jh_y = jacobian(h_output,outputs);
dh_u_true = Jh_u + Jh_y*D_true;

% Substitute in the state expresstions:
dobj_u_modified = casadi.substitute(dobj_u_modified  , output_vars, output_expr);
dg_u_true   = casadi.substitute(dg_u_true    , output_vars, output_expr);
dh_u_true   = casadi.substitute(dh_u_true    , output_vars, output_expr);

% Inject into larger jacobian struture:
dobj(input_inds)      = dobj_u_modified;  % objetive
dg(:,input_inds)      = dg_u_true;    % Equality
dh(:,input_inds)      = dh_u_true;    % Inequality

%%%%%%%%%%%%%% Cancel terms that must be cancelled:

%%% (necesary!) Remove input sensitivity form dynamic constraints:
gap_inds = reshape([C.equality.ind.gap{:}],[],1);
dg(gap_inds,input_inds) = 0; % zeroed
col_inds = reshape([C.equality.ind.col{:}],[],1);
dg(col_inds,input_inds) = 0; % zeroed


% Obs: Note that there are no other equality constraints, so i don't need
% worry about cancelling too many terms here.
% One should also cancel for all other nominal decision variables, but
% there are only inputs in this case.

%%% Remove collocation/integration terms from objective and inequality:

% Not strictly necessary, but helps convergence:
dobj(state_inds) = 0; 
dh(:,state_inds) = 0;
dh(:,aux_inds)   = 0;
dobj(aux_inds)   = 0;


% dobj = dop.MS.cas.mod.obj.d.F(C.decision.vec.cas,[C.dop_parameters.vec.cas; 0]);
% dg   = dop.MS.cas.mod.g.d.F(C.decision.vec.cas,[C.dop_parameters.vec.cas; 0]);
% dh   = dop.MS.cas.mod.h.d.F(C.decision.vec.cas,[C.dop_parameters.vec.cas; 0]);



%%%%%%%%%%%%%% Construct modified stationarity

modified_stationarity = dobj - lambda'*dg - mu'*dh;
% modified_stationarity = dop.MS.cas.mod.Lag.d.F(C.decision.vec.cas,C.lambda.vec.cas,C.mu.vec.cas,[C.dop_parameters.vec.cas; 0]);



%%% ------------------------- HALTING VECTOR:

%%%%% Fischer-Burmeister
epsilon = 1e-8;
FB = sqrt(h.^2 + mu.^2 + epsilon.^2) - h - mu; % Fischer-Burmeister (FB) complimentarity residual with smoothing


res = [modified_stationarity';
              g;
              FB  ]; % residual vector
merit = (norm(res,2)^2) / 2;

s = [decision;
      lambda ;
        mu   ];
Jr = jacobian(res,s);

ind_dec = 1:numel(decision);
ind_lam = numel(decision) + (1:numel(lambda));
ind_mu  = numel(decision) + numel(lambda) + (1:numel(mu));
halt.extract_newton_step = @(s) struct(...
                                 'decision',s(ind_dec),...
                                 'lambda',  s(ind_lam),...
                                 'mu',      s(ind_mu));

res     = casadi.Function(idstring("F_r"),     {decision,lambda,mu,par},{res},  {'decision','lambda','mu','dop_parameters'},{'halting vector'});
merit   = casadi.Function(idstring("GN_merit"),{decision,lambda,mu,par},{merit},{'decision','lambda','mu','dop_parameters'},{'halting merit'});
Jr      = casadi.Function(idstring("GN_Jr"),   {decision,lambda,mu,par},{Jr},   {'decision','lambda','mu','dop_parameters'},{'GN_Jr'});


halt.res   = @(decision,lambda,mu,par) full(res(decision,lambda,mu,par));
halt.Jr    = @(decision,lambda,mu,par) full(Jr(decision,lambda,mu,par));
halt.merit = @(decision,lambda,mu,par) full(merit(decision,lambda,mu,par));







%%% ------------------------ HALTING CONDITIONS


%%%%%%%%%%%% Make Casadi Functions:
 
F_g        = casadi.Function(idstring('F_g'),        {decision,par},{g},    {'decision','dop_parameters'},{'g'});
F_h        = casadi.Function(idstring('F_h'),        {decision,par},{h},    {'decision','dop_parameters'},{'h'});
F_obj      = casadi.Function(idstring('F_obj'),      {decision,par},{obj},  {'decision','dop_parameters'},{'obj'});
F_mod_stat = casadi.Function(idstring('F_modstat'),  {decision,lambda,mu,par},{modified_stationarity},  {'decision','lambda','mu','dop_parameters'},{'modified stationarity'});

%%%%%%%%%%% Callable functions:

C.g       = @(decision,par) full(F_g(decision,par));
C.h       = @(decision,par) full(F_h(decision,par));
C.obj     = @(decision,par) full(F_obj(decision,par));
C.modified_stationarity    = @(decision,lambda,mu,par) full(F_mod_stat(decision,lambda,mu,par));

HC.decision = decision;
HC.lambda = lambda;
HC.mu = mu;
HC.par = par;

HC.m_dLag  = modified_stationarity';
HC.g     = g;
HC.h     = min(h, 0);
HC.dual  = min(mu, 0);
HC.complementarity = h .* mu;

HC.evaluate =  [norm(HC.m_dLag          ,1);
                norm(HC.g               ,1);
                norm(HC.h               ,1);
                norm(HC.dual            ,1);
                norm(HC.complementarity ,1)];


F_HC = casadi.Function(idstring('F_HC'),HC,{'decision','lambda','mu','par'},{'m_dLag','g','h','dual','complementarity','evaluate'});
C.HC = @(decision,lambda,mu,par) full_struct(F_HC.call(struct('decision',decision,'lambda',lambda,'mu',mu,'par',par)));


disp(['done. ',sec2str(toc(halt_time))])