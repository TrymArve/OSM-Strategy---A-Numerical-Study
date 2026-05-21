# Output Sensitivity Modification (OSM) Strategy — A Numerical Study

This repository contains the MATLAB code and saved simulation data used for a numerical study of the **Output Sensitivity Modification (OSM)** strategy for dynamic optimization and nonlinear model predictive control (NMPC).

The OSM strategy allows a dynamic optimization problem to be solved with a preferred input-output sensitivity structure. In this study, the method is used to impose a decoupling preference in an NMPC controller for an exothermic Continuous Stirred Tank Reactor (CSTR), while still evaluating feasibility and performance with respect to the true nonlinear model.

The repository accompanies a paper on OSM-NMPC and provides code for reproducing and exploring the numerical results.

## Purpose of the study

The study demonstrates and compares:

- implementation of the OSM strategy in dynamic optimization,
- open-loop OSM solutions,
- closed-loop OSM-NMPC behavior,
- real-time applicability,
- solver iteration counts,
- solve times,
- warm-start behavior,
- comparison against cost-function tuning strategies,
- comparison against a linear-penalty formulation,
- the ability of OSM-NMPC to impose a preferred decoupling structure without modifying the plant model.

The code is intended both for reproducing the paper results and for enabling readers to modify the examples, test alternative sensitivity modifications, and compare OSM against other NMPC tuning strategies.

## Results
### Example:
<p align="center">
  <img src="./Open-Loop Solutions - Case 2.png" alt="Open-loop comparison of NMPC methods" width="750">
</p>
The figure shows the open-loop solutions of the compared NMPC formulations for the CSTR case study.

Colors: 

- GREEN - Classic NMPC
- YELLOW - OSM-stretegy
- RED - Aggressive NMPC tuning (quadratic only)
- BLUE - Linear Term

## Conclusion

The aggressive tuning is able to approximate the solution of the OSM-strategy, and
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
simply increasing its weight. In the general decoupling case, it is simple
to penalize the particular coupling, and not penalize usage of those
inputs in other couplings. Moreover, the preferred structure may not be
that of a decoupling scheme, and in general, a cost-function-shaping/tuning
strategy is even less applicable.

The linear term also achieves a decoupling effect, but suffers all the same
caveats as the aggressive tuning strategy; hard to tune, poor numerics, and
not applicable in the general case.

Overall, the OSM strategy offers a simpler approach to decoupling when, when
meticulous tuning would otherwise be applicable, and extends the decoupling
capabilities of NMPC beyond simple examples, where tuning no longer suffices.
In addition, the OSM strategy allows structural preferences beyond that of
decoupling schemes. 

In our implementation, the OSM strategy is real-time applicable, as it consistently solves conscutive, warm-started problems in well under 100ms, and our case study uses a sampling time of 2s.
Further research should include a study of how the solve times scale with system complexity.



## Requirements

The code was developed and tested with:

- MATLAB R2024a  
  Version: `24.1.0.2537033 (R2024a)`
- CasADi for MATLAB  
  Version: `3.5.5`
- MATLAB Optimization Toolbox  
  Used for `quadprog` and warm-started QP solves.

Before running the scripts, make sure CasADi is available on the MATLAB path.

Example:

```matlab
addpath('path/to/casadi')
addpath(genpath(pwd))
```

Ensure all files are available on the MATLAB path.

## Reproducibility information

The included simulation data was generated on the following system:

- **Processor:** 11th Gen Intel(R) Core(TM) i7-11850H @ 2.50 GHz
- **RAM:** 32.0 GB
- **System type:** 64-bit operating system, x64-based processor
- **Operating system:** Windows 11 Education, version 25H2

Solve times are hardware- and software-dependent. The included timing results should therefore be interpreted as representative for this setup, not as machine-independent benchmark values.

## The numerical study

### Model

The example is an exothermic, nonisothermal CSTR with one irreversible first-order reaction,

```math
A \rightarrow B.
```

The states are

```math
x = [C_A, T]^\top,
```

where

- `C_A` is the concentration of reactant A,
- `T` is the reactor temperature.

