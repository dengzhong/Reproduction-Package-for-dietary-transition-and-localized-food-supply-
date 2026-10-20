$Title cereal foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_cereal  'cereal production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/cereal_production_set.inc"
/;

set j_cereal  'cereal demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/cereal_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   cereal_production(i_cereal) 'Production capacity at each site'
   cereal_demand_halfeat(j_cereal)     'Demand at each market'
   distances(i_cereal,j_cereal) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/cereal_production.gdx', cereal_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/cereal_demand_halfeat.gdx', cereal_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_cereal,j_cereal)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_cereal)  'Supply capacity constraint'
   demand(j_cereal)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_cereal)..
   sum(j_cereal, x(i_cereal,j_cereal)) =l= cereal_production(i_cereal);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_cereal)..
   sum(i_cereal, x(i_cereal,j_cereal)) =e= cereal_demand_halfeat(j_cereal);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_cereal,j_cereal), distances(i_cereal,j_cereal)*x(i_cereal,j_cereal));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/cereal_halfeat_minfoodmiles.gdx";
