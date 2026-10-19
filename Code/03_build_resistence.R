library(terra)
library(raster)
library(dplyr)
library(igraph)
library(geosphere)
library(Matrix)
library(pbapply)
library(rhdf5)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/03_build_resistence.pdf")

partitions_to_run <- 1:9
output_dir <- "Output/distances"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("Output/transport", recursive = TRUE, showWarnings = FALSE)
partitions <- data.frame(
  first = c(1L, 5001L, 10001L, 15001L, 20001L, 25001L, 30001L, 35001L, 40001L),
  last = c(5000L, 10000L, 15000L, 20000L, 25000L, 30000L, 35000L, 40000L, 45808L),
  dataset = paste0("distance_all", 1:9)
)
stopifnot(length(partitions_to_run) > 0L, !anyNA(partitions_to_run),
          !anyDuplicated(partitions_to_run), all(partitions_to_run %in% seq_len(nrow(partitions))))
for (part in partitions_to_run) {
  h5file <- file.path(output_dir, paste0("short_Harvdis_production_demand_", partitions$first[part], "-", partitions$last[part], ".h5"))
  if (file.exists(h5file)) stop("Output already exists: ", h5file)
}

# 1. Prepare transport speed when missing.
if (!file.exists("Output/transport/alltransport_speed_new.tif")) {
  highways <- rast("Input/Other data/transport/GRIP4_density_tp1/grip4_tp1_dens_m_km2.asc")
  highways_speed <- highways
  values(highways_speed) <- ifelse(values(highways) > 0, 100, NA)
  plot(highways_speed)
  primaryroad <- rast("Input/Other data/transport/GRIP4_density_tp2/grip4_tp2_dens_m_km2.asc")
  primaryroad_speed <- primaryroad
  values(primaryroad_speed) <- ifelse(values(primaryroad) > 0, 80, NA)
  plot(primaryroad_speed)
  secondaryroad <- rast("Input/Other data/transport/GRIP4_density_tp3/grip4_tp3_dens_m_km2.asc")
  secondaryroad_speed <- secondaryroad
  values(secondaryroad_speed) <- ifelse(values(secondaryroad) > 0, 60, NA)
  plot(secondaryroad_speed)
  tertiaryroad <- rast("Input/Other data/transport/GRIP4_density_tp4/grip4_tp4_dens_m_km2.asc")
  tertiaryroad_speed <- tertiaryroad
  values(tertiaryroad_speed) <- ifelse(values(tertiaryroad) > 0, 20, NA)
  plot(tertiaryroad_speed)
  localroad <- rast("Input/Other data/transport/GRIP4_density_tp5/grip4_tp5_dens_m_km2.asc")
  localroad_speed <- localroad
  values(localroad_speed) <- ifelse(values(localroad) > 0, 20, NA)
  plot(localroad_speed)
  road_speed <- mosaic(highways_speed, primaryroad_speed, secondaryroad_speed, tertiaryroad_speed, localroad_speed,fun="max")
  plot(road_speed)
  road_speed_0.5deg <- aggregate(road_speed, fact = 6, fun = mean, na.rm = TRUE)
  plot(road_speed_0.5deg)
  writeRaster(road_speed_0.5deg,"Output/transport/road_speed_0.5deg.tif",overwrite = TRUE)
  railroad <- rast("Input/Other data/transport/railroad_0.5deg.tif")
  railroad <- terra::extend(railroad, terra::ext(-180, 180, -90, 90))
  ext(railroad) <- ext(highways)
  crs(railroad) <- crs(highways)
  railroad_speed <- railroad
  values(railroad_speed) <- ifelse(values(railroad) > 0, 24, NA)
  plot(railroad_speed)
  shiproad <- rast("Input/Other data/transport/shippingnew_0.5deg.tif")
  shiproad <- terra::extend(shiproad, terra::ext(-180, 180, -90, 90))
  ext(shiproad) <- ext(highways)
  crs(shiproad) <- crs(highways)
  shiproad_speed <- shiproad
  values(shiproad_speed) <- ifelse(values(shiproad) >=0, 19, NA)
  plot(shiproad_speed)
  highways_costbytime <- highways
  values(highways_costbytime) <- ifelse(values(highways) > 0, 25, NA)
  primaryroad_costbytime <- primaryroad
  values(primaryroad_costbytime) <- ifelse(values(primaryroad) > 0, 25, NA)
  secondaryroad_costbytime <- secondaryroad
  values(secondaryroad_costbytime) <- ifelse(values(secondaryroad) > 0, 25, NA)
  tertiaryroad_costbytime <- tertiaryroad
  values(tertiaryroad_costbytime) <- ifelse(values(tertiaryroad) > 0, 25, NA)
  localroad_costbytime <- localroad
  values(localroad_costbytime) <- ifelse(values(localroad) > 0, 25, NA)
  road_costbytime <- road_speed_0.5deg
  values(road_costbytime) <- ifelse(values(road_speed_0.5deg) > 0, 25, NA)
  plot(road_costbytime)
  railroad_costbytime <- railroad
  values(railroad_costbytime) <- ifelse(values(railroad) > 0, 3, NA)
  plot(railroad_costbytime)
  shiproad_costbytime <- shiproad
  values(shiproad_costbytime) <- ifelse(values(shiproad) >=0, 1, NA)
  plot(shiproad_costbytime)
  combined_costbytime <- mosaic(road_costbytime, railroad_costbytime, shiproad_costbytime, fun = "min")
  road_mask <- classify(combined_costbytime, rcl = matrix(c(25, 25, 1, -Inf, 24, NA, 26, Inf, NA), ncol = 3, byrow = TRUE))
  ship_mask <- classify(combined_costbytime, rcl = matrix(c(1, 1, 1, -Inf, 0, NA, 2, Inf, NA), ncol = 3, byrow = TRUE))
  rail_mask <- classify(combined_costbytime, rcl = matrix(c(3, 3, 1, -Inf, 2, NA, 4, Inf, NA), ncol = 3, byrow = TRUE))
  road_layer <- mask(road_speed_0.5deg,road_mask)
  rail_layer <- mask(railroad_speed,rail_mask)
  land_speed <- merge(road_layer,rail_layer)
  combined_speed <- mosaic(land_speed, shiproad_speed, fun = "max")
  plot(combined_speed, col = terrain.colors(100))
  road_fill <- mosaic(highways, primaryroad, secondaryroad, tertiaryroad, localroad,fun="max")
  road_fill <- aggregate(road_fill, fact = 6, fun = mean, na.rm = TRUE)
  values(road_fill) <- ifelse(values(road_fill) >= 0, 1, values(road_fill))
  plot(road_fill)
  land_mask <- !is.na(road_fill) | !is.na(railroad)
  combined_speed <- ifel(is.na(combined_speed) & land_mask, 5, combined_speed)
  combined_speed <- ifel(is.na(combined_speed), 10, combined_speed)
  plot(combined_speed)
    writeRaster(combined_speed, 'Output/transport/alltransport_speed_new.tif', overwrite = TRUE)
}

