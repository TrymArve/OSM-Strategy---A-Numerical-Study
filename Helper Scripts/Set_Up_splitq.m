


%%% ---------------------------------- Define Model

make_model_splitq % make the q-split model

% Set parameters:
model.parameters = dictionary(model.names.param,zeros(1,model.dim.param));
model.parameters("V")      = 100.0;          % [L]
model.parameters("rho")    = 1.0;            % [kg/L]      (1000 g/L)
model.parameters("Cp")     = 0.239;          % [kJ/(kg*K)] (0.239 J/g/K)
model.parameters("UA")     = 50/60;          % [kJ/(s*K)]  (50,000 J/min/K)
model.parameters("C_Af")   = 1.0;            % [mol/L]
model.parameters("T_f")    = 295.0;          % [K]
model.parameters("k0")     = 7.2e10/60;      % [1/s]       (originally 1/min)
model.parameters("E")      = 8750.0;         % [K]         (E_a/R)
model.parameters("DeltaH") = -50.0;          % [kJ/mol]    (-50,000 J/mol)
model.parameters("q_ref")  = 1.5;            % [L/s]       (reference value for q)



%%% ---------------------------------- DEFINE OPERATNING POINT / REFERENCE

ref = struct;
ref.T = 360; % [K] reference temperature for tank reaction temperature
ref.q = model.parameters("q_ref"); % [L/s] reference input volumetric flow rate
ref.parameters = model.parameters.values;

ref = model.steady(ref);
ref.outpu = model.y(ref.state,ref.input,model.parameters.values);





%%% ------------------------------------------- DISCRETIZE DYNAMICS:

%%%% Choose either of many integrators (play around!):

% Explicit Euler Integrator:
% disc = discretize_dynamics("f", model.f, ...
%                            "method", "Explicit Euler", ...
%                            "n_increments", 5);

% More accurate Explicit RK4 integrator:
disc = discretize_dynamics("f", model.f, ...
                           "method", "ERK4", ...
                           "n_increments", 1);

% Gauss-Legandre Collocation Integrator:
% disc = discretize_dynamics("f", model.f, ...
%                            "method", "Gauss-Legendre (6. order)", ...
%                            "n_increments", 2);

% Other implicit iterators ?
% disc = discretize_dynamics("f", model.f, ...
%                            "method", "custom collocation", ...
%                            "n_increments", 2,...
%                            "collocation_polynomial_order",2,...
%                            "collocation_polynomial_type","radau");




%%% ----------------------------------------- SIMULATION SETTINGS:


%%%% Very accurate Explicit RK4 integrator for simulation:
sim.disc = discretize_dynamics("f", model.f, ...
                           "method", "ERK4", ...
                           "n_increments", 10);






%%% ------------------------------------------- DYNAMIC OPTIMIZAITON PROBLEM

general_settings


%%%%%% Variable Bounds
bounds = configureDictionary("string","cell");
bounds("T_c")      = {[315, inf]};   % [K]    coolant temperature
bounds("T_tank")   = {[300, 361]};   % [K]    reactor temperature
bounds("C_A")      = {[0,inf]};
bounds("q_plus")   = {[0,inf]};
bounds("q_minus")  = {[0,inf]};

make_dop % create the dynamic optimization problem



% Manual tuning
base_weights.input("q_plus")    = base_weights.input("q_plus")  *1;
base_weights.input("q_minus")   = base_weights.input("q_minus") *1;
base_weights.input("T_c")       = base_weights.input("T_c")     *10;
base_weights.outpu("T_tank")    = base_weights.outpu("T_tank")  *100;








%%% ------------------ PREPARE PLOTTING
prepare_plotting

%%% ----------------------------------------- SOLVER SETTINGS:

solver_settings