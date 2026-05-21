% Store with output variables:
C.objective.output.expr = obj;
C.objective.output.F    = casadi.Function(idstring('F_objective_output'),{C.longshot.input.vars,C.longshot.outpu.vars},{obj},{'longshot_output_vars','longshot_input_vars'},{'objective'}); %#ok<*MCSUP>

% Make expression of decision variables:
C.objective.decision.expr = C.objective.output.F(C.longshot.input.vars,C.longshot.outpu.expr);
C.objective.decision.F    = casadi.Function(idstring('F_objective_decision'),{C.decision.vec.cas,C.dop_parameters.vec.cas},{C.objective.decision.expr},{'decision','opt_par_vec'},{'objective'});
