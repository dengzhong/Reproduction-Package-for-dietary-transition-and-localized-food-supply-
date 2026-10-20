$Title Bovine foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_Bovine  'Bovine production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_production_set.inc"
/;

set j_Bovine  'Bovine demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   Bovine_production(i_Bovine) 'Production capacity at each site'
   Bovine_demand_halfeat(j_Bovine)     'Demand at each market'
   distances(i_Bovine,j_Bovine) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_production.gdx', Bovine_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_demand_halfeat.gdx', Bovine_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_Bovine,j_Bovine)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_Bovine)  'Supply capacity constraint'
   demand(j_Bovine)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_Bovine)..
   sum(j_Bovine, x(i_Bovine,j_Bovine)) =l= Bovine_production(i_Bovine);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_Bovine)..
   sum(i_Bovine, x(i_Bovine,j_Bovine)) =e= Bovine_demand_halfeat(j_Bovine);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_Bovine,j_Bovine), distances(i_Bovine,j_Bovine)*x(i_Bovine,j_Bovine));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/Bovine_halfeat_minfoodmiles.gdx";
