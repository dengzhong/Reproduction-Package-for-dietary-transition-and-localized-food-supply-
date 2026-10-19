$ Title Bovines for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 1;



set i_Bovine  Bovine production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_production_set.inc"
/;

set j_Bovine  Bovine demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_demand_set.inc"
/;



Parameter Bovine_production(i_Bovine) 'Production capacity';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_production.gdx', Bovine_production;

Parameter Bovine_demand(j_Bovine) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Bovine_demand.gdx', Bovine_demand;


Parameter distances(i_Bovine,j_Bovine) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;



Variable
   x(i_Bovine,j_Bovine)     'shipment quantities in cases'
   z                        'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_Bovine) 'observe supply limit at plant i'
   demand(j_Bovine) 'satisfy demand at market j';

d..         z =e= sum((i_Bovine,j_Bovine), distances(i_Bovine,j_Bovine)*x(i_Bovine,j_Bovine));


supply(i_Bovine).. sum(j_Bovine, x(i_Bovine,j_Bovine)) =l= Bovine_production(i_Bovine);

demand(j_Bovine).. sum(i_Bovine, x(i_Bovine,j_Bovine)) =e= Bovine_demand(j_Bovine);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/Bovine_disHarv.gdx";