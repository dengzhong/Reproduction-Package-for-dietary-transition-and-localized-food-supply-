library(gdxrrw)
library(dplyr)
library(readxl)
library(openxlsx)
library(raster)
library(terra)

igdx("/Library/Frameworks/GAMS.framework/Versions/49/Resources/")
if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
output_dir <- "Output/food_miles_and_emissions"
for (folder in c(output_dir, file.path(output_dir, "figure4"), "Output/plots")) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
}
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/07_postprocessing_food_miles_and_transport_emissions.pdf")

rgdx.var <- function(varname) {
  var.data <- data.frame(varname$val)
  var.dim <- length(varname$uels)
  domains <- varname$domains
  for (j in (1:(var.dim))) {
    if (domains[j] == "*") {
      domains[j] <- paste("X", j, sep = "")
    }
  }
  for (i in 1:var.dim) {
    dim           <- data.frame(varname$uels[[i]])
    dim$id        <- seq_along(dim[, 1])
    index         <- varname$domains[i]
    colnames(dim) <- c(index, "id")
    var.colname   <- paste("X", i, sep = "")
    var.data      <- merge(dim, var.data, by.x = "id", by.y = var.colname)
    var.data      <- var.data[, -which(colnames(var.data) == "id")]
  }
  var.data <- var.data[, c(var.dim:1, var.dim + 1)]
  colnames(var.data)[var.dim + 1]  <- c("value")
  colnames(var.data)[var.dim]      <- "field"
  attributes(var.data)$domains     <- varname$domains
  attributes(var.data)$type        <- "variable"
  attributes(var.data)$symName     <- varname$name
  attributes(var.data)$description <- varname$description
  return(var.data)
}

point_demand <- raster('Output/0.5by0.5/calib_2020_population_0.5by0.5.tif') %>%
  as.data.frame(., xy = TRUE) %>%
  na.omit() %>%
  filter(pop_WB_2020 >= 500) %>%
  dplyr::select(-3)

point_production <- raster('Output/0.5by0.5/calib_2020_point_production.tif') %>%
  as.data.frame(., xy = TRUE) %>%
  na.omit() %>%
  filter(prod >= 0) %>%
  dplyr::select(-3)

library(terra)
allland <- rast('Output/transport/alltransport_speed_new.tif')
allland <- ifel(allland == 19, NA, allland)
plot(allland)


start_index <- cellFromXY(allland, point_production)
demand_index <- cellFromXY(allland, point_demand)

BaU <- readRDS('Output/transport_paths/bau_emission_type.rds')
BaU <- BaU %>%
  mutate(unit_emissions = case_when(
    type == 'walk' ~ 1,
    type == 'sea' ~ 12.1,
    type == 'rail' ~ 22.7,
    type == 'road' ~ 119.7
  ))
BaU$distance <- BaU$emissions/BaU$unit_emissions
BaU <- BaU %>% dplyr::select(x, y, type, distance)
country_ID <- raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(.,xy = TRUE)
mapping_region <- read_excel('Input/Other data/mapping country and region.xlsx',range = 'A1:D208')
country_ID <- left_join(country_ID,mapping_region,by = 'country_ID_0.5')


From_index <- cbind(point_production,start_index)
From_index <- left_join(From_index,country_ID,by = c('x','y'))

To_index <- cbind(point_demand,demand_index)
To_index <- left_join(To_index,country_ID,by = c('x','y'))


foods <- c("Bovine", "cereal", "eggs", "fruit", "legume_nuts", "milk",
           "oilcrop", "pig", "poultry", "root", "vegetable")
factors <- data.frame(
  sea = c(19.4, 9.2, 9.2, 16.9, 9.2, 16.9, 9.2, 19.4, 19.4, 9.2, 16.9),
  rail = c(52.1, 45.5, 45.5, 50.5, 45.5, 50.5, 45.5, 52.1, 52.1, 45.5, 50.5),
  road = c(421, 131, 131, 421, 131, 421, 131, 421, 421, 131, 421))
rownames(factors) <- foods
categories <- region_results <- country_results <- vector("list", length(foods))
names(categories) <- names(region_results) <- names(country_results) <- foods
for (k in seq_along(foods)) {
  food <- foods[k]
  trade <- rgdx.var(rgdx(file.path("Output/GAMS/optimize result", paste0(food, "_disHarv.gdx")), list(name = "x")))
  trade[[paste0("i_", food)]] <- as.numeric(gsub("i", "", trade[[paste0("i_", food)]]))
  trade$from <- start_index[trade[[paste0("i_", food)]]]
  trade$field <- as.numeric(gsub("j", "", trade$field))
  trade$to <- demand_index[trade$field]
  colnames(trade) <- c("x", "y", "weight", "from", "to")
  data <- left_join(trade, BaU, by = c("x", "y")) %>%
    mutate(unit_emissions = case_when(
      type == "walk" ~ 1,
      type == "sea"  ~ factors[food, "sea"],
      type == "rail" ~ factors[food, "rail"],
      type == "road" ~ factors[food, "road"]
    )) %>%
    group_by(x, y) %>%
    mutate(distance = ifelse(all(distance == 0) & type == "road", 55 * 0.521, distance)) %>%
    ungroup() %>%
    dplyr::select(x, y, from, to, type, weight, unit_emissions, distance) %>%
    mutate(unit_emissions = if_else(
      type == "walk", factors[food, "road"], unit_emissions
    ))
  data$emissions <- data$weight * 1000 * data$unit_emissions * data$distance / 1000 / 1000 / 1000000000
  final <- data %>%
    left_join(From_index, by = c("from" = "start_index")) %>%
    left_join(To_index, by = c("to" = "demand_index")) %>%
    dplyr::select(country_ID_0.5.x, country_ID_0.5.y, type, emissions, Region.x, Region.y)
  colnames(final) <- c("from", "to", "type", "emissions", "from_region", "to_region")
  country_results[[food]] <- final %>% group_by(from, to, type) %>%
    summarise(emissions_country = sum(emissions, na.rm = TRUE))
  region <- final %>% group_by(from_region, to_region, type) %>%
    summarise(emissions_country = sum(emissions, na.rm = TRUE))
  write.xlsx(region, file.path(output_dir, "figure4", paste0("000BaU_", food, "_region.xlsx")))
  region$item <- food
  region_results[[food]] <- region
  data$item <- food
  categories[[food]] <- data
}
all_BaU_trans_emis <- do.call(rbind, region_results)
write.xlsx(all_BaU_trans_emis, file.path(output_dir, "figure4", "000BaU_all_region.xlsx"))
total_emissions <- sum(vapply(categories, function(data) sum(data$emissions), numeric(1)))
total_distance <- sum(vapply(categories, function(data) sum(data$distance), numeric(1)))
total_distance_by_weight <- sum(vapply(categories, function(data) sum(data$distance * data$weight), numeric(1))) / 1000000000

