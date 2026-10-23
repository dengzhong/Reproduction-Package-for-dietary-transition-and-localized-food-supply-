$Title eggs foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_eggs  'eggs production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production_set.inc"
/;

set j_eggs  'eggs demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_eat_set.inc"
/;

Parameter
   emi_Eggs(i_eggs)   'Emission intensity at production site'
   eggs_production(i_eggs) 'Production capacity at each site'
   eggs_demand_eat(j_eggs)     'Demand at each market'
   emi_total(i_eggs)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/emi_Eggs.gdx', emi_Eggs;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production.gdx', eggs_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_eat.gdx', eggs_demand_eat;

emi_total(i_eggs) = emi_Eggs(i_eggs);

Variable
   x(i_eggs,j_eggs)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_eggs)  'Supply capacity constraint'
   demand(j_eggs)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_eggs)..
   sum(j_eggs, x(i_eggs,j_eggs)) =l= eggs_production(i_eggs);

demand(j_eggs)..
   sum(i_eggs, x(i_eggs,j_eggs)) =e= eggs_demand_eat(j_eggs);

emission_obj..
   total_emission =e= sum((i_eggs,j_eggs),
                           x(i_eggs,j_eggs) * emi_total(i_eggs));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/eggs_eat_minEmission.gdx";
