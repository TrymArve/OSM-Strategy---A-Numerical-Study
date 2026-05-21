
fprintf("Computing sensitivity matrix ... "); sens_time = tic;

%%% Make all state-to-state sensitivities:
A = configureDictionary('double','cell'); % contains all state-to-state sensitivity matrices
B = configureDictionary('double','cell'); % contains all input-to-state sensitivity matrices

% fprintf("(getting steps:A,B)..")
for k = 0:N_horizon-1
   state_k   = C.longshot.state.expr(:,k+1); % since this array contains expression propagating at lengths according to the shooting length, the correct propagation of sensitivites is handeled automatically.
   input_k   = C.longshot.input.vars(:,k+1);
   aux_vec_k = C.longshot.aux.vars(:,k+1);

   % sensitivities w.r.t. the immediately previous state and input:
   A{k} = disc.dF.state(state_k,input_k,C.dop_parameters.cas.param,aux_vec_k,C.dop_parameters.cas.Dt);
   B{k} = disc.dF.input(state_k,input_k,C.dop_parameters.cas.param,aux_vec_k,C.dop_parameters.cas.Dt);
end
% fprintf("(getting state-sens)..")
% Propagate forwards:
% Sens = casadi.SX.zeros(numel(C.longshot.state.expr),numel(C.longshot.input.vars));
State_Sens = casadi.Sparsity(numel(C.longshot.state.expr(:,2:end)),numel(C.longshot.input.vars));
State_Sens = casadi.SX(State_Sens);
Row = casadi.SX(model.dim.state,0);
A{0} = casadi.SX.eye(model.dim.state);
for k = 0:N_horizon-1
   Row = [A{k}*Row B{k}];
   State_Sens(k*model.dim.state + (1:model.dim.state), 1:size(Row,2)) = Row;
end

% fprintf("(getting output-sens)..")
Jac_y_u = casadi.SX(casadi.Sparsity(numel(C.longshot.outpu.expr),numel(C.longshot.input.vars)));
Jac_y_x = casadi.SX(casadi.Sparsity(numel(C.longshot.outpu.expr),numel(C.longshot.state.expr(:,2:end))));
for k = 1:N_horizon
   Jac_y_u((k-1)*model.dim.outpu + (1:model.dim.outpu),  (k-1)*model.dim.input + (1:model.dim.input)) = F_Jy_u(C.longshot.state.expr(:,k),C.longshot.input.vars(:,k),C.dop_parameters.cas.param);
   Jac_y_x((k-1)*model.dim.outpu + (1:model.dim.outpu),  (k-1)*model.dim.state + (1:model.dim.state)) = F_Jy_x(C.longshot.state.expr(:,k),C.longshot.input.vars(:,k),C.dop_parameters.cas.param);
end
D_true = Jac_y_u + Jac_y_x*State_Sens; % Final Output sensitivity !

C.F_D_true = casadi.Function('F_sensitivity_true',{C.decision.vec.cas,C.dop_parameters.vec.cas},{D_true},{'decision','dop_parameters'},{'sensitivity'});


disp("done. "+sec2str(toc(sens_time)))