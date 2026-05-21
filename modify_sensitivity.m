
fprintf("Modifying sensitivity matrix ... "); mod_time = tic;

% % Make block mask matrix
no = model.dim.outpu;
ni = model.dim.input;

Blk_Mask = casadi.SX.ones(no,ni);
Blk_Mask(model.ind.outpu.T_tank,model.ind.input.q) = 0;



% Assemble full Mask matrix:
Ones = casadi.SX.ones(no,ni);
Full_Mask = casadi.SX([]);
for k = 1:H_horizon
   Column = [repmat(Ones,k-1,1) ;
             repmat(Blk_Mask,H_horizon,1)      ];

   Full_Mask = [Full_Mask Column(1:size(D_true,1),:)]; %#ok<AGROW>
end

D_modified = casadi.SX(D_true).*Full_Mask;

C.F_D_modified = casadi.Function('F_sensitivity_modified',{C.decision.vec.cas,C.dop_parameters.vec.cas},{D_modified},{'decision','dop_parameters'},{'sensitivity'});

disp("done. "+sec2str(toc(mod_time)))