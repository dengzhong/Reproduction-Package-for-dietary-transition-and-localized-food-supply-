$Title fruit foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_fruit  'fruit production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_production_set.inc"
/;

set j_fruit  'fruit demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   fruit_production(i_fruit) 'Production capacity at each site'
   fruit_demand_halfeat(j_fruit)     'Demand at each market'
   distances(i_fruit,j_fruit) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_production.gdx', fruit_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_demand_halfeat.gdx', fruit_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_fruit,j_fruit)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_fruit)  'Supply capacity constraint'
   demand(j_fruit)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_fruit)..
   sum(j_fruit, x(i_fruit,j_fruit)) =l= fruit_production(i_fruit);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_fruit)..
   sum(i_fruit, x(i_fruit,j_fruit)) =e= fruit_demand_halfeat(j_fruit);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_fruit,j_fruit), distances(i_fruit,j_fruit)*x(i_fruit,j_fruit));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/fruit_halfeat_minfoodmiles.gdx";
