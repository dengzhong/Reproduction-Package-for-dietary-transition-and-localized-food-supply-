$ Title poultrys for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_poultry  poultry production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_production_set.inc"
/;

set j_poultry  poultry demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_demand_set.inc"
/;



Parameter poultry_production(i_poultry) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/poultry_production.gdx', poultry_production;

Parameter poultry_demand(j_poultry) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_poultry_demand.gdx', poultry_demand;


Parameter dist_new(i_poultry,j_poultry) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_poultry,j_poultry) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_poultry) 'observe supply limit at plant i'
   demand(j_poultry) 'satisfy demand at market j';

d..
    z =e= sum((i_poultry,j_poultry), dist_new(i_poultry,j_poultry)*x(i_poultry,j_poultry));

supply(i_poultry)..
    sum(j_poultry, x(i_poultry,j_poultry)) =l= poultry_production(i_poultry);

demand(j_poultry)..
    sum(i_poultry, x(i_poultry,j_poultry)) =e= poultry_demand(j_poultry);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_eat_poultry_countrylevel.gdx";

