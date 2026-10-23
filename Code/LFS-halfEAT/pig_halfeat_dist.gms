$Title pig foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_pig  'pig production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_production_set.inc"
/;

set j_pig  'pig demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   pig_production(i_pig) 'Production capacity at each site'
   pig_demand_halfeat(j_pig)     'Demand at each market'
   distances(i_pig,j_pig) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_production.gdx', pig_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_demand_halfeat.gdx', pig_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_pig,j_pig)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_pig)  'Supply capacity constraint'
   demand(j_pig)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_pig)..
   sum(j_pig, x(i_pig,j_pig)) =l= pig_production(i_pig);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_pig)..
   sum(i_pig, x(i_pig,j_pig)) =e= pig_demand_halfeat(j_pig);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_pig,j_pig), distances(i_pig,j_pig)*x(i_pig,j_pig));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/pig_halfeat_minfoodmiles.gdx";
