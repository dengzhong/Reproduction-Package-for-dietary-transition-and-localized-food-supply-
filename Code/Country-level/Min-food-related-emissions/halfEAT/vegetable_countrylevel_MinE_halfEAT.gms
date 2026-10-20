$Title vegetable foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_vegetable  'vegetable production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/vegetable_production_set.inc"
/;

set j_vegetable  'vegetable demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/vegetable_demand_set.inc"
/;

Parameter
   emi_vegetable(i_vegetable)   'Emission intensity at production site'
   vegetable_production(i_vegetable) 'Production capacity at each site'
   vegetable_demand(j_vegetable)     'Demand at each market'
   emi_total(i_vegetable)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_vegetable.gdx', emi_vegetable;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/vegetable_production.gdx', vegetable_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/halfEAT_vegetable_demand.gdx', vegetable_demand;

emi_total(i_vegetable) = emi_vegetable(i_vegetable);

Variable
   x(i_vegetable,j_vegetable)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_vegetable)  'Supply capacity constraint'
   demand(j_vegetable)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_vegetable)..
   sum(j_vegetable, x(i_vegetable,j_vegetable)) =l= vegetable_production(i_vegetable);

demand(j_vegetable)..
   sum(i_vegetable, x(i_vegetable,j_vegetable)) =e= vegetable_demand(j_vegetable);

emission_obj..
   total_emission =e= sum((i_vegetable,j_vegetable),
                           x(i_vegetable,j_vegetable) * emi_total(i_vegetable));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_halfEAT_vegetable_countrylevel.gdx";
