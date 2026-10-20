$Title poultry foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_poultry  'poultry production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_production_set.inc"
/;

set j_poultry  'poultry demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_demand_set.inc"
/;

Parameter
   emi_Poultry(i_poultry)   'Emission intensity at production site'
   poultry_production(i_poultry) 'Production capacity at each site'
   poultry_demand(j_poultry)     'Demand at each market'
   emi_total(i_poultry)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_Poultry.gdx', emi_Poultry;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_production.gdx', poultry_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/halfEAT_poultry_demand.gdx', poultry_demand;

emi_total(i_poultry) = emi_Poultry(i_poultry);

Variable
   x(i_poultry,j_poultry)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_poultry)  'Supply capacity constraint'
   demand(j_poultry)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_poultry)..
   sum(j_poultry, x(i_poultry,j_poultry)) =l= poultry_production(i_poultry);

demand(j_poultry)..
   sum(i_poultry, x(i_poultry,j_poultry)) =e= poultry_demand(j_poultry);

emission_obj..
   total_emission =e= sum((i_poultry,j_poultry),
                           x(i_poultry,j_poultry) * emi_total(i_poultry));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_halfEAT_poultry_countrylevel.gdx";
