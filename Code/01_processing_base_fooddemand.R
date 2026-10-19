library(terra)
library(raster)
library(dplyr)
library(readxl)

country_file <- "G:/Foodshed/countrylevel/country_ID_0.5_newest.tif"
population_file <- "G:/Foodshed/0.5by0.5/calib_2020_population_0.5by0.5.tif"
statistics_dir <- "G:/Foodshed/code for foodshed"
output_dir <- "G:/Foodshed/0.5by0.5/basic_food_demand"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
crop_list <- c("cereal", "root", "pulses", "nuts", "oilcrop", "sugar", "fruit", "vegetable", "stimulant")
livestock_list <- c("Bovine", "eggs", "milk", "pig", "poultry")

# 1. Prepare population and country IDs.
country_grid <- rast(country_file)
country_ID <- as.data.frame(raster(country_file), xy = TRUE)
population <- as.data.frame(raster(population_file), xy = TRUE)
population[!is.na(population[, 3]) & population[, 3] < 5000, 3] <- NA
population_2020_ID <- left_join(population, country_ID, by = c("x", "y"))
colnames(population_2020_ID) <- c("x", "y", "pop_2020", "ISO3")

# 2. Calculate demand for nine crop and five livestock groups.
for (food_group in c("crop", "livestock")) {
  food_list <- if (food_group == "crop") crop_list else livestock_list
  statistics <- read_excel(file.path(statistics_dir, paste0(food_group, "_production_demand.xlsx")))
  for (food_name in food_list) {
    food_demand <- statistics %>%
      dplyr::select(ID_0, Item, supply) %>%
      filter(ID_0 != "#N/A", Item == food_name) %>%
      dplyr::select(ID_0, supply)
    colnames(food_demand) <- c("ISO3", "Value")
    food_demand$ISO3 <- as.numeric(food_demand$ISO3)
    demand_name <- paste0(food_name, "_demand")
    demand_tif <- left_join(population_2020_ID, food_demand, by = "ISO3") %>%
      mutate(!!demand_name := pop_2020 * Value / 1000 / 1000) %>%
      dplyr::select(x, y, all_of(demand_name))
    demand_tif_new <- rast(demand_tif)
    ext(demand_tif_new) <- ext(country_grid)
    crs(demand_tif_new) <- crs(country_grid)
    writeRaster(demand_tif_new,
                file.path(output_dir, paste0(food_name, "_demand_0.5by0.5_select.tif")),
                overwrite = TRUE)
  }
}

cereal_demand <- raster(file.path(output_dir, "cereal_demand_0.5by0.5_select.tif")) %>%
  as.data.frame(xy = TRUE) %>% na.omit()
sum(cereal_demand$cereal_demand, na.rm = TRUE)
