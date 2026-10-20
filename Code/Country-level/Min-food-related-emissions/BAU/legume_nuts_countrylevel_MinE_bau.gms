$Title legume_nuts foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_legume_nuts  'legume_nuts production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/legume_nuts_production_set.inc"
/;

set j_legume_nuts  'legume_nuts demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/legume_nuts_demand_set.inc"
/;

Parameter
   emi_pulses(i_legume_nuts)   'Emission intensity at production site'
   legume_nuts_production(i_legume_nuts) 'Production capacity at each site'
   legume_nuts_demand(j_legume_nuts)     'Demand at each market'
   emi_total(i_legume_nuts)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_pulses.gdx', emi_pulses;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/legume_nuts_production.gdx', legume_nuts_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bau_legume_nuts_demand.gdx', legume_nuts_demand;

emi_total(i_legume_nuts) = emi_pulses(i_legume_nuts);

Variable
   x(i_legume_nuts,j_legume_nuts)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_legume_nuts)  'Supply capacity constraint'
   demand(j_legume_nuts)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_legume_nuts)..
   sum(j_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =l= legume_nuts_production(i_legume_nuts);

demand(j_legume_nuts)..
   sum(i_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =e= legume_nuts_demand(j_legume_nuts);

emission_obj..
   total_emission =e= sum((i_legume_nuts,j_legume_nuts),
                           x(i_legume_nuts,j_legume_nuts) * emi_total(i_legume_nuts));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_bau_legume_nuts_countrylevel.gdx";
