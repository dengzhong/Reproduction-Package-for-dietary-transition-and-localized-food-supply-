$Title Bovine foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_Bovine  'Bovine production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_production_set.inc"
/;

set j_Bovine  'Bovine demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_demand_set.inc"
/;

Parameter
   emi_Bovine(i_Bovine)   'Emission intensity at production site'
   Bovine_production(i_Bovine) 'Production capacity at each site'
   Bovine_demand(j_Bovine)     'Demand at each market'
   emi_total(i_Bovine)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_Bovine.gdx', emi_Bovine;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_production.gdx', Bovine_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/halfEAT_Bovine_demand.gdx', Bovine_demand;

emi_total(i_Bovine) = emi_Bovine(i_Bovine);

Variable
   x(i_Bovine,j_Bovine)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_Bovine)  'Supply capacity constraint'
   demand(j_Bovine)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_Bovine)..
   sum(j_Bovine, x(i_Bovine,j_Bovine)) =l= Bovine_production(i_Bovine);

demand(j_Bovine)..
   sum(i_Bovine, x(i_Bovine,j_Bovine)) =e= Bovine_demand(j_Bovine);

emission_obj..
   total_emission =e= sum((i_Bovine,j_Bovine),
                           x(i_Bovine,j_Bovine) * emi_total(i_Bovine));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_halfEAT_Bovine_countrylevel.gdx";
