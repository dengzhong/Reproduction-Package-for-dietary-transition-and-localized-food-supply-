$ Title cereals for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_cereal  cereal production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_production_set.inc"
/;

set j_cereal  cereal demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_demand_set.inc"
/;



Parameter cereal_production(i_cereal) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/cereal_production.gdx', cereal_production;

Parameter cereal_demand(j_cereal) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_cereal_demand.gdx', cereal_demand;


Parameter dist_new(i_cereal,j_cereal) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_cereal,j_cereal) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_cereal) 'observe supply limit at plant i'
   demand(j_cereal) 'satisfy demand at market j';

d..
    z =e= sum((i_cereal,j_cereal), dist_new(i_cereal,j_cereal)*x(i_cereal,j_cereal));

supply(i_cereal)..
    sum(j_cereal, x(i_cereal,j_cereal)) =l= cereal_production(i_cereal);

demand(j_cereal)..
    sum(i_cereal, x(i_cereal,j_cereal)) =e= cereal_demand(j_cereal);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_eat_cereal_countrylevel.gdx";

