library(terra)
library(raster)
library(dplyr)
library(R.matlab)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/04_food_demand_to_gams.pdf")

folder <- "Output/0.5by0.5"
output_dir <- "Output/GAMS"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
jobs <- data.frame(
  scenario = c("base", "base", "base", "eat", "eat", "eat"),
  food = c("vegetable", "cereal", "legume_nuts", "fruit", "oilcrop", "legume_nuts"),
  output = c("vegetable_index.mat", "cereal_index.mat", "legume_nuts_index.mat",
             "fruit_eat_index.mat", "oilcrop_eat_index.mat", "legume_nuts_eat_index.mat")
)

# 1. Match production and demand locations to the transport grid.
point_demand <- raster(file.path(folder, "calib_2020_population_0.5by0.5.tif")) %>%
  as.data.frame(xy = TRUE) %>% na.omit() %>%
  filter(pop_WB_2020 >= 500) %>% dplyr::select(-3)
point_production <- raster(file.path(folder, "calib_2020_point_production.tif")) %>%
  as.data.frame(xy = TRUE) %>% na.omit() %>%
  filter(prod >= 0) %>% dplyr::select(-3)
allland <- rast("Output/transport/alltransport_speed_new.tif")
allland <- ifel(allland == 19, NA, allland)
plot(allland)
start_index <- cellFromXY(allland, point_production)
demand_index <- cellFromXY(allland, point_demand)

# 2. Export the six original GAMS input files.
for (i in seq_len(nrow(jobs))) {
  scenario <- jobs$scenario[i]
  food <- jobs$food[i]
  demand_dir <- file.path(folder, if (scenario == "base") "basic_food_demand" else "EAT_food_demand")
  if (food == "legume_nuts") {
    nuts_demand <- as.data.frame(raster(file.path(demand_dir, "nuts_demand_0.5by0.5_select.tif")), xy = TRUE)
    pulses_demand <- as.data.frame(raster(file.path(demand_dir, "pulses_demand_0.5by0.5_select.tif")), xy = TRUE)
    demand_total <- nuts_demand
    demand_total$legume_nuts_demand <- rowSums(cbind(nuts_demand$nuts_demand, pulses_demand$pulses_demand), na.rm = TRUE)
    demand_total <- demand_total %>% filter(legume_nuts_demand > 0) %>% dplyr::select(-3)
  } else {
    demand_total <- raster(file.path(demand_dir, paste0(food, "_demand_0.5by0.5_select.tif"))) %>%
      as.data.frame(xy = TRUE) %>% na.omit()
    demand_column <- paste0(food, "_demand")
    if (food %in% c("cereal", "oilcrop")) {
      feed_file <- if (scenario == "base") "basic_feed_demand/crop_feed_.tif" else "EAT_feed_demand/Oil_feed_eat.tif"
      feed_column <- if (scenario == "base") "crop_feed" else "Oil_feed"
      feed <- raster(file.path(folder, feed_file)) %>% as.data.frame(xy = TRUE) %>% na.omit()
      demand_total <- left_join(demand_total, feed, by = c("x", "y"))
      combined_column <- paste0(food, "_demand1")
      demand_total[[combined_column]] <- rowSums(cbind(demand_total[[demand_column]], demand_total[[feed_column]]), na.rm = TRUE)
      demand_column <- combined_column
      demand_total <- demand_total %>% dplyr::select(x, y, all_of(demand_column))
    }
    demand_total <- demand_total %>% filter(.data[[demand_column]] > 0)
  }
  demand_coords <- demand_total %>% dplyr::select(x, y)
  positions_demand <- which(demand_index %in% cellFromXY(allland, demand_coords))
  payload <- list()
  if (scenario == "base") {
    if (food == "legume_nuts") {
      nuts_prod <- as.data.frame(raster(file.path(folder, "calib_2020_nuts_0.5by0.5.tif")), xy = TRUE)
      pulses_prod <- as.data.frame(raster(file.path(folder, "calib_2020_pulses_0.5by0.5.tif")), xy = TRUE)
      production_total <- nuts_prod %>%
        mutate(legume_nuts_prod = rowSums(cbind(nuts_prod$nuts_2020, pulses_prod$pulses_2020), na.rm = TRUE)) %>%
        filter(legume_nuts_prod >= 1) %>% dplyr::select(-3)
    } else {
      production_column <- paste0(food, "_2020")
      production_total <- raster(file.path(folder, paste0("calib_2020_", food, "_0.5by0.5.tif"))) %>%
        as.data.frame(xy = TRUE) %>% na.omit() %>% filter(.data[[production_column]] >= 1)
      plot(rast(production_total))
    }
    production_coords <- production_total %>% dplyr::select(x, y)
    payload$set_production <- which(start_index %in% cellFromXY(allland, production_coords))
    payload$set_demand <- positions_demand
    payload[[paste0(food, "_production")]] <- production_total
  } else {
    payload$set_demand <- positions_demand
  }
  payload[[paste0(food, "_demand")]] <- demand_total
  do.call(writeMat, c(list(file.path(output_dir, jobs$output[i])), payload))
}
