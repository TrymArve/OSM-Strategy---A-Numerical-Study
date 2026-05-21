names.state = ["C_A","T"];
names.input = ["q","T_c"];
names.param = [ ...
   "V",      ...  % reactor volume                   [L]
   "rho",    ...  % reactor liquid density           [kg/L]
   "Cp",     ...  % reactor heat capacity            [kJ/(kg*K)]
   "UA",     ...  % overall heat transfer UA         [kJ/(s*K)]
   "C_Af",   ...  % feed concentration               [mol/L]
   "T_f",    ...  % feed temperature                 [K]
   "k0",     ...  % Arrhenius pre-exponential        [1/s]
   "E",      ...  % activation energy / R            [K]
   "DeltaH"  ...  % heat of reaction (exothermic<0)  [kJ/mol]
];

model = struct; % Create struct that will hold our model stuff

model.names = names; % Attach names

%%% Create CasADi SX variables and add miscellanous information
for type = string(fieldnames(model.names))'
   model.cas.(type) = dictionary;
   model.dim.(type) = length(model.names.(type));
   for name = model.names.(type)
       cas_variable = casadi.SX.sym(char(name),1,1);
       model.cas.(type)(name) = cas_variable;
       model.ind.(type).(name) = model.cas.(type).numEntries;
      eval([char(name),' = cas_variable;'])
   end
end


%%% ---------------------------------------- DEFINE DYNAMICS

%%%%%% Auxiliary expressions:

% Arrhenius kinetics (E already scaled by R)
k = k0*exp(-E./T);      % [1/s]
r = k.*C_A;             % [mol/(L*s)]  reaction rate per volume



%%%%%% Dynamics:

% Species balance:
dC_A = q/V*(C_Af - C_A) - r;

% Reactor energy balance (Seborg/Kantor form):
% dT/dt = q/V (T_f - T) + (-DeltaH/(rho Cp))*r + UA/(V rho Cp)(T_c - T)
dT = q/V*(T_f - T) ...
     + (-DeltaH/(rho*Cp))*r ...           % reaction heat (DeltaH<0 for exothermic)
     + (UA/(V*rho*Cp))*(T_c - T);         % cooling / heating via jacket

% Dynamics:
f = [dC_A; dT];

% Create CasADi Function:
model.f = casadi.Function(idstring('F_Dynamics'),{model.cas.state.values,model.cas.input.values,model.cas.param.values},{f},{'state','input','parameters'},{'dstate'});


%%% ------------------------------------------- STEADY STATE DESIGN
 
%{
We parameterize steady states by:
   -  Tss -> desired reactor temperature                 (state)
   -  qss -> flow rate of ractant into tank              (input)

and compute the corresponding steady state values of
   - C_Ass  -> steady state concentration of chemical A  (state)
   - T_c,ss -> steady state cooling temperature          (input)
%}

%%%%%% We shall choose values for:
Tss = model.cas.state("T");
qss = model.cas.input("q");

% Append arguments to struct
eq.T = Tss;
eq.q = qss;
eq.parameters = model.cas.param.values;

%%%%% Steady State Equations:

% Kinetics at Tss:
k_ss = k0*exp(-E./Tss);

% Concentration steady-state:
%{
0 = q/V (C_Af - C_A) - k C_A 
-> C_Ass = (q/V C_Af)/(q/V + k_ss)
%}
CA_ss = (qss/V*C_Af) ./ (qss/V + k_ss);
r_ss  = k_ss.*CA_ss;

% From dT/dt = 0:
%{
 0 = q/V (T_f - Tss) + (-DeltaH/(rho Cp))*r_ss + UA/(V rho Cp)(T_c,ss - Tss)   
 =>  T_c,ss = Tss - (V rho Cp / UA) [ q/V (T_f - Tss) + (-DeltaH/(rho Cp))*r_ss ]
%}
T_c_ss = Tss - (V*rho*Cp/UA) .* ( qss/V*(T_f - Tss) + (-DeltaH/(rho*Cp))*r_ss );


%%%%% The reference 
eq.state = [CA_ss; Tss];
eq.input = [qss; T_c_ss];

F_steady = casadi.Function('F_steady_state_values', ...
                               eq,...
                               {'T','q','parameters'}, ...
                               {'state','input'});
model.steady = @(eq) full_struct(F_steady.call(eq));


%%% ------------------------------------------- DEFINE OUTPUT

model.cas.outpu = dictionary;

%%%% Define output names and expressions:
model.cas.outpu("T_tank") = T;


model.names.outpu = model.cas.outpu.keys;
i=0;
for name = model.names.outpu
   i=i+1;
   model.ind.outpu.(name) = i;
end
model.dim.outpu = numel(model.cas.outpu.numEntries);
F_y = casadi.Function('F_output',{model.cas.state.values,model.cas.input.values,model.cas.param.values},{model.cas.outpu.values},{'state','input','parameters'},{'output'});

Jy_u = jacobian(model.cas.outpu.values,model.cas.input.values);
Jy_x = jacobian(model.cas.outpu.values,model.cas.state.values);

F_Jy_u = casadi.Function('F_Jy_u',{model.cas.state.values,model.cas.input.values,model.cas.param.values},{Jy_u},{'state','input','parameters'},{'J_y_u'});
F_Jy_x = casadi.Function('F_Jy_x',{model.cas.state.values,model.cas.input.values,model.cas.param.values},{Jy_x},{'state','input','parameters'},{'J_y_x'});


model.y = @(state,input,param) full(F_y(state,input,param));



%%%% ----------------------------- STYLE

% Tank temp
model.style.state.T.unit    = "[K]";
model.style.state.T.label   = "$T$";

model.style.state.C_A.unit  = "[mol/L]";
model.style.state.C_A.label = "$C_{A}$";

model.style.input.q.unit   = "[L/s]";
model.style.input.q.label = "$q$";

model.style.input.T_c.unit = "[K]";
model.style.input.T_c.label = "$T_{c}$";