$ Title oilcrops for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 1;



set i_oilcrop  oilcrop production point
/
$include G:/oilcrop_production_set.inc
/;

set j_oilcrop  oilcrop demand point
/
$include G:/oilcrop_demand_set.inc
/;


Parameter oilcrop_production(i_oilcrop) 'capacity of plant i in cases';
execute_load 'G:\Foodshed\for gams\oilcrop_production.gdx', oilcrop_production;

Parameter oilcrop_demand(j_oilcrop) 'demand markets';
execute_load 'G:\Foodshed\for gams\oilcrop_demand.gdx', oilcrop_demand;


Parameter distances(i_oilcrop,j_oilcrop) 'distance in kilometer';
execute_load 'G:\Foodshed\for gams\distanceHisv_all.gdx', distances;



Variable
   x(i_oilcrop,j_oilcrop) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_oilcrop) 'observe supply limit at plant i'
   demand(j_oilcrop) 'satisfy demand at market j';

d..         z =e= sum((i_oilcrop,j_oilcrop), distances(i_oilcrop,j_oilcrop)*x(i_oilcrop,j_oilcrop));

supply(i_oilcrop).. sum(j_oilcrop, x(i_oilcrop,j_oilcrop)) =l= oilcrop_production(i_oilcrop);

demand(j_oilcrop).. sum(i_oilcrop, x(i_oilcrop,j_oilcrop)) =e= oilcrop_demand(j_oilcrop);



Model transport / all /;

solve transport using lp minimizing z;

execute_unload "G:\Foodshed\for gams\optimize result\oilcrop_disHarv.gdx";