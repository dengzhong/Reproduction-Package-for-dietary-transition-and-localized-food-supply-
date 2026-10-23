$Title vegetable foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_vegetable  'vegetable production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_production_set.inc"
/;

set j_vegetable  'vegetable demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   vegetable_production(i_vegetable) 'Production capacity at each site'
   vegetable_demand_halfeat(j_vegetable)     'Demand at each market'
   distances(i_vegetable,j_vegetable) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_production.gdx', vegetable_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_demand_halfeat.gdx', vegetable_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_vegetable,j_vegetable)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_vegetable)  'Supply capacity constraint'
   demand(j_vegetable)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_vegetable)..
   sum(j_vegetable, x(i_vegetable,j_vegetable)) =l= vegetable_production(i_vegetable);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_vegetable)..
   sum(i_vegetable, x(i_vegetable,j_vegetable)) =e= vegetable_demand_halfeat(j_vegetable);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_vegetable,j_vegetable), distances(i_vegetable,j_vegetable)*x(i_vegetable,j_vegetable));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/vegetable_halfeat_minfoodmiles.gdx";
