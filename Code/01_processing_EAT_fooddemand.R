library(terra)
library(raster)
library(dplyr)
library(readxl)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")

country_file <- "Input/Other data/countrylevel/country_ID_0.5_newest.tif"
population_file <- "Output/0.5by0.5/calib_2020_population_0.5by0.5.tif"
statistics_file <- "Input/Other data/food_demand_for_lancet.xlsx"
output_dir <- "Output/0.5by0.5/EAT_food_demand"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
food_types <- c("cereal", "root", "pulses", "nuts", "oilcrop", "sugar", "fruit", "vegetable", "Bovine", "eggs", "pig", "poultry", "milk")

country_grid <- rast(country_file)
country_ID <- as.data.frame(raster(country_file), xy = TRUE)
population <- as.data.frame(raster(population_file), xy = TRUE)
population[!is.na(population[, 3]) & population[, 3] < 5000, 3] <- NA
population_2020_ID <- left_join(population, country_ID, by = c("x", "y"))
colnames(population_2020_ID) <- c("x", "y", "pop_2020", "ISO3")
statistics <- read_excel(statistics_file)

for (food in food_types) {
  food_demand <- statistics %>%
    dplyr::select(ID_0, Item, food_demand) %>%
    filter(ID_0 != "#N/A", Item == food) %>%
    dplyr::select(ID_0, food_demand)
  colnames(food_demand) <- c("ISO3", "Value")
  food_demand$ISO3 <- as.numeric(food_demand$ISO3)
  demand_name <- paste0(food, "_demand")
  demand <- left_join(population_2020_ID, food_demand, by = "ISO3") %>%
    mutate(!!demand_name := pop_2020 * Value / 1000 / 1000) %>%
    dplyr::select(x, y, all_of(demand_name))
  demand <- rast(demand)
  ext(demand) <- ext(country_grid)
  crs(demand) <- crs(country_grid)
  writeRaster(demand, file.path(output_dir, paste0(food, "_demand_0.5by0.5_select.tif")), overwrite = TRUE)
}
