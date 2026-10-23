$Title cereal foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_cereal  'cereal production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_production_set.inc"
/;

set j_cereal  'cereal demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_demand_set.inc"
/;

Parameter
   emi_cereal(i_cereal)   'Emission intensity at production site'
   cereal_production(i_cereal) 'Production capacity at each site'
   cereal_demand(j_cereal)     'Demand at each market'
   emi_total(i_cereal)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_cereal.gdx', emi_cereal;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_production.gdx', cereal_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bau_cereal_demand.gdx', cereal_demand;

emi_total(i_cereal) = emi_cereal(i_cereal);

Variable
   x(i_cereal,j_cereal)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_cereal)  'Supply capacity constraint'
   demand(j_cereal)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_cereal)..
   sum(j_cereal, x(i_cereal,j_cereal)) =l= cereal_production(i_cereal);

demand(j_cereal)..
   sum(i_cereal, x(i_cereal,j_cereal)) =e= cereal_demand(j_cereal);

emission_obj..
   total_emission =e= sum((i_cereal,j_cereal),
                           x(i_cereal,j_cereal) * emi_total(i_cereal));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_bau_cereal_countrylevel.gdx";
