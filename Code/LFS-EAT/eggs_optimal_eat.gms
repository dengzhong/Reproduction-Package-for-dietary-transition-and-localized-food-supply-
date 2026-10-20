$ Title eggss for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng

Option LP = Cplex;
option Threads = 1;

set i_eggs  eggs production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production_set.inc"
/;

set j_eggs  eggs demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_eat_set.inc"
/;

Parameter eggs_production(i_eggs) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_production.gdx', eggs_production;

Parameter eggs_demand_eat(j_eggs) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/eggs_demand_eat.gdx', eggs_demand_eat;

Parameter distances(i_eggs,j_eggs) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;

Variable
   x(i_eggs,j_eggs) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';

Positive Variable x;

Equation
   d         'define objective function'
   supply(i_eggs) 'observe supply limit at plant i'
   demand(j_eggs) 'satisfy demand at market j';

d..         z =e= sum((i_eggs,j_eggs), distances(i_eggs,j_eggs)*x(i_eggs,j_eggs));

supply(i_eggs).. sum(j_eggs, x(i_eggs,j_eggs)) =l= eggs_production(i_eggs);

demand(j_eggs).. sum(i_eggs, x(i_eggs,j_eggs)) =e= eggs_demand_eat(j_eggs);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/eggs_disHarv_eat.gdx";
