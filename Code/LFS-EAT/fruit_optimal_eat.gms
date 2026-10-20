$ Title fruits for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng

Option LP = Cplex;
option Threads = 1;

set i_fruit  fruit production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_production_set.inc"
/;

set j_fruit  fruit demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_demand_eat_set.inc"
/;

Parameter fruit_production(i_fruit) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_production.gdx', fruit_production;

Parameter fruit_demand_eat(j_fruit) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/fruit_demand_eat.gdx', fruit_demand_eat;

Parameter distances(i_fruit,j_fruit) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;

Variable
   x(i_fruit,j_fruit) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';

Positive Variable x;

Equation
   d         'define objective function'
   supply(i_fruit) 'observe supply limit at plant i'
   demand(j_fruit) 'satisfy demand at market j';

d..         z =e= sum((i_fruit,j_fruit), distances(i_fruit,j_fruit)*x(i_fruit,j_fruit));

supply(i_fruit).. sum(j_fruit, x(i_fruit,j_fruit)) =l= fruit_production(i_fruit);

demand(j_fruit).. sum(i_fruit, x(i_fruit,j_fruit)) =e= fruit_demand_eat(j_fruit);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/fruit_disHarv_eat.gdx";
