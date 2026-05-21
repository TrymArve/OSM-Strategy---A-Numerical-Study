%%% KKT tolerances
tol = dictionary;
tol("dLag")             = 1e-2;
tol("g")                = 1e-4;
tol("h")                = 1e-4;
tol("dual")             = 1e-4;
tol("complementarity")  = 1e-4;

%%% -------------------- PREPARE QUADPROG
qp_tol = 1e-8;
QPoptions = optimoptions( ...
   'quadprog','Algorithm','active-set','Display','none',...
   'ConstraintTolerance',qp_tol,...
   'FunctionTolerance',qp_tol,...
   'OptimalityTolerance',qp_tol,...
   'StepTolerance',qp_tol,...
   'MaxIterations',1e4);
ws = optimwarmstart(C.decision.vec.num,QPoptions); % quadprog warmstart

% Maximum number of SQP iterations:
sqp_max_iter = 500;

% Choose reset or not guesses back to reference of not
reset_OL_guess = true;
reset_CL_guess = true;