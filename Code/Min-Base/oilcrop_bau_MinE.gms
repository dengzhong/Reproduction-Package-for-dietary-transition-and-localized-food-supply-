$Title oilcrop foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_oilcrop  'oilcrop production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_production_set.inc"
/;

set j_oilcrop  'oilcrop demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_demand_set.inc"
/;

Parameter
   emi_oilcrop(i_oilcrop)   'Emission intensity at production site'
   oilcrop_production(i_oilcrop) 'Production capacity at each site'
   oilcrop_demand(j_oilcrop)     'Demand at each market'
   emi_total(i_oilcrop)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/emi_oilcrop.gdx', emi_oilcrop;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_production.gdx', oilcrop_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/oilcrop_demand.gdx', oilcrop_demand;

emi_total(i_oilcrop) = emi_oilcrop(i_oilcrop);

Variable
   x(i_oilcrop,j_oilcrop)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_oilcrop)  'Supply capacity constraint'
   demand(j_oilcrop)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_oilcrop)..
   sum(j_oilcrop, x(i_oilcrop,j_oilcrop)) =l= oilcrop_production(i_oilcrop);

demand(j_oilcrop)..
   sum(i_oilcrop, x(i_oilcrop,j_oilcrop)) =e= oilcrop_demand(j_oilcrop);

emission_obj..
   total_emission =e= sum((i_oilcrop,j_oilcrop),
                           x(i_oilcrop,j_oilcrop) * emi_total(i_oilcrop));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/oilcrop_minEmission.gdx";
