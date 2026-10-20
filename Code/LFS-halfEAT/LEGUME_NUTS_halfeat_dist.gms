$Title legume_nuts foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_legume_nuts  'legume_nuts production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_production_set.inc"
/;

set j_legume_nuts  'legume_nuts demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   legume_nuts_production(i_legume_nuts) 'Production capacity at each site'
   legume_nuts_demand_halfeat(j_legume_nuts)     'Demand at each market'
   distances(i_legume_nuts,j_legume_nuts) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_production.gdx', legume_nuts_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_demand_halfeat.gdx', legume_nuts_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_legume_nuts,j_legume_nuts)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_legume_nuts)  'Supply capacity constraint'
   demand(j_legume_nuts)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_legume_nuts)..
   sum(j_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =l= legume_nuts_production(i_legume_nuts);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_legume_nuts)..
   sum(i_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =e= legume_nuts_demand_halfeat(j_legume_nuts);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_legume_nuts,j_legume_nuts), distances(i_legume_nuts,j_legume_nuts)*x(i_legume_nuts,j_legume_nuts));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/legume_nuts_halfeat_minfoodmiles.gdx";
