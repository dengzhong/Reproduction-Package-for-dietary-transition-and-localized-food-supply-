$ Title legume_nutss for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = Cplex;
option Threads = 0;



set i_legume_nuts  legume_nuts production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_production_set.inc"
/;

set j_legume_nuts  legume_nuts demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_demand_set.inc"
/;




Parameter legume_nuts_production(i_legume_nuts) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_production.gdx', legume_nuts_production;

Parameter legume_nuts_demand(j_legume_nuts) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/legume_nuts_demand.gdx', legume_nuts_demand;


Parameter distances(i_legume_nuts,j_legume_nuts) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Output/GAMS/distanceHisv_all.gdx', distances;



Variable
   x(i_legume_nuts,j_legume_nuts) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_legume_nuts) 'observe supply limit at plant i'
   demand(j_legume_nuts) 'satisfy demand at market j';

d..         z =e= sum((i_legume_nuts,j_legume_nuts), distances(i_legume_nuts,j_legume_nuts)*x(i_legume_nuts,j_legume_nuts));

supply(i_legume_nuts).. sum(j_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =l= legume_nuts_production(i_legume_nuts);

demand(j_legume_nuts).. sum(i_legume_nuts, x(i_legume_nuts,j_legume_nuts)) =e= legume_nuts_demand(j_legume_nuts);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/optimize result/legume_nuts_disHarv.gdx";