$ Title roots for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_root  root production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/root_production_set.inc"
/;

set j_root  root demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/root_demand_set.inc"
/;



Parameter root_production(i_root) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/root_production.gdx', root_production;

Parameter root_demand(j_root) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_root_demand.gdx', root_demand;


Parameter dist_new(i_root,j_root) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_root,j_root) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_root) 'observe supply limit at plant i'
   demand(j_root) 'satisfy demand at market j';

d..
    z =e= sum((i_root,j_root), dist_new(i_root,j_root)*x(i_root,j_root));

supply(i_root)..
    sum(j_root, x(i_root,j_root)) =l= root_production(i_root);

demand(j_root)..
    sum(i_root, x(i_root,j_root)) =e= root_demand(j_root);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_eat_root_countrylevel.gdx";

