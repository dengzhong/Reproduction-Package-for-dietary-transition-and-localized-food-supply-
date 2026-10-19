$ Title Bovines for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 1;



set i_Bovine  Bovine production point
/
$include G:/Bovine_production_set.inc
/;

set j_Bovine  Bovine demand point
/
$include G:/Bovine_demand_set.inc
/;

Parameter emi_Bovine(i_Bovine) 'emission intensity for Bovine across country';
execute_load 'G:\Foodshed\for gams\emi_Bovine.gdx', emi_Bovine;


Parameter Bovine_production(i_Bovine) 'Production capacity';
execute_load 'G:\Foodshed\for gams\Bovine_production.gdx', Bovine_production;

Parameter Bovine_demand(j_Bovine) 'demand markets';
execute_load 'G:\Foodshed\for gams\Bovine_demand.gdx', Bovine_demand;


Parameter distances(i_Bovine,j_Bovine) 'distance in kilometer';
execute_load 'G:\Foodshed\for gams\distanceHisv_all.gdx', distances;



Variable
   x(i_Bovine,j_Bovine)     'shipment quantities in cases'
   emi_counsumer(j_Bovine)  'Consumption-based emissions'
   z                        'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   emisssion(j_Bovine) 'Consumption-based emissions'
   supply(i_Bovine) 'observe supply limit at plant i'
   demand(j_Bovine) 'satisfy demand at market j';

d..         z =e= sum((i_Bovine,j_Bovine), distances(i_Bovine,j_Bovine)*x(i_Bovine,j_Bovine));

emisssion(j_Bovine).. emi_counsumer(j_Bovine) =e= sum(i_Bovine, x(i_Bovine,j_Bovine)*emi_Bovine(i_Bovine));

supply(i_Bovine).. sum(j_Bovine, x(i_Bovine,j_Bovine)) =l= Bovine_production(i_Bovine);

demand(j_Bovine).. sum(i_Bovine, x(i_Bovine,j_Bovine)) =e= Bovine_demand(j_Bovine);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "G:\Foodshed\for gams\optimize result\Bovine_disHarv_emission.gdx";