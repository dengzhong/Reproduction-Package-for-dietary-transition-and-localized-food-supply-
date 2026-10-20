$ Title pigs for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_pig  pig production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/pig_production_set.inc"
/;

set j_pig  pig demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/pig_demand_set.inc"
/;



Parameter pig_production(i_pig) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/pig_production.gdx', pig_production;

Parameter pig_demand(j_pig) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_pig_demand.gdx', pig_demand;


Parameter dist_new(i_pig,j_pig) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_pig,j_pig) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_pig) 'observe supply limit at plant i'
   demand(j_pig) 'satisfy demand at market j';

d..
    z =e= sum((i_pig,j_pig), dist_new(i_pig,j_pig)*x(i_pig,j_pig));

supply(i_pig)..
    sum(j_pig, x(i_pig,j_pig)) =l= pig_production(i_pig);

demand(j_pig)..
    sum(i_pig, x(i_pig,j_pig)) =e= pig_demand(j_pig);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_eat_pig_countrylevel.gdx";