all_BaU_trans_emis <- do.call(rbind, categories) %>%
  left_join(From_index, by = c("from" = "start_index")) %>%
  dplyr::select(from, count, Region, to, item, type, weight, distance, emissions) %>%
  rename(from_count = count, from_region = Region) %>%
  left_join(To_index, by = c("to" = "demand_index")) %>%
  dplyr::select(x, y, from, from_count, from_region, to, count, Region, item, type, weight, distance, emissions) %>%
  rename(to_count = count, to_region = Region)
Region_type_BaU_trans_emis <- all_BaU_trans_emis %>% group_by(to_region, type, item) %>% summarise(emis = sum(emissions))
write.xlsx(Region_type_BaU_trans_emis, file.path(output_dir, "000Regional emissions by transport mode and item for bau.xlsx"))
type_BaU_trans_emis <- all_BaU_trans_emis %>% group_by(type, item) %>% summarise(emis = sum(emissions))

for (category in names(categories)) {
  
  BaU_data <- categories[[category]]
  
  cell_emissions <- BaU_data %>%
    group_by(to) %>%
    summarise(total_emissions = sum(emissions,na.rm = TRUE))
  
  cell_distance <- BaU_data %>%
    group_by(to) %>%
    summarise(total_distance = sum(distance,na.rm = TRUE))
  
  cell_distance_by_weight <- BaU_data %>%
    group_by(to) %>%
    summarise(total_distance = sum(distance*weight,na.rm = TRUE))
  
  coords <- xyFromCell(allland,cell_distance_by_weight$to)
  
  cell_distance_by_weight <- cbind(coords,cell_distance_by_weight[,"total_distance"])
  cell_distance_by_weight <- rast(cell_distance_by_weight)
  writeRaster(cell_distance_by_weight,paste0('Output/food_miles_and_emissions/000_',category,'_distance_by_weight_bau_sum.tif'),overwrite=TRUE)
  
  cell_distance <- cbind(coords,cell_distance[,"total_distance"])
  cell_distance <- rast(cell_distance)
  writeRaster(cell_distance,paste0('Output/food_miles_and_emissions/000_',category,'_distance_bau_sum.tif'),overwrite=TRUE)
  
  cell_emissions <- cbind(coords,cell_emissions[,"total_emissions"])
  cell_emissions <- rast(cell_emissions)
  writeRaster(cell_emissions,paste0('Output/food_miles_and_emissions/000_',category,'_emissions_bau_sum.tif'),overwrite=TRUE)
  
  types <- unique(BaU_data$type)
  
  for (t in types) {
    BaU_data_type <- BaU_data %>% filter(type == t)
    
    cell_emissions <- BaU_data_type %>%
      group_by(to) %>%
      summarise(total_emissions = sum(emissions, na.rm = TRUE))
    
    cell_distance_by_weight <- BaU_data_type %>%
      group_by(to) %>%
      summarise(total_distance = sum(distance * weight, na.rm = TRUE))
    
    cell_distance <- BaU_data_type %>%
      group_by(to) %>%
      summarise(total_distance = sum(distance, na.rm = TRUE))
    
    coords <- xyFromCell(allland, cell_distance_by_weight$to)
    
    cell_distance_by_weight_rast <- cbind(coords, cell_distance_by_weight[,"total_distance"])
    cell_distance_by_weight_rast <- rast(cell_distance_by_weight_rast)
    writeRaster(cell_distance_by_weight_rast, paste0('Output/food_miles_and_emissions/000_',category,'_distance_by_weight_', t, '_bau_sum.tif'), overwrite = TRUE)
    
    cell_distance_rast <- cbind(coords, cell_distance[,"total_distance"])
    cell_distance_rast <- rast(cell_distance_rast)
    writeRaster(cell_distance_rast, paste0('Output/food_miles_and_emissions/000_',category,'_distance_', t, '_bau_sum.tif'), overwrite = TRUE)
    
    cell_emissions_rast <- cbind(coords, cell_emissions[,"total_emissions"])
    cell_emissions_rast <- rast(cell_emissions_rast)
    writeRaster(cell_emissions_rast, paste0('Output/food_miles_and_emissions/000_',category,'_emission_', t, '_bau_sum.tif'), overwrite = TRUE)
  }
  
}





