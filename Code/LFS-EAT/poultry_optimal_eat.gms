$ Title poultrys for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng

Option LP = Cplex;
option Threads = 1;

set i_poultry  poultry production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_production_set.inc"
/;

set j_poultry  poultry demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_demand_eat_set.inc"
/;

Parameter poultry_production(i_poultry) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_production.gdx', poultry_production;

Parameter poultry_demand_eat(j_poultry) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/poultry_demand_eat.gdx', poultry_demand_eat;

Parameter distances(i_poultry,j_poultry) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;

Variable
   x(i_poultry,j_poultry) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';

Positive Variable x;

Equation
   d         'define objective function'
   supply(i_poultry) 'observe supply limit at plant i'
   demand(j_poultry) 'satisfy demand at market j';

d..         z =e= sum((i_poultry,j_poultry), distances(i_poultry,j_poultry)*x(i_poultry,j_poultry));

supply(i_poultry).. sum(j_poultry, x(i_poultry,j_poultry)) =l= poultry_production(i_poultry);

demand(j_poultry).. sum(i_poultry, x(i_poultry,j_poultry)) =e= poultry_demand_eat(j_poultry);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/poultry_disHarv_eat.gdx";
