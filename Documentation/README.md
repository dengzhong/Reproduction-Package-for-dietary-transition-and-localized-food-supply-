# Parameter descriptions and data dictionary

This document defines the model parameters, data fields, spatial identifiers and accounting conventions used by the scripts in `Code/`. File paths are relative to the repository root. The [main README](../README.md#6-how-to-run-the-code) describes the computational workflow and execution order.

## 1. Conventions and identifiers

| Identifier | Meaning |
|---|---|
| `<food>` | `Bovine`, `cereal`, `eggs`, `fruit`, `legume_nuts`, `milk`, `oilcrop`, `pig`, `poultry`, `root` or `vegetable`. |
| `bau` / Base | Baseline dietary demand used in an optimization scenario. The `bau` label in post-processing filenames refers to LFS-Base results. |
| `eat` / EAT | EAT-Lancet dietary demand. |
| `halfeat` / `halfEAT` | Half-EAT dietary scenario. |
| `Mindist` / LFS | Optimization minimizing shipment quantity multiplied by modeled distance. |
| `MinE` | Optimization minimizing shipment quantity multiplied by production-origin emission intensity. |
| `x`, `y` in spatial tables | Longitude and latitude, in degrees. |
| `i1`, `i2`, … | Production-location labels in GAMS. In grid models the integer refers to the shared production-location list, not directly to the raster cell number. |
| `j1`, `j2`, … | Demand-location labels in GAMS. In grid models the integer refers to the shared demand-location list. |
| `start_index` | Raster cell numbers of the production locations. |
| `demand_index` | Raster cell numbers of the demand locations. |
| `ID_0`, `country_ID_0.5`, `ISO3` | Country identifiers used to link spatial and tabular data. In some scripts, numeric country identifiers are assigned the column name `ISO3`; their interpretation follows the source workbook. |

Grid-level analyses use a spatial resolution of 0.5°. Cell identifiers follow the ordering of the transport raster. Country-level analyses use the national sets and labels defined in the supplied GDX files.

## 2. GAMS sets, parameters and variables

| Symbol | Dimensions | Meaning and units |
|---|---|---|
| `i_<food>` | Production locations | Locations included in the food-specific production set. |
| `j_<food>` | Demand locations | Locations included in the food-specific demand set. |
| `<food>_production(i)` | One value per origin | Upper bound on production available for allocation, expressed in the mass unit of the supplied GDX file. |
| `<food>_demand(j)` | One value per destination | Baseline dietary demand. Country-level models retain this symbol across dietary scenarios and load the corresponding scenario-specific inputs. |
| `<food>_demand_eat(j)` | One value per destination | EAT demand in grid-level models. |
| `<food>_demand_halfeat(j)` | One value per destination | Half-EAT demand in grid-level models. |
| `distances(i,j)` | Origin × destination | Grid-level modeled transport distance, km, loaded from `distanceHisv_all.gdx`. |
| `dist_new(i,j)` | Country origin × country destination | National transport-distance matrix, km. |
| `emi_<product>(i)` | One value per origin | Production emission intensity associated with the origin; the product name can differ from the food-category name. |
| `emi_total(i)` | One value per origin | Emission intensity used in the MinE objective, equal to the production emission intensity at each origin. |
| `x(i,j)` | Origin × destination | Nonnegative optimized shipment quantity, expressed in the same mass unit as production availability and demand. Here, `x` denotes the decision variable. |
| `z` | Scalar | Food-miles objective: sum of `distance × x`, in model mass units × km. |
| `total_emission` | Scalar | MinE objective: sum of `emi_total × x`, in units implied by mass and intensity. |

The supply constraint, `sum(j, x(i,j)) <= production(i)`, limits allocated output to available production. The demand constraint, `sum(i, x(i,j)) = demand(j)`, requires full demand satisfaction. Production availability defines an upper bound; realized production follows the allocated output. All models are formulated as continuous linear programs.

The correspondence between food categories, production-emission intensity files and GAMS parameters is given below.

| Food | GDX file | Parameter |
|---|---|---|
| Bovine | `emi_Bovine.gdx` | `emi_Bovine` |
| cereal | `emi_cereal.gdx` | `emi_cereal` |
| eggs | `emi_Eggs.gdx` | `emi_Eggs` |
| fruit | `emi_fruit.gdx` | `emi_fruit` |
| legume_nuts | `emi_pulses.gdx` | `emi_pulses` |
| milk | `emi_Milk.gdx` | `emi_Milk` |
| oilcrop | `emi_oilcrop.gdx` | `emi_oilcrop` |
| pig | `emi_Pork.gdx` | `emi_Pork` |
| poultry | `emi_Poultry.gdx` | `emi_Poultry` |
| root | `emi_root.gdx` | `emi_root` |
| vegetable | `emi_vegetable.gdx` | `emi_vegetable` |

Grid-level inputs are stored in `Input/GAMS input/`, and national inputs are stored in its `Country-level/` subdirectory. Identically named files in these directories refer to different spatial domains. Models that reference `cereal_production1.gdx` use that specific production dataset.

## 3. Input file dictionary

| File or group | Content and use |
|---|---|
| `Other data/countrylevel/gadm36_countrylevel（无南极洲）.shp` | Country boundaries rasterized using `GID_0`, accompanied by the associated DBF, SHX and PRJ files. |
| `Other data/countrylevel/country_ID_0.5_newest.tif` | Country identifiers on the common 0.5° grid. |
| `Other data/mapping_name1.tif` | Reference grid used in feed preprocessing. |
| `Other data/population/poplution_2020/gpw-v4-population-count_2020.tif` | GPW 2020 population count; people per source cell. |
| `Other data/population_WB.xlsx` | National 2020 population totals. The code renames its two columns to `ISO3` and `Value`. |
| `Other data/livestock.xlsx` | Livestock production calibration table with `Area`, `ISO3`, `Item`, `Value`. |
| `Other data/livestock_new.xlsx` | Final calibration table with `country`, `ISO3`, `ID_0`, `Item`, `Value`. |
| `Other data/crop_production_demand.xlsx` | Crop statistics: country identifiers, `pop`, `Item`, `supply` and `production`. |
| `Other data/livestock_production_demand.xlsx` | Livestock statistics: country identifiers, `Item`, `supply` and `production`. |
| `Other data/food_demand_for_lancet.xlsx` | EAT demand: country identifiers, `Region Code`, `Item`, `supply`, `waste coefficient` and `food_demand`. |
| `Other data/feed_total_2020.csv` | National feed totals used to calibrate grain-feed quantities. |
| `Other data/feed_fodder_ratio_2020.csv` | Country-specific `Crop` and `Oil` feed ratios. |
| `Other data/mapping country and region.xlsx` | Country-to-region correspondence table. The scripts read `A1:D208`, containing `country_ID_0.5`, `Region_code`, `Region` and `count`. |
| `Livestock Production Systems data/` | Seven production rasters and seven grain-feed rasters. The main README specifies source files and required directory structure. |
| `SPAM data/` | Individual crop production rasters combined into the modeled food groups. |
| `Other data/transport/GRIP4_density_tp1/` … `tp5/` | Road-density ASC rasters: highways, primary, secondary, tertiary and local roads. Source density units are m of road per km². |
| `Other data/transport/railroad_0.5deg.tif` | Prepared railway raster used to identify rail cells. |
| `Other data/transport/shippingnew_0.5deg.tif` | Prepared shipping raster used to identify maritime cells. |

### 3.1. Common workbook fields

| Field | Meaning |
|---|---|
| `country`, `Area` | Country name. |
| `ISO3`, `ID_01`, `ID_0` | Identifiers linking national statistics to spatial units, with conversions defined in the relevant preprocessing scripts. |
| `Item` | Crop, livestock or combined food category used for filtering. |
| `Value` | Numeric population or production statistic; interpretation depends on the workbook. |
| `pop`, `2020` | Population total or reference-year population. |
| `supply` | Per-capita food availability used by the baseline demand calculation. The code computes `population × supply / 1000 / 1000`. With supply in kg/person/year, this produces thousand tonnes/year. |
| `production` | National production target used to calibrate food-production rasters. |
| `food_demand` | EAT per-capita demand quantity used by the EAT demand script. |
| `waste coefficient` | Food-specific adjustment column in the supplied EAT workbook. |
| `count` | Country label used for origin/destination attribution and international trade comparisons. |
| `Region`, `Region_code`, `Region Code` | Regional classification labels or codes, with field names retained from the corresponding source tables. |

## 4. Transport parameters

The transport network is parameterized using the settings below. Path selection depends on normalized travel time and relative cost; mass conversions are applied during subsequent emissions accounting.

| Setting | Value or rule |
|---|---|
| Network connections | Eight neighboring raster cells; directed graph. |
| Highway / primary / secondary / tertiary / local road speeds | 100 / 80 / 60 / 20 / 20 km/h, before aggregation. |
| Railway speed | 24 km/h. |
| Designated shipping speed | 19 km/h. |
| Default speed for residual land cells | 5 km/h. |
| Default speed for remaining cells | 10 km/h. |
| Relative costs | Rail 3; road 25; designated shipping 1; residual cells assigned speeds of 5 and 10 have a relative cost of 100. |
| Time normalization | `(time - 1/100) / (1/5 - 1/100)`, with `time = 1 / speed`. |
| Cost normalization | `(cost - 1) / (25 - 1)`. |
| Edge weight | `0.5 × normalized_time + 0.5 × normalized_cost`. |
| Geographic path distance | Sum of Haversine distances between consecutive path-cell centers, converted from m to km. |
| Intra-cell correction in script 07 | If all mode distances of an origin–destination pair are zero, assign `55 × 0.521 = 28.655 km` to road. |

The unit step used to construct path-selection weights provides the basis for normalization. Geographic transport distances are subsequently calculated from consecutive path-cell coordinates.

### 4.1. Transport emission factors

Script `06` multiplies mode-specific path lengths by reference factors of 119.7 for road, 22.7 for rail, 12.1 for sea and 1 for walk. The resulting intermediate retains the distance contribution of each transport mode. Script `07` recovers these distances by division and calculates shipment-weighted emissions using the food-specific factors below, expressed in g CO2eq/(tonne·km).

| Food | Sea | Rail | Road |
|---|---:|---:|---:|
| Bovine | 19.4 | 52.1 | 421 |
| cereal | 9.2 | 45.5 | 131 |
| eggs | 9.2 | 45.5 | 131 |
| fruit | 16.9 | 50.5 | 421 |
| legume_nuts | 9.2 | 45.5 | 131 |
| milk | 16.9 | 50.5 | 421 |
| oilcrop | 9.2 | 45.5 | 131 |
| pig | 19.4 | 52.1 | 421 |
| poultry | 19.4 | 52.1 | 421 |
| root | 9.2 | 45.5 | 131 |
| vegetable | 16.9 | 50.5 | 421 |

For the `walk` category, script `07` applies the corresponding food's road factor when calculating final transport emissions.

## 5. Intermediate files and their fields

| File | Schema or contents |
|---|---|
| `Output/0.5by0.5/calib_2020_population_0.5by0.5.tif` | Calibrated population, people per cell; layer `pop_WB_2020`. |
| `Output/0.5by0.5/calib_2020_point_production.tif` | Combined production-location raster; layer `prod`. |
| `Output/0.5by0.5/calib_2020_<food>_0.5by0.5.tif` | Calibrated food production; layers used by the code commonly end in `_2020`. |
| `Output/transport/alltransport_speed_new.tif` | Combined transport speed in km/h. |
| `Output/distances/*.h5` | Nine numeric matrices with datasets `/distance_all1` … `/distance_all9`. Rows and columns retain the common origin/destination ordering. |
| `Output/GAMS/distanceHisv_all.gdx` | H5 blocks combined into the two-dimensional GAMS parameter `distances`, labeled by production and demand index. |
| `Output/GAMS/*_index.mat` | Six implemented MAT examples; see below. |
| `Output/GAMS/source_all.rds` | Data frame with `from` and list column `to_list`, identifying destinations associated with each production cell. |
| `Output/transport_paths/distance_by_emissions_by_type_bau(...).rds` | Mode-specific path records for each computational partition. |
| `Output/transport_paths/bau_emission_type.rds` | Mode-specific path records concatenated across all computational partitions. |

MAT exports contain `set_demand` and a food-demand spatial table. Baseline examples additionally contain `set_production` and a food-production spatial table. The set values identify positions in the shared production and demand lists. Cereal and oilcrop examples incorporate their corresponding feed demand; `legume_nuts` combines pulses and nuts.

### 5.1. Path RDS fields

| Field | Meaning |
|---|---|
| `from`, `to` | Origin and destination raster cell numbers. |
| `to_list` | List of destination cell numbers for an origin in `source_all.rds`. |
| `type` | `road`, `rail`, `sea` or `walk`. Each origin–destination pair has a row for each mode. |
| `distance` | Cumulative path length for the mode, km. Available in script 06 outputs. |
| `emissions` | In path RDS files: `distance × reference factor`, before multiplying by shipment quantity. |
| `x`, `y` | In path RDS files: origin position in the production-location list and destination position in the demand-location list. These fields identify positions in the location lists. |

Field definitions depend on the data structure. Spatial-table `x/y` denote coordinates, path-table `x/y` denote location-list positions, and GAMS `x` denotes shipment quantity.

## 6. Final outputs and accounting

| Output | Meaning |
|---|---|
| `Output/GAMS/optimize result/*.gdx` | Grid-level optimized flows and model symbols. Scenario-specific filenames are listed in the main README. |
| `Output/GAMS/Country-level/optimize result/*.gdx` | Optimized national food flows, indexed by the national production and demand sets. |
| `Output/food_miles_and_emissions/*_distance_bau_sum.tif` | Cumulative modeled distance of incoming flows at each demand cell, expressed in km. |
| `Output/food_miles_and_emissions/*_distance_by_weight_bau_sum.tif` | Sum of shipment quantity × distance at each demand cell. Raster values are expressed in model mass units × km. |
| `Output/food_miles_and_emissions/*_emissions_bau_sum.tif` | Shipment-weighted transport emissions, using the conversion expression in script 07. |
| `Output/food_miles_and_emissions/figure4/*.xlsx` | Regional transport-emission aggregates by origin, destination, food and transport mode. |
| `Output/food_related_emissions/000_food_related_emissions_LFS_Base.tif` | Production emissions attributable to food consumed in each demand cell, summed across foods. Transport emissions are excluded. |
| `Output/food_related_emissions/food_related_emis.xlsx` | Destination-country food-related emissions: `to_iso`, `to_region`, `emis`, `item`. |
| `Output/regional_food_trade/LFS_Base_trade.xlsx` | Regional bilateral flows: `from_region`, `to_region`, `tradeValue`, `Item`. |
| `Output/regional_food_trade/LFS_Base_country_trade.xlsx` | National bilateral flows and their associated regions. |
| `Output/regional_food_trade/LFS_Base_imports_exports.xlsx` | Separate regional and international trade summaries. |
| `Output/GAMS/logs/*.log` | Archived LFS-Base solver logs. |

### 6.1. Unit conversions

Physical units are determined by the source datasets and accounting expressions. Production availability, dietary demand and shipment quantities share a common mass scale. With per-capita supply expressed in kg/person/year, the baseline demand calculation yields thousand tonnes/year.

Transport emissions in script `07` are calculated as follows:

```r
emissions = weight * 1000 * unit_emissions * distance / 1000 / 1000 / 1000000000
```

When `weight` is expressed in thousand tonnes and `unit_emissions` in g CO2eq/(tonne·km), the calculated emissions are in Gt CO2eq. Conversion to Mt CO2eq requires multiplication by 1000. The `distance * weight` raster is expressed in thousand tonne-km. The global summary `total_distance_by_weight` divides the aggregate by `1e9`, yielding trillion tonne-km under the same mass convention.

Script `08` calculates `shipment quantity × production intensity`, with units determined by the shipment mass scale and source emission intensity. Its scalar summary divides the aggregate by `1e6`. The units of fields named `emissions` or `emis` therefore follow their respective accounting expressions.

### 6.2. Regional trade summary fields

| Field | Meaning |
|---|---|
| `tradeValue`, `weight` | Physical quantity of food transported between origin and destination. |
| `exports`, `imports` | Outgoing and incoming cross-region quantities in the regional sheet; cross-country quantities aggregated by region in the international sheet. |
| `internal_supply` | Flows whose origin and destination belong to the same region, including international flows within that region. |
| `total_supply` | `internal_supply + exports`. |
| `total_demand` | `internal_supply + imports`. |
| `net_exports` | `exports - imports`. |
| `import_share` | Regional imports divided by total regional demand, as a fraction from 0 to 1 when quantities are nonnegative. |

The regional aggregation merges Central America into South America and combines North America and Oceania as North America & Oceania. This regional classification is implemented in script 09; regional labels in other analyses follow the corresponding scripts.
