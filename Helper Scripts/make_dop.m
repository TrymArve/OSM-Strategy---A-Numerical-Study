
total_time = tic;
disp(" ")

disp("|| \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")
disp('|| Creating dynamic optimization problem (dynamic NLP) ...');


% Reset stuff:
prev_input = [];
prev_state = [];
next_state = [];
aux = [];


N_horizon = N_shooting_intervals*N_samples_per_interval;

% Symbolic Parameters
parameters_sym = model.cas.param.values;
measured_state_sym = casadi.SX.sym('measured_state',[model.dim.state,1]);
Dt_sym = casadi.SX.sym('Dt');
C.dop_parameters = StructorSX;
C.dop_parameters.add('param',parameters_sym,'measured_state',measured_state_sym,'Dt',Dt_sym);
 
% Set dop parameters:
C.dop_parameters.num.param = model.parameters.values;
C.dop_parameters.num.Dt    = Dt;   



% Create shooting object to hold varibles on the shooting horizon:
C.decision   = StructorSX;
C.equality   = StructorSX;
C.lambda     = StructorSX;
C.inequality = StructorSX;
C.mu         = StructorSX;



%%%%%%% Create Decision Variables
fprintf('||      --- Creating variables ... ');var_time = tic;

% For each shooting interval, create relevant variables and add to shooting-object:
inputs  = configureDictionary("double","cell");
aux     = configureDictionary("double","cell");
outputs = configureDictionary("double","cell");

for s = 1:N_shooting_intervals
   % Create casadi varaibles for shooting interval
   inputs{s}      = casadi.SX.sym(char("input_s"+s),[model.dim.input,N_samples_per_interval]);
   state          = casadi.SX.sym(char("state_s"+s),[model.dim.state,1]);
   aux{s}         = casadi.SX.sym(char("aux_s"+s),numel(disc.aux_vector),N_samples_per_interval);
   outputs{s}     = casadi.SX.sym(char("output_s"+s),[model.dim.outpu,N_samples_per_interval]);

   % Add variables to decision vector:
   C.decision.add('state',state,'input',inputs{s},'aux',aux{s});
end
C.shots.input = inputs;
C.shots.aux = aux;
C.shots.outpu = outputs;
disp([' done. ',sec2str(toc(var_time))])






%%%%% Integrate
fprintf('||      --- Integrating            ... ');ineq_time = tic;

% so that the fields exist, to provide better catch-all functions:
C.equality.add("gap",[],"col",[]);
C.lambda.add("gap",[],"col",[]);

% Initial point:
C.shots.state = configureDictionary("double","cell");
C.shots.state{0} = measured_state_sym;

% Initialize longshot:
C.longshot.input.vars  =  casadi.SX(model.dim.input,0);
C.longshot.state.expr  = C.decision.cas.state(:,1); % state trajectory expressed with decision variables
C.longshot.outpu.vars  = []; %  outputs{0};

for s = 1:N_shooting_intervals

   % Initial value for shooting
   C.shots.state{s} = C.decision.cas.state(:,s);

   % Shooting gap:
   gap = C.shots.state{s}(:,1) - C.shots.state{s-1}(:,end);


   % Dynamic constraints:
   collocation_constraints = casadi.SX([]);
   for j = 1:N_samples_per_interval
      prev_input = inputs{s}(:,j);
      prev_state = C.shots.state{s}(:,j);
      next_state = disc.F(prev_state,prev_input,parameters_sym,aux{s}(:,j),Dt_sym);
      C.shots.state{s} = [C.shots.state{s} next_state];

      collocation_constraints = [collocation_constraints; disc.A(prev_state,prev_input,parameters_sym,aux{s}(:,j),Dt_sym)]; %#ok<*AGROW>
   end

   lambda_gap = casadi.SX.sym(char("lambda_gap_s"+s),size(gap));
   lambda_col = casadi.SX.sym(char("lambda_col_s"+s),size(collocation_constraints));

   C.equality.add("gap",gap,"col",collocation_constraints);
   C.lambda.add("gap",lambda_gap,"col",lambda_col);

   C.longshot.input.vars = [C.longshot.input.vars C.shots.input{s}];
   C.longshot.state.expr = [C.longshot.state.expr C.shots.state{s}(:,2:end)];
   C.longshot.outpu.vars = [C.longshot.outpu.vars outputs{s}];
end

% Output trajectory expressed with decision variables:
C.longshot.outpu.expr = casadi.SX.zeros(model.dim.outpu,size(C.longshot.outpu.vars,2));
for k = 1:N_horizon
   C.longshot.outpu.expr(:,k) = model.y(C.longshot.state.expr(:,k+1),C.longshot.input.vars(:,k),parameters_sym);
end
C.longshot.aux.vars = horzcat(C.shots.aux.values{:});


C.longshot.state.F  = casadi.Function(idstring("F_longshot_state"), {C.decision.vec.cas,C.dop_parameters.vec.cas},{C.longshot.state.expr}, {'decision','opt_par vector'},{'longshot_state'});
C.longshot.outpu.F  = casadi.Function(idstring("F_longshot_output"),{C.decision.vec.cas,C.dop_parameters.vec.cas},{C.longshot.outpu.expr},{'decision','opt_par vector'},{'longshot_output'});
C.F_equality        = casadi.Function(idstring("equality_vector"),{C.decision.vec.cas,C.dop_parameters.vec.cas},{C.equality.vec.cas},{'decision','opt_par vector'},{'equality_vector'});


