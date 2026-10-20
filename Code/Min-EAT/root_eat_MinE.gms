$Title root foodshed optimization; Nov 10, 2025 @Copyright Huazhong Agricultural University - Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_root  'root production locations (supply points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/root_production_set.inc"
/;

set j_root  'root demand locations (demand points)'
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/root_demand_eat_set.inc"
/;

Parameter
   emi_root(i_root)   'Emission intensity at production site'
   root_production(i_root) 'Production capacity at each site'
   root_demand_eat(j_root)     'Demand at each market'
   emi_total(i_root)         'Total emission intensity';

execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/emi_root.gdx', emi_root;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/root_production.gdx', root_production;
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/root_demand_eat.gdx', root_demand_eat;

emi_total(i_root) = emi_root(i_root);

Variable
   x(i_root,j_root)   'Shipment quantity from i to j'
   total_emission         'Total food-related emissions';

Positive Variable x;

Equation
   supply(i_root)  'Supply capacity constraint'
   demand(j_root)  'Demand satisfaction constraint'
   emission_obj      'Objective: minimize food-related emissions';

supply(i_root)..
   sum(j_root, x(i_root,j_root)) =l= root_production(i_root);

demand(j_root)..
   sum(i_root, x(i_root,j_root)) =e= root_demand_eat(j_root);

emission_obj..
   total_emission =e= sum((i_root,j_root),
                           x(i_root,j_root) * emi_total(i_root));

Model transport_emission /emission_obj, supply, demand/;
solve transport_emission using lp minimizing total_emission;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/root_eat_minEmission.gdx";