# 2. Build the weighted graph and select production and demand cells.
combined_speed <- rast('Output/transport/alltransport_speed_new.tif')
plot(combined_speed)
combined_speed <- ifel(is.na(combined_speed), 10, combined_speed)
combined_costbytime <- ifel(combined_speed == 24, 3,
                            ifel(combined_speed >= 20, 25,
                                 ifel(combined_speed == 5, 100,
                                      ifel(combined_speed == 19, 1,
                                           ifel(combined_speed == 10, 100, combined_speed)))))
plot(combined_speed)
plot(combined_costbytime, col = terrain.colors(100))
n_cells <- ncell(combined_speed)
adj_matrix <- sparseMatrix(i = integer(0), j = integer(0), x = numeric(0), dims = c(n_cells, n_cells))
cell_values <- values(combined_speed)
cost_values <- values(combined_costbytime)
neighbors <- adjacent(combined_speed, cells = 1:n_cells, directions = 8, pairs = TRUE)
distances <- rep(1, nrow(neighbors))
times <- (distances / cell_values[neighbors[, 1]])
distances_cost <- rep(1, nrow(neighbors))
costs <- (distances_cost * cost_values[neighbors[, 1]])
normalized_time <- (times-1/100) / (1/5 - 1/100)
normalized_cost <- (costs-1) / (25 - 1)
weight_result <- 0.5*normalized_time + 0.5*normalized_cost
adj_matrix[cbind(neighbors[, 1], neighbors[, 2])] <- weight_result
g <- graph_from_adjacency_matrix(adj_matrix, mode = "directed", weighted = TRUE)

rm(list = setdiff(ls(), c("g", "partitions", "partitions_to_run", "output_dir")))
gc()
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
allland <- rast('Output/transport/alltransport_speed_new.tif')
allland <- ifel(allland == 19, NA, allland)
plot(allland)
start_index <- cellFromXY(allland, point_production)
demand_index <- cellFromXY(allland, point_demand)
rm(point_demand, point_production)
gc()

calculate_distances <- function(start_idx) {
  shortest_path <- shortest_paths(g, from = start_idx, to = demand_index, weights = E(g)$weight)
  distance <- numeric(length(shortest_path$vpath))
  for (mm in seq_along(shortest_path$vpath)) {
    path_indices <- as.numeric(shortest_path$vpath[[mm]])
    path_coords <- xyFromCell(allland, path_indices)
    transport_distance <- if (nrow(path_coords) > 1) {
      sum(distHaversine(path_coords[1:(nrow(path_coords) - 1), ],
                        path_coords[2:nrow(path_coords), ]))
    } else {
      0
    }
    distance[mm] <- transport_distance / 1000
  }
  return(distance)
}

stopifnot(max(partitions$last[partitions_to_run]) <= length(start_index))

# 3. Compute and write each partition separately.
for (part in partitions_to_run) {
  first <- partitions$first[part]
  last <- partitions$last[part]
  dataset <- partitions$dataset[part]
  h5file <- file.path(output_dir, paste0("short_Harvdis_production_demand_", first, "-", last, ".h5"))
  message("Partition ", part, ": ", first, "-", last)
  result <- pblapply(start_index[first:last], calculate_distances)
  distance_matrix <- do.call(rbind, result)
  rm(result)
  h5createFile(h5file)
  chunk_size <- pmin(c(1000L, 1000L), dim(distance_matrix))
  h5createDataset(h5file, dataset, dims = dim(distance_matrix),
                  chunk = chunk_size, storage.mode = "double")
  for (i in seq(1L, nrow(distance_matrix), by = chunk_size[1])) {
    for (j in seq(1L, ncol(distance_matrix), by = chunk_size[2])) {
      rows <- i:min(i + chunk_size[1] - 1L, nrow(distance_matrix))
      cols <- j:min(j + chunk_size[2] - 1L, ncol(distance_matrix))
      h5write(distance_matrix[rows, cols, drop = FALSE], h5file, dataset, index = list(rows, cols))
    }
  }
  h5closeAll()
  rm(distance_matrix)
  gc()
}
