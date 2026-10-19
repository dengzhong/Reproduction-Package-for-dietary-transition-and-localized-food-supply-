library(terra)
library(raster)

folder <- "G:/Foodshed/0.5by0.5"
output_dir <- file.path(folder, "EAT_feed_demand")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
food_types <- c("Bovine", "milk", "pig", "poultry")
demand_ratio <- numeric(length(food_types))
for (i in seq_along(food_types)) {
  filename <- paste0(food_types[i], "_demand_0.5by0.5_select.tif")
  eat <- as.data.frame(raster(file.path(folder, "EAT_food_demand", filename)), xy = TRUE)
  basic <- as.data.frame(raster(file.path(folder, "basic_food_demand", filename)), xy = TRUE)
  demand_ratio[i] <- sum(eat[, 3], na.rm = TRUE) / sum(basic[, 3], na.rm = TRUE)
}

livestock <- c("bvmeat", "bvmilk", "pig", "poultry", "sgmeat", "sgmilk")
for (feed_type in c("Crop", "Oil")) {
  total_name <- if (feed_type == "Crop") "crop_feed" else "Oil_feed"
  total <- as.data.frame(raster(file.path(folder, "basic_feed_demand", paste0(total_name, "_.tif"))), xy = TRUE)
  feed <- vector("list", length(livestock))
  for (i in seq_along(livestock)) {
    column <- paste0(feed_type, "_feed_", livestock[i])
    data <- as.data.frame(raster(file.path(folder, "basic_feed_demand", paste0(column, "_.tif"))), xy = TRUE)
    feed[[i]] <- data[[column]]
  }
  adjusted <- cbind(
    rowSums(cbind(feed[[1]], feed[[5]]), na.rm = TRUE) * demand_ratio[1],
    rowSums(cbind(feed[[2]], feed[[6]]), na.rm = TRUE) * demand_ratio[2],
    feed[[3]] * demand_ratio[3],
    feed[[4]] * demand_ratio[4]
  )
  total[, 3] <- rowSums(adjusted, na.rm = TRUE)
  feed_eat <- rast(total)
  feed_eat <- ifel(feed_eat == 0, NA, feed_eat)
  plot(feed_eat)
  filename <- if (feed_type == "Crop") "crop_feed_eat.tif" else "Oil_feed_eat.tif"
  writeRaster(feed_eat, file.path(output_dir, filename))
}
