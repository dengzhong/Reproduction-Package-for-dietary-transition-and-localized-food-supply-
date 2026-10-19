library(terra)
library(raster)

folder <- "G:/Foodshed/0.5by0.5"
food_types <- c("cereal", "root", "pulses", "nuts", "oilcrop", "sugar", "fruit", "vegetable", "stimulant", "bovine", "eggs", "milk", "pig", "poultry")
for (i in seq_along(food_types)) {
  food <- food_types[i]
  input_file <- file.path(folder, paste0("calib_2020_", food, "_0.5by0.5.tif"))
  if (food == "bovine" && !file.exists(input_file)) {
    input_file <- file.path(folder, "calib_2020_Bovine_0.5by0.5.tif")
  }
  production <- as.data.frame(raster(input_file), xy = TRUE)
  column <- paste0(food, "_2020")
  if (food == "bovine" && !column %in% names(production)) column <- "Bovine_2020"
  stopifnot(column %in% names(production))
  if (i == 1L) {
    point_production <- production
    colnames(point_production) <- c("x", "y", "prod")
    production_values <- matrix(NA_real_, nrow(production), length(food_types))
  }
  production_values[, i] <- production[[column]]
}
point_production$prod <- rowSums(production_values, na.rm = TRUE)
point_production$prod <- ifelse(point_production$prod == 0, NA, point_production$prod)
point_production <- rast(na.omit(point_production))
plot(point_production)
writeRaster(point_production, file.path(folder, "calib_2020_point_production.tif"), overwrite = TRUE)
