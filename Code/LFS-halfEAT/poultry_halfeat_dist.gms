$Title poultry foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_poultry  'poultry production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_production_set.inc"
/;

set j_poultry  'poultry demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   poultry_production(i_poultry) 'Production capacity at each site'
   poultry_demand_halfeat(j_poultry)     'Demand at each market'
   distances(i_poultry,j_poultry) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_production.gdx', poultry_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_demand_halfeat.gdx', poultry_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_poultry,j_poultry)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_poultry)  'Supply capacity constraint'
   demand(j_poultry)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_poultry)..
   sum(j_poultry, x(i_poultry,j_poultry)) =l= poultry_production(i_poultry);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_poultry)..
   sum(i_poultry, x(i_poultry,j_poultry)) =e= poultry_demand_halfeat(j_poultry);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_poultry,j_poultry), distances(i_poultry,j_poultry)*x(i_poultry,j_poultry));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/poultry_halfeat_minfoodmiles.gdx";