The manipulated inputs are

```math
u = [q, T_c]^\top,
```

where

- `q` is the inlet volumetric flow rate,
- `T_c` is the coolant/jacket temperature.

The controlled output used in the sensitivity modification is

```math
y = T.
```

The CSTR model is defined in:

```text
make_model.m
```

The q-split model used for the linear-penalty comparison is defined in:

```text
make_model_splitq.m
```

### Control problem

The controller regulates the system to a nominal high-temperature steady state. The study uses a quadratic stage cost on output deviation and input deviation, together with state/input constraints.

Important constraints include:

- lower bound on coolant temperature,
- upper bound on reactor temperature,
- lower bound on concentration,
- additional nonnegativity bounds on `q_plus` and `q_minus` in the q-split formulation.

The nominal setup, bounds, weights, horizon length, simulation time, and initial conditions are defined mainly in:

```text
Set_Up.m
Set_Up_splitq.m
general_settings.m
```

The finite-horizon dynamic optimization problem is created in:

```text
make_dop.m
```

### Sensitivity modification

The OSM case modifies the input-output sensitivity matrix so that the controller does not perceive the sensitivity from inlet flow rate `q` to tank temperature `T_tank` in the objective-gradient calculation.

In other words, the intended structural preference is:

```math
\frac{\partial T_i}{\partial q_j} = 0
```

for the relevant predicted output and input samples.

This modification is implemented in:

```text
make_sensitivity.m
modify_sensitivity.m
make_halting_vector.m
```

The purpose is to encourage the controller to use `T_c` as the primary input for temperature regulation, while still allowing the true nonlinear model and constraints to determine feasibility.

## Compared methods

The repository compares four main controller formulations.

| Method | Script | Description |
|---|---|---|
| Classic NMPC | `ClassicNMPC.m` | Standard NMPC with the nominal quadratic objective. |
| OSM-NMPC | `osmNMPC.m` | NMPC based on the OSM halting conditions with modified input-output sensitivity. |
| Aggressive tuning | `aggressiveNMPC.m` | Cost-function tuning baseline where the penalty on `q` is increased to discourage use of inlet flow. |
| Linear-term tuning | `linear_termNMPC_splitq.m` | q-split formulation with a linear penalty on deviations in the inlet flow direction. |

The OSM method changes the stationarity/gradient information used to define the solution, while the aggressive and linear-term methods try to obtain similar behavior by changing the cost function.

## Open-loop and closed-loop experiments

The study includes both open-loop and closed-loop simulations.

### Open-loop solutions

Open-loop solutions are computed for selected initial conditions and compared across the methods. These results show how each formulation chooses an input trajectory over the prediction horizon.

### Closed-loop simulations

Closed-loop simulations apply the first input from each solve, simulate the plant forward, then resolve the optimization problem at the next sampling instant.

The closed-loop study is used to compare:

- controller behavior,
- temperature regulation,
- use of inlet flow `q`,
- use of coolant temperature `T_c`,
- constraint handling,
- iteration counts,
- solve times,
- warm-startability.

## Initial-condition cases

Two cases are included.

```matlab
Case = "case_1";
Case = "case_2";
```

The cases are defined in `general_settings.m`.

- `case_1` primarily illustrates the decoupling effect.
- `case_2` illustrates behavior closer to an active-constraint situation, where feasibility may require use of the otherwise discouraged coupling.

## How to reproduce the included plots

To load the saved results and reproduce the analysis plots, run:

```matlab
Main_analysis
```

This script loads the included `.mat` files, plots the open-loop and closed-loop trajectories, and prints average warm-started iteration counts and solve times for the closed-loop simulations.

The saved result files follow the naming pattern:

```text
shw_open_<method>_<case>.mat
shw_closed_<method>_<case>.mat
```

For example:

```text
shw_open_osm_case_2.mat
shw_closed_osm_case_2.mat
```

## How to regenerate the results

To regenerate the numerical results, run:

```matlab
Main_generate_results
```

By default, the script is set to:

```matlab
Case = "case_2";
save_result = false;
```

To overwrite or create saved result files, set:

