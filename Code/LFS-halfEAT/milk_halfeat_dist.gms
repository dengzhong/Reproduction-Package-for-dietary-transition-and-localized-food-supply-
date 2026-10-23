$Title milk foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_milk  'milk production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production_set.inc"
/;

set j_milk  'milk demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   milk_production(i_milk) 'Production capacity at each site'
   milk_demand_halfeat(j_milk)     'Demand at each market'
   distances(i_milk,j_milk) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production.gdx', milk_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand_halfeat.gdx', milk_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_milk,j_milk)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_milk)  'Supply capacity constraint'
   demand(j_milk)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_milk)..
   sum(j_milk, x(i_milk,j_milk)) =l= milk_production(i_milk);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_milk)..
   sum(i_milk, x(i_milk,j_milk)) =e= milk_demand_halfeat(j_milk);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_milk,j_milk), distances(i_milk,j_milk)*x(i_milk,j_milk));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/milk_halfeat_minfoodmiles.gdx";
