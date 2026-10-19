$ Title roots for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 1;



set i_root  root production point
/
$include G:/root_production_set.inc
/;

set j_root  root demand point
/
$include G:/root_demand_set.inc
/;




Parameter root_production(i_root) 'capacity of plant i in cases';
execute_load 'G:\Foodshed\for gams\root_production.gdx', root_production;

Parameter root_demand(j_root) 'demand markets';
execute_load 'G:\Foodshed\for gams\root_demand.gdx', root_demand;


Parameter distances(i_root,j_root) 'distance in kilometer';
execute_load 'G:\Foodshed\for gams\distanceHisv_all.gdx', distances;



Variable
   x(i_root,j_root) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_root) 'observe supply limit at plant i'
   demand(j_root) 'satisfy demand at market j';

d..         z =e= sum((i_root,j_root), distances(i_root,j_root)*x(i_root,j_root));

supply(i_root).. sum(j_root, x(i_root,j_root)) =l= root_production(i_root);

demand(j_root).. sum(i_root, x(i_root,j_root)) =e= root_demand(j_root);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "G:\Foodshed\for gams\optimize result\root_disHarv.gdx";