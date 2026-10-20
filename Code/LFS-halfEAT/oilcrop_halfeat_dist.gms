$Title oilcrop foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

*===========================================================
* BASIC SETTINGS
*===========================================================
Option LP = Cplex;
option Threads = 0;

*===========================================================
* SETS
*===========================================================
set i_oilcrop  'oilcrop production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_production_set.inc"
/;

set j_oilcrop  'oilcrop demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_demand_eat_set.inc"
/;

*===========================================================
* PARAMETERS
*===========================================================
Parameter
   oilcrop_production(i_oilcrop) 'Production capacity at each site'
   oilcrop_demand_halfeat(j_oilcrop)     'Demand at each market'
   distances(i_oilcrop,j_oilcrop) 'distance in kilometer';

* Load data from external GDX files
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_production.gdx', oilcrop_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_demand_halfeat.gdx', oilcrop_demand_halfeat;

*===========================================================
* VARIABLES
*===========================================================
Variable
   x(i_oilcrop,j_oilcrop)   'Shipment quantity from i to j'
   z                        'total transportation disttance in kilometer';

Positive Variable x;

*===========================================================
* EQUATIONS
*===========================================================
Equation
   d         'define objective function'
   supply(i_oilcrop)  'Supply capacity constraint'
   demand(j_oilcrop)  'Demand satisfaction constraint';

*-----------------------------------------------------------
* Supply constraint: total shipments from i cannot exceed capacity
*-----------------------------------------------------------
supply(i_oilcrop)..
   sum(j_oilcrop, x(i_oilcrop,j_oilcrop)) =l= oilcrop_production(i_oilcrop);

*-----------------------------------------------------------
* Demand constraint: demand at j must be fully satisfied
*-----------------------------------------------------------
demand(j_oilcrop)..
   sum(i_oilcrop, x(i_oilcrop,j_oilcrop)) =e= oilcrop_demand_halfeat(j_oilcrop);

*-----------------------------------------------------------
* Objective: minimize total food miles
*-----------------------------------------------------------
d..         z =e= sum((i_oilcrop,j_oilcrop), distances(i_oilcrop,j_oilcrop)*x(i_oilcrop,j_oilcrop));

*===========================================================
* LFS-halfEAT — MINIMIZE TOTAL FOOD MILES
*===========================================================
Model transport_emission /d, supply, demand/;
solve transport_emission using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/oilcrop_halfeat_minfoodmiles.gdx";
