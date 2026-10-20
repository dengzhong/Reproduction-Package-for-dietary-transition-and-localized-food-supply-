$Title fruit foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = CONOPT4;
option Threads = 0;

set i_fruit  'fruit production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/fruit_production_set.inc"
/;

set j_fruit  'fruit demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/fruit_demand_set.inc"
/;

Parameter
   emi_fruit(i_fruit)   'Emission intensity at production site'
   fruit_production(i_fruit) 'Production capacity at each site'
   fruit_demand(j_fruit)     'Demand at each market'
   emi_total(i_fruit)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/emi_fruit.gdx', emi_fruit;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/fruit_production.gdx', fruit_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_fruit_demand.gdx', fruit_demand;

emi_total(i_fruit) = emi_fruit(i_fruit);

Variable
   x(i_fruit,j_fruit)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_fruit)  'Supply capacity constraint'
   demand(j_fruit)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_fruit)..
   sum(j_fruit, x(i_fruit,j_fruit)) =l= fruit_production(i_fruit);

demand(j_fruit)..
   sum(i_fruit, x(i_fruit,j_fruit)) =e= fruit_demand(j_fruit);

emission_obj..
   total_emission =e= sum((i_fruit,j_fruit),
                           x(i_fruit,j_fruit) * emi_total(i_fruit));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/MinE_eat_fruit_countrylevel.gdx";
