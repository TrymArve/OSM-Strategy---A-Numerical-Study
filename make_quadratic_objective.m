%%%%%%% Quadratic base-objective: (to be added onto depending on the method used%)
C.objective = [];
obj = [];
obj = casadi.SX.zeros;
obj = obj*0;

R = diag(weights.input.values);
Y = diag(weights.outpu.values);
for k = 1:N_horizon
   u_k = C.longshot.input.vars(:, k);
   y_k = C.longshot.outpu.vars(:, k);

   Du = u_k - ref.input;
   Dy = y_k - ref.outpu;

   obj = obj + Du.' * R * Du + Dy.' * Y * Dy;
end