```matlab
save_result = true;
```

To generate results for another initial condition, change:

```matlab
Case = "case_1";
```

or

```matlab
Case = "case_2";
```

inside `Main_generate_results.m`.

## Repository structure

Important files include:

| File | Purpose |
|---|---|
| `Main_analysis.m` | Loads included results, plots trajectories, and reports iteration/solve-time summaries. |
| `Main_generate_results.m` | Regenerates open-loop and closed-loop results. |
| `Set_Up.m` | Sets up the nominal CSTR model, parameters, bounds, discretization, objective weights, plotting, and solver settings. |
| `Set_Up_splitq.m` | Sets up the q-split model used for the linear-term comparison. |
| `make_model.m` | Defines the CSTR model with inputs `q` and `T_c`. |
| `make_model_splitq.m` | Defines the q-split model with inputs `q_plus`, `q_minus`, and `T_c`. |
| `make_dop.m` | Builds the dynamic optimization problem. |
| `make_quadratic_objective.m` | Builds the nominal quadratic objective. |
| `make_sensitivity.m` | Constructs the true input-output sensitivity matrix. |
| `modify_sensitivity.m` | Applies the OSM sensitivity mask. |
| `make_halting_vector.m` | Constructs the OSM halting residual. |
| `solve_SQP.m` | Solves the standard SQP formulation. |
| `solve_FB.m` | Solves the OSM/Fischer-Burmeister halting formulation. |
| `simulate.m` | Performs closed-loop simulation. |
| `show_results.m` | Plots state and input trajectories. |
| `show_solves.m` | Plots iteration counts and solve times. |
| `solver_settings.m` | Defines tolerances, QP options, warm-start options, and SQP iteration limits. |

## Modifying the experiments

Some useful entry points for further experimentation are listed below.

### Change the sensitivity modification

Edit:

```text
modify_sensitivity.m
```

For example, to modify a different input-output channel, change the block mask:

```matlab
Blk_Mask(model.ind.outpu.T_tank, model.ind.input.q) = 0;
```

### Change the initial condition

Edit:

```text
general_settings.m
```

The two current cases are defined by perturbing the nominal steady state.

### Change objective weights

Edit the manual tuning section in:

```text
Set_Up.m
```

or

```text
Set_Up_splitq.m
```

For example:

```matlab
base_weights.input("q")      = base_weights.input("q") * 1;
base_weights.input("T_c")    = base_weights.input("T_c") * 10;
base_weights.outpu("T_tank") = base_weights.outpu("T_tank") * 100;
```

### Change solver settings

Edit:

```text
solver_settings.m
```

This file contains KKT tolerances, QP tolerances, warm-start settings, and the maximum number of SQP iterations.

### Change discretization

Edit the discretization section in:

```text
Set_Up.m
```

or

```text
Set_Up_splitq.m
```

The current setup uses explicit RK4 for both prediction and simulation, with a more accurate RK4 setup for plant simulation.

## Notes on interpretation

The aggressive-tuning and linear-term formulations can sometimes produce behavior similar to OSM in this simple example. However, these approaches rely on cost-function tuning and are therefore problem-dependent.

The OSM strategy instead imposes the desired structural preference directly through the sensitivity information used in the stationarity conditions. This is important because many structural preferences are difficult or impossible to express accurately through scalar cost-function tuning alone.

A key point of the study is that OSM can discourage the controller from using a specified coupling for optimality, while still preserving feasibility with respect to the true nonlinear model when only the objective gradient is modified.

## Citation

If you use this code, please cite the associated paper once bibliographic information is available.

Suggested placeholder:

```bibtex
@misc{gabrielsen2026osm,
  title  = {Output Sensitivity Modification for Nonlinear Model Predictive Control},
  author = {Gabrielsen, Trym Arve Lund and Imsland, Lars Struen and Krishnamoorthy, Dinesh},
  year   = {2026},
  note   = {Code repository: OSM-Strategy---A-Numerical-Study}
}
```

## License

No license information is specified here. Add a license file if the repository is intended for public reuse, modification, or redistribution.
