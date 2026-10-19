$ Title cereals for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 1;



set i_cereal  cereal production point
/
$include G:/cereal_production_set.inc
/;

set j_cereal  cereal demand point
/
$include G:/cereal_demand_set.inc
/;




Parameter cereal_production(i_cereal) 'capacity of plant i in cases';
execute_load 'G:\Foodshed\for gams\cereal_production.gdx', cereal_production;

Parameter cereal_demand(j_cereal) 'demand markets';
execute_load 'G:\Foodshed\for gams\cereal_demand.gdx', cereal_demand;


Parameter distances(i_cereal,j_cereal) 'distance in kilometer';
execute_load 'G:\Foodshed\for gams\distanceHisv_all.gdx', distances;



Variable
   x(i_cereal,j_cereal) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_cereal) 'observe supply limit at plant i'
   demand(j_cereal) 'satisfy demand at market j';

d..         z =e= sum((i_cereal,j_cereal), distances(i_cereal,j_cereal)*x(i_cereal,j_cereal));

supply(i_cereal).. sum(j_cereal, x(i_cereal,j_cereal)) =l= cereal_production(i_cereal);

demand(j_cereal).. sum(i_cereal, x(i_cereal,j_cereal)) =e= cereal_demand(j_cereal);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "cereal_disHarv.gdx";