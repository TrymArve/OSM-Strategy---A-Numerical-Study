

%% Analysis
clc; clear; close all;
Set_Up
iterations  = struct;
solve_times = struct;

Case = "case_1";

methods = ["classic","osm","aggressive","aggressive_2","linear_term"];
for loop = ["open", "closed"]
   for method = methods
      load("shw_"+loop+"_"+method+"_"+Case)
      show.(loop)(method).traj = shw.traj;
      if loop == "closed"
         iterations.(method) = shw.traj.iterations;
         solve_times.(method) = shw.traj.solve_times;
      end
   end
   show_results
end
show_solves

%%% Print:
fprintf("\nAverage number of iterations when warm started by previous solution:\n")
for method = methods
   fprintf("  %-14s -> %8.2f iterations\n", method, mean(iterations.(method)(2:end)))
   % first control signal is not warmstarted
end

fprintf("\nAverage solve time [ms] when warm started by previous solution:\n")
for method = methods
   fprintf("  %-14s -> %8.4f ms\n", method, mean(solve_times.(method)(2:end))*1000)
   % first control signal is not warmstarted
end





%%
%{

The aggressive tuning is able to produce the same solution as OSM, and
does so with similar efficiency as the OSM implementation. Though, achieving
this decopling effect with an aggressive controller requires careful
tuning. The tuning must be aggressive enough to approximate the OSM
solution well, and must not be so aggressive that the numerics become
poorly conditioned. In general, tuning the controller correctly can be a
complex, time consuming, and difficult process. In contrast, the OSM
strategy does not require tuning, as the sought behavior appears
automatically form the imposed structure. In fact, the OSM strategy can be
tuned to accomodate other preferenecs, while respecting the preferred structure.

Furthermore, note that the cost-function-shaping approah is only possible
for simple cases, such as our example, where a variable can be supressed by
simply increasing its weight. In the general decoupling case, it is not
obvious how to penalize the particular coupling, and not usage of those
inputs in other couplings. Moreover, the preferred strucutre may not be
that of a decoupling scheme, and in general, a cost-function-shaping/tuning
strategy is even less applicable.

The linear term also achieves a decoupling effect, but suffers all the same
caveats as the aggressive tuning strategy; hard to tune, poor numerics, and
not applicable in the general case.

Overall, the OSM strategy offers a simpler path to decoupling when, when
meticulous tuning would otherwise be applicable, and extend the decoupling
capabilities of MPC beyond simple examples, where tuning no longer suffices.
In addition, the OSM strategy allows structural preferences beyond that of
decoupling schemes. 


%}