$ Title Bovines for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_Bovine  Bovine production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_production_set.inc"
/;

set j_Bovine  Bovine demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_demand_set.inc"
/;
display i_Bovine;


Parameter Bovine_production(i_Bovine) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/Bovine_production.gdx', Bovine_production;

Parameter Bovine_demand(j_Bovine) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/halfEAT_Bovine_demand.gdx', Bovine_demand;


Parameter dist_new(i_Bovine,j_Bovine) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_Bovine,j_Bovine) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_Bovine) 'observe supply limit at plant i'
   demand(j_Bovine) 'satisfy demand at market j';

d..
    z =e= sum((i_Bovine,j_Bovine), dist_new(i_Bovine,j_Bovine)*x(i_Bovine,j_Bovine));

supply(i_Bovine)..
    sum(j_Bovine, x(i_Bovine,j_Bovine)) =l= Bovine_production(i_Bovine);

demand(j_Bovine)..
    sum(i_Bovine, x(i_Bovine,j_Bovine)) =e= Bovine_demand(j_Bovine);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_halfEAT_Bovine_countrylevel.gdx";

