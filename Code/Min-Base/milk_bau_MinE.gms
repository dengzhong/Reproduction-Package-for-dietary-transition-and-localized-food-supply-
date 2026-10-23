$Title milk foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_milk  'milk production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production_set.inc"
/;

set j_milk  'milk demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand_set.inc"
/;

Parameter
   emi_Milk(i_milk)   'Emission intensity at production site'
   milk_production(i_milk) 'Production capacity at each site'
   milk_demand(j_milk)     'Demand at each market'
   emi_total(i_milk)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/emi_Milk.gdx', emi_Milk;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production.gdx', milk_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand.gdx', milk_demand;

emi_total(i_milk) = emi_Milk(i_milk);

Variable
   x(i_milk,j_milk)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_milk)  'Supply capacity constraint'
   demand(j_milk)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_milk)..
   sum(j_milk, x(i_milk,j_milk)) =l= milk_production(i_milk);

demand(j_milk)..
   sum(i_milk, x(i_milk,j_milk)) =e= milk_demand(j_milk);

emission_obj..
   total_emission =e= sum((i_milk,j_milk),
                           x(i_milk,j_milk) * emi_total(i_milk));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/milk_minEmission.gdx";
