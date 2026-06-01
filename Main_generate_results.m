
clc; clear; close all;
Set_Up

% Choose what to do:
Case = "case_2";          % which initial conditions?
save_result = false;

%%%%% -------------- OPEN LOOP SOLUTIONS:


%% Classic OL

loop = "open";
ClassicNMPC
show_results

%% OSM OL

loop = "open";
osmNMPC
show_results


%% Aggressive OL

loop = "open";
aggressiveNMPC
aggressive2NMPC
show_results


%%%%% -------------- CLOSED LOOP SIMULATIONS:

%% Classic CL

loop = "closed";
ClassicNMPC
show_results

%% OSM CL

loop = "closed";
osmNMPC
show_results

%% Aggressive CL

loop = "closed";
aggressiveNMPC
aggressive2NMPC
show_results

%% For Linear-penalty formulation:
clc; clear; close all;
Set_Up_splitq

% Choose what to do:
Case = "case_2";          % which initial conditions?
save_result = false;

% Linear Term OL (q-split)
loop = "open";
linear_termNMPC_splitq
show_results

% Linear Term CL (q-split)
loop = "closed";
linear_termNMPC_splitq
show_results







%%
%%% Print:
disp("Stats for "+method+":")
fprintf("  %-14s -> %8.4f iterations\n", method, mean(show.(loop)(method).traj.iterations(2:end)))
fprintf("  %-14s -> %8.4f ms\n", method, mean(show.(loop)(method).traj.solve_times(2:end))*1000)


