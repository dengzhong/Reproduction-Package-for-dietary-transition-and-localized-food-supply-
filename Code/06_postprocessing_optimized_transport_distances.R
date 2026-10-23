library(terra)
library(raster)
library(igraph)
library(geosphere)
library(Matrix)
library(dplyr)
library(tidyr)
library(pbapply)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
partitions_to_run <- NULL
combine_results <- TRUE
output_dir <- "Output/transport_paths"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
source_all <- readRDS("Output/GAMS/source_all.rds")
stopifnot(nrow(source_all) > 0, all(c("from", "to_list") %in% names(source_all)))

combined_speed <- rast('Output/transport/alltransport_speed_new.tif')
combined_speed <- ifel(is.na(combined_speed), 10, combined_speed)
combined_costbytime <- ifel(combined_speed == 24, 3,
                            ifel(combined_speed >= 20, 25,
                                 ifel(combined_speed == 5, 100,
                                      ifel(combined_speed == 19, 1,
                                           ifel(combined_speed == 10, 100, combined_speed)))))
combined_emissions <- ifel(combined_speed == 24, 22.7,
                           ifel(combined_speed >= 20, 119.7,
                                ifel(combined_speed == 5, 1,
                                     ifel(combined_speed == 19, 12.1,
                                          ifel(combined_speed == 10, 12.1, combined_speed)))))
emission_factors <- as.vector(values(combined_emissions))
transport_types <- c("walk", "sea", "rail", "road")[match(emission_factors, c(1, 12.1, 22.7, 119.7))]
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
rm(adj_matrix, neighbors, cell_values, cost_values, distances, times, distances_cost,
   costs, normalized_time, normalized_cost, weight_result, combined_emissions, combined_costbytime)
gc()

point_demand <- raster::raster("Output/0.5by0.5/calib_2020_population_0.5by0.5.tif") %>%
  as.data.frame(xy = TRUE) %>% na.omit() %>% filter(pop_WB_2020 >= 500)
point_production <- raster::raster("Output/0.5by0.5/calib_2020_point_production.tif") %>%
  as.data.frame(xy = TRUE) %>% na.omit() %>% filter(prod >= 0)
start_index <- terra::cellFromXY(combined_speed, point_production[, c("x", "y")])
demand_index <- terra::cellFromXY(combined_speed, point_demand[, c("x", "y")])
all_types <- c("road", "rail", "sea", "walk")

calculate_distances <- function(start_idx, demand_idx) {
  paths <- shortest_paths(g, from = start_idx, to = demand_idx, weights = E(g)$weight)$vpath
  result <- vector("list", length(paths))
  for (j in seq_along(paths)) {
    cells <- as.integer(paths[[j]])
    if (!length(cells)) stop("No path from ", start_idx, " to ", demand_idx[j])
    coords <- terra::xyFromCell(combined_speed, cells)
    if (length(cells) > 1L) {
      segments <- data.frame(
        type = transport_types[cells[-1L]],
        factor = emission_factors[cells[-1L]],
        distance = geosphere::distHaversine(coords[-nrow(coords), , drop = FALSE],
                                           coords[-1L, , drop = FALSE]) / 1000)
    } else {
      segments <- data.frame(type = transport_types[cells], factor = emission_factors[cells], distance = 0)
    }
    if (anyNA(segments)) stop("Missing transport type, factor or distance on path.")
    totals <- segments %>% group_by(type) %>%
      summarise(emissions = sum(factor * distance), distance = sum(distance), .groups = "drop") %>%
      complete(type = all_types, fill = list(emissions = 0, distance = 0))
    result[[j]] <- data.frame(from = start_idx, to = demand_idx[j], totals)
  }
  bind_rows(result)
}

first <- seq.int(1L, nrow(source_all), by = 10000L)
last <- pmin(first + 9999L, nrow(source_all))
files <- file.path(output_dir, sprintf("distance_by_emissions_by_type_bau(%d-%d).rds", first, last))
if (is.null(partitions_to_run)) partitions_to_run <- seq_along(first)
stopifnot(length(partitions_to_run) > 0L, !anyNA(partitions_to_run),
          !anyDuplicated(partitions_to_run), all(partitions_to_run %in% seq_along(first)))
for (part in partitions_to_run) {
  result <- pblapply(seq.int(first[part], last[part]), function(i) {
    calculate_distances(source_all$from[i], unlist(source_all$to_list[i]))
  })
  distance_all <- bind_rows(result)
  distance_all$x <- match(distance_all$from, start_index)
  distance_all$y <- match(distance_all$to, demand_index)
  saveRDS(distance_all, files[part])
  rm(result, distance_all)
  gc()
}
if (combine_results) {
  if (!all(file.exists(files))) stop("Run all partitions before combining results.")
  saveRDS(bind_rows(lapply(files, readRDS)), file.path(output_dir, "bau_emission_type.rds"))
}