disp([' done. ',sec2str(toc(ineq_time))])






%%%% Add Inequality Constraints:
inds = struct;
C.inequality.add('bounds',[])
C.mu.add('bounds',[]);

   %%%%%% Create all the decision bounds:
   disp("||      --- Adding decision_bounds ...")
   if bounds.numEntries == 0
      disp(' (none).')
   else
      %%% Preprocess
      inds.outpu = [];
      inds.state = [];
      inds.input = [];
      bound_vec = struct('state',[],'input',[],'outpu',[]);
      bound_vec(2).state = [];
      for bound_type = 1:2
         inds(bound_type).state = [];
         inds(bound_type).input = [];
         for name = bounds.keys'
            if isinf(bounds{name}(bound_type))
               continue;
            end
            if ismember(name,model.names.outpu)
               type = "outpu"; % prioritize output over states if some states are passed as outputs
            elseif ismember(name,model.names.state)
               type = "state";
            elseif ismember(name,model.names.input)
               type = "input";
            else
               error("USER ERROR: you are trying to add a decision bound on a varaible that does not exist: "+name)
            end

            inds(bound_type).(type) = [inds(bound_type).(type); model.ind.(type).(name)];
            bound_vec(bound_type).(type)(end+1) = bounds{name}(bound_type);

         end
      end

      decsion_bounds = {};
      for s = 1:N_shooting_intervals
         for j = 1:N_samples_per_interval
            next_outpu = C.shots.outpu{s}(:,j);
            next_state = C.shots.state{s}(:,j+1);
            current_input = inputs{s}(:,j);
            decsion_bounds{end+1}  = [ current_input(inds(1).input)  - bound_vec(1).input';
                                      -current_input(inds(2).input)  + bound_vec(2).input';
                                       next_state(   inds(1).state)  - bound_vec(1).state';
                                      -next_state(   inds(2).state)  + bound_vec(2).state';
                                       next_outpu(   inds(1).outpu)  - bound_vec(1).outpu';
                                      -next_outpu(   inds(2).outpu)  + bound_vec(2).outpu'];
         end
      end
   end

   %%%%%% Append Bounds:
   n_bounds = size(decsion_bounds{1},1);
   for stage= 1:N_horizon
      C.inequality.add('bounds',decsion_bounds{stage});
      C.mu.add('bounds',casadi.SX.sym(char("mu_bounds_stage"+stage),n_bounds));
   end

   %%%%%%% Convert to decision variable expressiosn: (they currently contain output varaibles)
   inequality_vector_output = C.inequality.vec.cas;
   F_ineq_output = casadi.Function(idstring('F_ineq_output'),{C.longshot.outpu.vars,C.decision.vec.cas},{inequality_vector_output},{'longshot_output_vars','decision'},{'ineq_vector'});
   inequality_vector_decision = F_ineq_output(C.longshot.outpu.expr,C.decision.vec.cas);
   C.inequality.vec.cas = inequality_vector_decision;
   C.constraints.inequality.output = inequality_vector_output;
   C.constraints.inequality.decision = inequality_vector_decision;


   disp(['||            ... done. ',sec2str(toc(ineq_time))])


% Make inequality function
C.F_inequality = casadi.Function(idstring("inequality_vector"),{C.decision.vec.cas,C.dop_parameters.vec.cas},{inequality_vector_decision},{'decision','opt_par vector'},{'inequality_vector'});


%%%%% Make a function to quickly create an initial guess form reference
C.guess = @(ref_state,ref_input) struct('state', repmat(ref_state,1,C.decision.size.state(2)), ...
                                        'input', repmat(ref_input,1,C.decision.size.input(2)), ...
                                        'aux',   repmat(ref_state,C.decision.size.aux(1)/numel(ref_state),C.decision.size.aux(2)));








disp( "||  ... done. ")
disp( "|| ---------------------------------------------")
disp(['||    - Total Build Time: ',sec2str(toc(total_time))])
disp( "|| ------------------- Horizon: ----------------")
disp( "||    - N.   shooting intervals     :  "+N_shooting_intervals)
disp( "||    - N.   samples per interval   :  "+N_samples_per_interval)
disp( "||    - N. total samples on horizon :  "+N_horizon)
disp( "|| -------------------- Size: ------------------")
disp( "||    - N.   decision variables     :  "+C.decision.len)
disp( "||    - N.   equality constraints   :  "+C.equality.len)
disp( "||    - N. inequality constraints   :  "+C.inequality.len)
disp( "||    - N.      total constraints   :  "+(C.inequality.len+C.equality.len))
disp( "|| ---------------------------------------------")
disp( "||    - Decision:")
disp( "||         - n.state    :  "+C.decision.numel.state)
disp( "||         - n.input    :  "+C.decision.numel.input)
disp( "||         - n.aux      :  "+C.decision.numel.aux)
disp( "||    - Equality:")
disp( "||         - n.gap      :  "+C.equality.numel.gap)
disp( "||         - n.col      :  "+C.equality.numel.col)
disp( "||    - Inequality:")
disp( "||         - n.bounds   :  "+C.inequality.numel.bounds)
disp( "|| //////////////////////////////////////////////////////////")
disp( " ")
