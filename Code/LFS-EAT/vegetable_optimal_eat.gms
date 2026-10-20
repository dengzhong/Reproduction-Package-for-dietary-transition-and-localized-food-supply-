$ Title vegetables for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng

Option LP = Cplex;
option Threads = 0;

set i_vegetable  vegetable production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_production_set.inc"
/;

set j_vegetable  vegetable demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_demand_eat_set.inc"
/;

Parameter vegetable_production(i_vegetable) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_production.gdx', vegetable_production;

Parameter vegetable_demand_eat(j_vegetable) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/vegetable_demand_eat.gdx', vegetable_demand_eat;

Parameter distances(i_vegetable,j_vegetable) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;

Variable
   x(i_vegetable,j_vegetable) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';

Positive Variable x;

Equation
   d         'define objective function'
   supply(i_vegetable) 'observe supply limit at plant i'
   demand(j_vegetable) 'satisfy demand at market j';

d..         z =e= sum((i_vegetable,j_vegetable), distances(i_vegetable,j_vegetable)*x(i_vegetable,j_vegetable));

supply(i_vegetable).. sum(j_vegetable, x(i_vegetable,j_vegetable)) =l= vegetable_production(i_vegetable);

demand(j_vegetable).. sum(i_vegetable, x(i_vegetable,j_vegetable)) =e= vegetable_demand_eat(j_vegetable);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/vegetable_disHarv_eat.gdx";
