$Title eggs foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_eggs  'eggs production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production_set.inc"
/;

set j_eggs  'eggs demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   eggs_production(i_eggs) 'Production capacity at each site'
   eggs_demand_halfeat(j_eggs)     'Demand at each market'
   distances(i_eggs,j_eggs) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production.gdx', eggs_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_halfeat.gdx', eggs_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_eggs,j_eggs)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_eggs)  'Supply capacity constraint'
   demand(j_eggs)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_eggs)..
   sum(j_eggs, x(i_eggs,j_eggs)) =l= eggs_production(i_eggs);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_eggs)..
   sum(i_eggs, x(i_eggs,j_eggs)) =e= eggs_demand_halfeat(j_eggs);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_eggs,j_eggs), distances(i_eggs,j_eggs)*x(i_eggs,j_eggs));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/eggs_halfeat_minfoodmiles.gdx";
