$ Title oilcrops for foodshed; Nov 4, 2024 @Copyright Huazhong Agricultural university Zhongci Deng


Option LP = CONOPT4;
option Threads = 0;



set i_oilcrop  oilcrop production point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/oilcrop_production_set.inc"
/;

set j_oilcrop  oilcrop demand point
/
$include "/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/oilcrop_demand_set.inc"
/;



Parameter oilcrop_production(i_oilcrop) 'capacity of plant i in cases';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/oilcrop_production.gdx', oilcrop_production;

Parameter oilcrop_demand(j_oilcrop) 'demand markets';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/EAT_oilcrop_demand.gdx', oilcrop_demand;


Parameter dist_new(i_oilcrop,j_oilcrop) 'distance in kilometer';
execute_load '/Users/zhongcideng/Desktop/Code availability/Input/GAMS input/Country-level/dist_new.gdx', dist_new;

Variable
   x(i_oilcrop,j_oilcrop) 'shipment quantities in cases'
   z      'total transportation disttance in kilometer';
   
Positive Variable x;

Equation
   d         'define objective function'
   supply(i_oilcrop) 'observe supply limit at plant i'
   demand(j_oilcrop) 'satisfy demand at market j';

d..
    z =e= sum((i_oilcrop,j_oilcrop), dist_new(i_oilcrop,j_oilcrop)*x(i_oilcrop,j_oilcrop));

supply(i_oilcrop)..
    sum(j_oilcrop, x(i_oilcrop,j_oilcrop)) =l= oilcrop_production(i_oilcrop);

demand(j_oilcrop)..
    sum(i_oilcrop, x(i_oilcrop,j_oilcrop)) =e= oilcrop_demand(j_oilcrop);

Model transport / all /;

solve transport using lp minimizing z;

execute_unload "/Users/zhongcideng/Desktop/Code availability/Output/GAMS/Country-level/optimize result/Mindist_eat_oilcrop_countrylevel.gdx";

