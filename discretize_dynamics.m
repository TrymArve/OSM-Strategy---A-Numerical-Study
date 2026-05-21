classdef discretize_dynamics
%{
This class defines a single integration step.
That is, it generates the discrete dynamcis x_next = f_d(x_now), based on
the integration scheme of your choice.
%}
   properties(SetAccess=immutable)
      f (1,1) % continuous dynamics: x_dot = f(x,u,p)
      F (1,1) % discrete dynamics: x_next = F(x,u,p,Aux,Dt)
      A  % Auxiliary expressions that should equal to zero for F to be an integration scheme (algebraic constraint: A = 0)
      dF % sensitivity matrices
      order (1,1) double {mustBeNonnegative} = 0; % integration order (set to 0 for custom methods with unknown order...)
      n_increments (1,1) double {mustBeInteger,mustBePositive} = 1;
      n_stages     (1,1) double {mustBeInteger} = 0;
      plicity (1,1) string {mustBeMember(plicity,["explicit","implicit"])} = "explicit"; % integration type
      integrator (1,1) string % name of integration scheme (if given a name)
      aux (1,1) dictionary = configureDictionary('double','cell'); % auxiliary variables
   end

   properties(Dependent)
      aux_vector
      dim_F
      dim_A
   end

   properties
      Dt double % You may add a numeric time step size that is recomemnded to use when stepping, to ensure accurate steps.
   end
   
   properties(SetAccess=immutable,Hidden)
      dim (1,1) struct = struct;
      BT_b double
      BT_A double
      collocation (1,1) struct
   end

   methods
      function C = discretize_dynamics(required,options)
         arguments
            
            % Required arguments (in struct style for ease of use when calling the contructor)
            required.f (1,1) casadi.Function % x_dot = f(x,u,p)
            required.method (1,1) string {mustBeMember(required.method,["Explicit Euler","Implicit Euler","ERK4","ERK4 (simultaneous)","Implicit Midpoint","Crank-Nicolson (Implicit)","IRK4 (L-stable)","Gauss-Legendre (4. order)","Gauss-Legendre (6. order)","custom collocation","custom explicit butcher tableau","custom implicit butcher tableau"])}

            
            
            % General settings:
            options.n_increments (1,1) double {mustBePositive,mustBeInteger} = 1;

            % Collocaiton Specific settigns:
            options.collocation_polynomial_order (1,1) double {mustBePositive,mustBeInteger} = 2;
            options.collocation_polynomial_type (1,1) string {mustBeMember(options.collocation_polynomial_type,["legendre","radau"])} = "legendre";

            options.bucher_tableau_b (1,:) double {mustBeReal}
            options.bucher_tableau_A (:,:) double {mustBeReal}
         end

         fprintf('Discretizing dynamics...  ');
         def_time = tic;

         for field = ["f","method"]
            if ~isfield(required,field)
               error(['REQUIRED ARGUMENTS: "f" (continuous dynamics as casadi.Function - x_dot = f(x,u,p)), and "method" (integration scheme to be used). You are missing "',char(field),'"'])
            end
         end

         % Store continuous model:
         C.f = required.f;

         % Store integrator information:
         C.integrator = required.method;
         C.n_increments = options.n_increments;

         % Define time-step variables:
         Dt = casadi.SX.sym('Dt');
         dt = (Dt/C.n_increments);

         % Auxiliary variables and expressions:
         aux_var = dictionary;% structor("default_mix","TRYMPC_horizon");
         aux_expr = dictionary;%structor("default_mix","TRYMPC_horizon");



         % Get number of inputs
         n_inputs = C.f.n_in();
         if n_inputs > 3
            error('Dynamics (f(x,u,p)) should not have more than three arguments.')
         elseif n_inputs < 2
            error('Dynamics must have at least two arguments (i.e. f(x,u,p) or f(x,u)).')
         end

         % initialize at zero
         names = ["state","input","param"];
         for name = names
            C.dim.(name) = 0;
         end

         % Loop through each input to get its size
         for i = 1:n_inputs
            sz = C.f.size_in(i-1);  % CasADi uses zero-based indexing
            if sz(2) ~= 1
               error(['The ',char(names(i)),' argument of dynamics (f(x,u,p)) should be a column vector.'])
            end
            C.dim.(names(i)) = sz(1);
         end


         input      = casadi.SX.sym('input',[C.dim.input, 1]);
         param      = casadi.SX.sym('param',[C.dim.param, 1]);
         prev_state = casadi.SX.sym('state_prev',[C.dim.state, 1]);
         next_state = prev_state;

         f = C.f;

         % Create global stage variable
         stages = 0;

         %% Select Integrator

         % define integrator:
         switch C.integrator
            case "Explicit Euler"
               C.order = 1;
               C.plicity = "explicit";
               
               % Butcher Tableau:
               C.BT_b = 1;
               C.BT_A = 0;

               ERK_builder

            case "Implicit Euler"

               C.order = 1;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = 1;
               C.BT_A = 1;

               IRK_builder

            case "ERK4"
               C.order = 4;
               C.plicity = "explicit";

               % Butcher Tableau:
               C.BT_b = [1 2 2 1]/6;
               C.BT_A = zeros(4);
               C.BT_A(2,1) = 1/2;
               C.BT_A(3,2) = 1/2;
               C.BT_A(4,3) = 1;

               ERK_builder

            case "ERK4 (simultaneous)"
               C.order = 4;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = [1 2 2 1]/6;
               C.BT_A = zeros(4);
               C.BT_A(2,1) = 1/2;
               C.BT_A(3,2) = 1/2;
               C.BT_A(4,3) = 1;

               IRK_builder

            case "Implicit Midpoint"

               C.order = 2;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = 1;
               C.BT_A = 1/2;

               IRK_builder

            case "Crank-Nicolson (Implicit)"

               C.order = 2;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = [1 1]/2;
               C.BT_A = [0 0; 1 1]/2;

               IRK_builder

            case "Gauss-Legendre (4. order)"

               C.order = 4;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = [1 1]/2;
               C.BT_A = [   1/4         1/4-sqrt(3)/6 ;
                  1/4+sqrt(3)/6      1/4       ];

               IRK_builder

            case "Gauss-Legendre (6. order)"

               C.order = 6;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = [5/18 4/9 5/18];
               C.BT_A = [5/36              2/9-sqrt(15)/15   5/36-sqrt(15)/30;
                                    5/36+sqrt(15)/24      2/9           5/36-sqrt(15)/24;
                                    5/36+sqrt(15)/30  2/9+sqrt(15)/15   5/36];

               IRK_builder

            case "IRK4 (L-stable)"

               C.order = 3;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = [3 -3 1 1]/2;
               C.BT_A = [ 1   0   0   0  ;
                                    1/3  1   0   0  ;
                                    -1   1   1   0  ;
                                     3  -3   1   1  ] /2;

               IRK_builder

            case "custom explicit butcher tableau"
               if ~isfield(options,'bucher_tableau_b')
                  TRYMPC2.usererror('the b-vector of a butcher tableau must be defined to use a custom butcher tableau. Try f.ex. "ERK4" for a predefined RK method.')
               end
               if ~isfield(options,'bucher_tableau_A')
                  TRYMPC2.usererror('the A-matrix of a butcher tableau must be defined to use a custom butcher tableau. Try f.ex. "ERK4" for a predefined RK method.')
               end

               C.order = 0;
               C.plicity = "explicit";

               % Butcher Tableau:
               C.BT_b = options.bucher_tableau_b;
               C.BT_A = options.bucher_tableau_A;

               ERK_builder

            case "custom implicit butcher tableau"
               if ~isfield(options,'bucher_tableau_b')
                  TRYMPC2.usererror('the b-vector of a butcher tableau must be defined to use a custom butcher tableau. Try f.ex. "IRK4" for a predefined RK method.')
               end
               if ~isfield(options,'bucher_tableau_A')
                  TRYMPC2.usererror('the A-matrix of a butcher tableau must be defined to use a custom butcher tableau. Try f.ex. "IRK4" for a predefined RK method.')
               end

               C.order = 0;
               C.plicity = "implicit";

               % Butcher Tableau:
               C.BT_b = options.bucher_tableau_b;
               C.BT_A = options.bucher_tableau_A;

               IRK_builder

            case "custom collocation"

               % save collocation settings:
               C.collocation.d = options.collocation_polynomial_order;
               C.collocation.polynomial_type = options.collocation_polynomial_type;
               
               C.plicity = "implicit";
               
               % specify order
               switch C.collocation.polynomial_type
                  case "legendre"
                     C.order = C.collocation.d*2;
                  case "radau"
                     C.order = C.collocation.d*2 - 1;
                     % warning('DEVELOPER ERROR: ops, I am unsure if I have built the collocation scheme specifically for Legendre, of if simply choosing Radau point will procude the correct Radau collocation shceme. - Trym')
                  otherwise
                     error('DEVELOPER ERROR: an invalid colloocation polynomial type was selected')
               end


               %%%%%%%% MAKE LGARANGE POLYNMIAL COEFFIECIENTS
               d = C.collocation.d; % order of integration and order of polynomial
               C.collocation.tau = [0 casadi.collocation_points(d, char(C.collocation.polynomial_type))]; % choose collocaiton points (based on either gauss-legendre or gauss-radau quadrature)
               C.collocation.Li = [];
               C.collocation.dLi = [];
               % Construct Lagrange interpolation polynomials:
               for j=1:d+1
                  coeff = 1;
                  for r=1:d+1
                     if r ~= j
                        coeff = conv(coeff, [1, -C.collocation.tau(r)]);
                        coeff = coeff / (C.collocation.tau(j)-C.collocation.tau(r));
                     end
                  end
                  C.collocation.Li(j,:) = coeff;
                  C.collocation.dLi(j,:) = polyder(coeff);
               end
               %%%%%%%% ... END OF MAKING LAGRANGE POLYNOMIAL COEFFICIENTS

               collocation_builder
         end
         
         %% Create Integrator Functions



         % Auxiliary functions (=0)
         if C.plicity == "implicit"
            C.aux = aux_var; % store aux variables
            aux_vec = C.aux_vector;
            aux_expr = cellfun( @(aux_cell) vertcat(aux_cell{:}), values(aux_expr), 'UniformOutput',false);
            aux_expr = [vertcat(aux_expr{:})];
            A = casadi.Function(idstring('Algebraics'),{prev_state,input,param,aux_vec,Dt},{aux_expr},{'prev_state','input','parameter','auxiliary','Dt'},{'algebraic_expression'}); % Expressions that should be zero. (both algebraic equations, and auxiliary integration equations)
            C.A = A;
         else
            aux_vec = [];
            aux_expr = [];
            C.A = casadi.Function(idstring('Algebraics'),{prev_state,input,param,aux_vec,Dt},{casadi.SX([])},{'prev_state','input','parameter','auxiliary','Dt'},{'empty_algebraic_expression'});
         end

         % Discrete dynamics
         F = casadi.Function(idstring('F_next_state'),{prev_state,input,param,aux_vec,Dt},{next_state},{'prev_state','input','parameter','auxiliary','Dt'},{'next_state'}); % discrete dynamics

         C.F = F;


         %%%%%  --------- Also compute the sensitivitiy of F w.r.t. x and u:

         %%% Jacobians of F
         Jac_F_x = jacobian(next_state,prev_state);
         Jac_F_u = jacobian(next_state,input);
         Jac_F_a = jacobian(next_state,aux_vec);

         %%% Jacobians of A
         Jac_A_x = jacobian(aux_expr,prev_state);
         Jac_A_u = jacobian(aux_expr,input);
         if isempty(aux_expr)
            Jac_A_a = [];
         else
            Jac_A_a = jacobian(aux_expr,aux_vec);
         end
         %%% Total sensitivities of F
         Der_F_x = Jac_F_x - Jac_F_a * solve(Jac_A_a,Jac_A_x);
         Der_F_u = Jac_F_u - Jac_F_a * solve(Jac_A_a,Jac_A_u);

         C.dF.state = casadi.Function(idstring('Derivative_F_state'),{prev_state,input,param,aux_vec,Dt},{Der_F_x},{'prev_state','input','parameter','auxiliary','Dt'},{'Der_F_x'});
         C.dF.input = casadi.Function(idstring('Derivative_F_input'),{prev_state,input,param,aux_vec,Dt},{Der_F_u},{'prev_state','input','parameter','auxiliary','Dt'},{'Der_F_u'});

         

         % Remember number of stages
          C.n_stages = stages;

         disp(['done.  ',sec2str(toc(def_time)),'  (use  "discretize_dynamics.help"  for more info)'])
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END OF CONSTRUCTOR



         %% RK Builders

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUNGE-KUTTA:
         function ERK_builder


            % Buthcer Tableau:
            b = reshape(C.BT_b,[],1);
            A = C.BT_A;
            stages = length(b);
            

            % Integrate system using RK method described by Butcher Tableau:
            for inc = 1:C.n_increments
               k = f(next_state,input,param);
               for s = 2:stages
                  state = next_state;
                  for a = 1:s-1
                     state = state + dt*A(s,a)*k(:,a);
                  end
                  k = [k f(state,input,param)]; %#ok<AGROW>
               end
               next_state = next_state + dt*(k*b);
            end
         end

         function IRK_builder

            % Butcher Tableau:
            b = reshape(C.BT_b,[],1);
            A = C.BT_A;
            stages = length(b);      % number of RK stages
           
            nx = C.dim.state;

            % 1) Create stage STATE variables X_s for each increment
            for inc = 1:C.n_increments
               X = casadi.SX.zeros(nx, stages);
               for s = 1:stages
                  X(:,s) = casadi.SX.sym( ...
                     ['X_inc', num2str(inc), '_stage', num2str(s)], ...
                     [nx, 1]);
               end
               aux_var(inc) = {X};   % aux_var{inc}(:,s) = X_s
            end

            % 2) Build IRK algebraic equations and state update
            for inc = 1:C.n_increments

               X = aux_var{inc};                     % stage states (nx x stages)
               Fx = casadi.SX.zeros(nx, stages);     % f(X_s) at each stage

               % Evaluate dynamics at each stage state
               for s = 1:stages
                  Fx(:,s) = f(X(:,s), input, param); % k_s = f(X_s)
               end

               % Stage equations: X_s - (x + dt * sum_j A_{s j} f(X_j)) = 0
               X_alg = casadi.SX.zeros(nx, stages);
               for s = 1:stages
                  X_alg(:,s) = X(:,s) - ( ...
                     next_state + dt * Fx * A(s,:).' );
               end

               % Store algebraic expressions for this increment
               aux_expr(inc) = {X_alg};

               % State update: x_{k+1} = x_k + dt * sum_s b_s f(X_s)
               next_state = next_state + dt * (Fx * b);
            end

         end



         %% COLLOCATION
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%% COLLOCATION
         function collocation_builder

            % define number of stages
            stages = C.collocation.d;
            

            % Create symbolic variables for collocation coefficients (analogous to state variables at the collocation points)
            for inc = 1:C.n_increments
               k = casadi.SX.zeros([C.dim.state,stages]);
               for s = 1:stages
                  k(:,s) = casadi.SX.sym(['k_inc',num2str(inc),'_stage',num2str(s)],[C.dim.state,1]);
               end
               aux_var(inc) = {k};
            end


            %%%%%%%%%%% Create casadi-Function to represent the collocation polynomial p (and dp) to use on each interval:

            %%% Use collocation variables of first inc to define casadi-function:

            % Prepare args for casadi function:
            tau = casadi.SX.sym('tau');
            

            % Create collocation polynomial p
            tau_powers = transpose(tau.^(C.collocation.d:-1:0));
            p.expr = [next_state aux_var{1}] * C.collocation.Li *  tau_powers;

            % prepare args
            in_args = struct;
            in_args.state = next_state;
            in_args.aux   = aux_var{1};
            in_args.tau   = tau;
            infields = fieldnames(in_args);
            args = in_args;
            
            % Create casadi function
            args.out = p.expr;
            p.F = casadi.Function('F_collocation_p',args,infields,{'out'});


            % Create collocation polynomial derivative; dp
            tau_powers = transpose(tau.^(C.collocation.d-1:-1:0));
            dp.expr = [next_state aux_var{1}] * C.collocation.dLi * tau_powers;

            % Create casadi function
            args.out = dp.expr;
            dp.F = casadi.Function('F_collocation_dp',args,infields,{'out'});


            in_args.state = next_state; % initial condition for first increment
            for inc = 1:C.n_increments
               in_args.aux = aux_var{inc}; % get auxiliary variables for current increment
               collocation_alg = casadi.SX.zeros([C.dim.state,C.collocation.d]); % prepare container for expressions

               % create collocation constraint at each tau
               for c = 1:C.collocation.d
                  in_args.tau = C.collocation.tau(c+1); % skip first entry since this I added zero to the beginning of the tau vector
                  p_of_tau = in_args.aux(:,c); % evaluate p at tau (can use the aux var directly, since p is designed to be equal to the aux-vars at their respective taus)
                  collocation_alg(:,c) = dt*f(p_of_tau,input,param) - dp.F.call(in_args).out;
               end

               % Update the state variable to be the next state:
               in_args.tau = 1; % evaluate the polynomial at tau=1 to find next state
               in_args.state = p.F.call(in_args).out; % update the state to be the next state

               % store algebraic expression: (should equal zero to constitute an integration scheme)
               aux_expr(inc) = {collocation_alg};
            end

            % Finally, the final/('next') state variable is:
            next_state = in_args.state;

         end


      end
   end




   methods
      function aux_vec = get.aux_vector(C)
         aux_vec = cellfun( @(aux_cell) vertcat(aux_cell{:}), values(C.aux), 'UniformOutput',false);
         aux_vec = [vertcat(aux_vec{:})];
      end

      function sz1 = get.dim_F(C)
         sz = C.F.size_out(0);
         sz1 = sz(1);
      end

      function sz1 = get.dim_A(C)
         sz = C.A.size_out(0);
         sz1 = sz(1);
      end
   end


   methods(Static)
      function help
         disp(" ")
         disp("|| ==========================================================================================================")
         disp("|| ================================= HOW TO: (discretized_dynamics) =========================================")
         disp("|| ==========================================================================================================")
         disp("|| ")
         disp("|| Fields:")
         disp("|| -> F - the discretized dynamcis \newline")
         disp("||        use:  x_next = F(x,u,p,aux,Dt)")
         disp("||        where:")
         disp("||                 x - current state")
         disp("||                 u - constant input over interval")
         disp("||                 p - parameters (if the original dynamics are defined without parameters, this is omitted)")
         disp("||               aux - auxiliary variables (only for implicit integrators). Use 'aux_vector'/'aux' to access these variables")
         disp("||                Dt - step length")
         disp("|| -> A - Algebraic constraints (axuliary expressions that should equal zero)")
         disp("||        use:  A(x,u,p,aux,Dt)   (should ensure A(...) = 0 for F to a valid discretization)")
         disp("||        (with the same inputs as F)")
         disp("||        Only applicable for implicit methods.")
         disp("|| -> aux - contains the auxiliary variables for implicit methods.")
         disp("||          This is a dictionary with keys for each increment, ")
         disp("||          and the values are cell arrays containing the stage variables columnwise: (n_state,n_stages)")
         disp("||          (i.e.  'my_disc.aux{inc}(:,s)'  provides the auxiliary vector for stage s for increment inc)")
         disp("|| -> aux_vector - vectorized version of aux")
         disp("|| ")
         disp("|| ----------------------------------------------------------------------------------------------------------")
         disp("|| How to call constructor (how to use discretizer):")
         disp("||     # call:   'my_disc = discretize_dynamics( ... )'")
         disp("||     # required arguments:")
         disp("||                    f - The continuous dynamics as a casadi function ('casadi.Function')")
         disp("||                          Must have arguments: (state,input) or (state,input,parameters). i.e: x_dot = f(x,u,p) or x_dot = f(x,u)")
         disp("||               method - The integration scheme. Choose amoung predefiend schemes, or one of the custom options to define your own scheme.")
         disp("||                          Custom - If you choose custom ERK/IRK, simply privide the butcher tableu. (see optional arguments)")
         disp("||                                 - If choosing custom collocation, simply provide polynomial type and order. (see optional arguments)")
         disp("||     # optional arguments:")
         disp("||           (general)")
         disp("||                           n_increments - number of integration steps per discretization interval.")
         disp("||           (ERK/IRK)")
         disp("||                       bucher_tableau_b - the b vector of a buther tableu")
         disp("||                       bucher_tableau_A - the b matrix of a buther tableu")
         disp("||       (collocation)")
         disp("||           collocation_polynomial_order - the polynomial order (integration order is twice this order legendre, and twice minus one for radau)")
         disp("||            collocation_polynomial_type - the polynomial type (legendre/radau)")
         disp("||                                          (note: use legendre for maximum integration order, and use radau for the 'stiff decay' property)")
         disp("||     # Example:")
         disp('||          my_disc = discretize_dynamics( "f",f,"method","custom collocation","n_increments",3,"collocation_polynomial_order",3,"collocation_polynomial_type","legendre") ")')
         disp("|| ==========================================================================================================")
         disp("|| ==========================================================================================================")
         disp(" ")
      end
   end
end

