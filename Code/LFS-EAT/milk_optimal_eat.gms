$ Title milks for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng

Option LP = Cplex;
option Threads = 1;

set i_milk  milk production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production_set.inc"
/;

set j_milk  milk demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand_eat_set.inc"
/;

Parameter milk_production(i_milk) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_production.gdx', milk_production;

Parameter milk_demand_eat(j_milk) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/milk_demand_eat.gdx', milk_demand_eat;

Parameter distances(i_milk,j_milk) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;

Variable
   x(i_milk,j_milk) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';

Positive Variable x;

Equation
   d         'define objective function'
   supply(i_milk) 'observe supply limit at plant i'
   demand(j_milk) 'satisfy demand at market j';

d..         z =e= sum((i_milk,j_milk), distances(i_milk,j_milk)*x(i_milk,j_milk));

supply(i_milk).. sum(j_milk, x(i_milk,j_milk)) =l= milk_production(i_milk);

demand(j_milk).. sum(i_milk, x(i_milk,j_milk)) =e= milk_demand_eat(j_milk);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/milk_disHarv_eat.gdx";
