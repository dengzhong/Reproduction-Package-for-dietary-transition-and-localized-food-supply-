$Title pig foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_pig  'pig production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_production_set.inc"
/;

set j_pig  'pig demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_demand_eat_set.inc"
/;

Parameter
   emi_Pork(i_pig)   'Emission intensity at production site'
   pig_production(i_pig) 'Production capacity at each site'
   pig_demand_halfeat(j_pig)     'Demand at each market'
   emi_total(i_pig)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/emi_Pork.gdx', emi_Pork;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_production.gdx', pig_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/pig_demand_halfeat.gdx', pig_demand_halfeat;

emi_total(i_pig) = emi_Pork(i_pig);

Variable
   x(i_pig,j_pig)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_pig)  'Supply capacity constraint'
   demand(j_pig)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_pig)..
   sum(j_pig, x(i_pig,j_pig)) =l= pig_production(i_pig);

demand(j_pig)..
   sum(i_pig, x(i_pig,j_pig)) =e= pig_demand_halfeat(j_pig);

emission_obj..
   total_emission =e= sum((i_pig,j_pig),
                           x(i_pig,j_pig) * emi_total(i_pig));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/pig_halfeat_minEmission.gdx";
