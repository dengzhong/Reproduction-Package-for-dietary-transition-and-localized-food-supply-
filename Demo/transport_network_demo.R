# Reviewer #5 / Comment 1: reproducible numerical demonstration
# 100 x 100 network | realistic corridor layout | 20 major shipping routes
# Requirements: install.packages(c("igraph", "ggplot2", "Matrix"))
# The spatial patterns are hypothetical, not observed geography.

library(igraph)
library(ggplot2)

set.seed(20261010)
n <- 100L
cells <- expand.grid(x = seq_len(n), y = seq_len(n))
cells$id <- seq_len(nrow(cells))  # id = x + (y - 1) * n
id_at <- function(x, y) as.integer(x + (y - 1L) * n)

# 1. Zones: central 50 x 25 sea; default sea is penalized/non-route.
in_sea <- with(cells, x >= 26 & x <= 75 & y >= 38 & y <= 62)
cells$type <- ifelse(in_sea, "Off-route ocean", "Ordinary land")

# Convert a chain of waypoints to grid cells; 8-connected between endpoints.
polyline_ids <- function(waypoints) {
  stopifnot(is.matrix(waypoints), ncol(waypoints) == 2)
  selected <- integer()
  for (k in seq_len(nrow(waypoints) - 1L)) {
    a <- waypoints[k, ]; b <- waypoints[k + 1L, ]
    ns <- max(abs(b - a)) + 1L
    xx <- round(seq(a[1], b[1], length.out = ns))
    yy <- round(seq(a[2], b[2], length.out = ns))
    valid <- xx >= 1 & xx <= n & yy >= 1 & yy <= n
    selected <- c(selected, id_at(xx[valid], yy[valid]))
  }
  unique(selected)
}

paint <- function(points, type, only_sea = FALSE, only_land = FALSE, width = 0L) {
  idx <- polyline_ids(matrix(unlist(points), ncol = 2, byrow = TRUE))
  if (width > 0L) {
    xy <- cells[idx, c("x", "y")]
    offsets <- expand.grid(dx = -width:width, dy = -width:width)
    idx <- unique(unlist(lapply(seq_len(nrow(offsets)), function(j) {
      x <- xy$x + offsets$dx[j]; y <- xy$y + offsets$dy[j]
      ok <- x >= 1 & x <= n & y >= 1 & y <= n
      id_at(x[ok], y[ok])
    })))
  }
  if (only_sea) idx <- idx[in_sea[idx]]
  if (only_land) idx <- idx[!in_sea[idx]]
  cells$type[idx] <<- type
  invisible(idx)
}

# 2. Land transport network: structured, intersecting corridors.
# Ordinary land speed=15, cost=15. Rail speed=24, cost=3.
# Highway speed=22, cost=25 (following the original reclassification rule).
# Major trunk expressways and circumferential roads.
highways <- list(
  list(c(8, 10), c(22, 18), c(25, 35), c(24, 65), c(23, 87), c(38, 94)),
  list(c(92, 9), c(83, 20), c(78, 34), c(77, 65), c(79, 84), c(94, 94)),
  list(c(5, 27), c(25, 29), c(42, 31), c(74, 30), c(96, 26)),
  list(c(5, 73), c(23, 70), c(47, 68), c(75, 69), c(96, 75)),
  list(c(12, 7), c(35, 14), c(58, 15), c(84, 12), c(97, 16)),
  list(c(10, 90), c(32, 85), c(52, 89), c(80, 88), c(97, 91))
)
for (p in highways) paint(p, "Highway", only_land = TRUE, width = 1L)

# Railway trunks cross land in several directions. Rail takes priority at crossings.
railways <- list(
  list(c(3, 20), c(18, 24), c(25, 28), c(48, 34), c(75, 33), c(95, 40)),
  list(c(4, 82), c(17, 75), c(24, 67), c(47, 66), c(76, 66), c(97, 58)),
  list(c(15, 4), c(17, 25), c(20, 37), c(21, 63), c(19, 82), c(21, 98)),
  list(c(91, 4), c(86, 26), c(81, 37), c(80, 63), c(86, 85), c(92, 98)),
  list(c(8, 8), c(31, 21), c(45, 34), c(69, 36), c(92, 52)),
  list(c(7, 96), c(28, 81), c(42, 67), c(65, 64), c(96, 42))
)
for (p in railways) paint(p, "Railway", only_land = TRUE, width = 0L)

# 3. Central sea: 20 shipping routes with realistic trunk/hub structure.
# Ships can use only marked lanes; all remaining ocean cells are penalized.
# Routes share two major marine hubs and a central shipping trunk.
shipping_routes <- vector("list", 20L)
shipping_cells <- vector("list", 20L)

# Twelve west-east service routes, merging into two common navigational hubs.
west_y <- c(39, 41, 43, 45, 47, 49, 51, 53, 55, 57, 59, 61)
east_y <- c(60, 58, 56, 54, 52, 50, 48, 46, 44, 42, 40, 39)
for (k in 1:12) {
  p <- list(c(26, west_y[k]), c(37, 47), c(49, 50),
            c(58, 50), c(66, 53), c(75, east_y[k]))
  shipping_routes[[k]] <- p
  shipping_cells[[k]] <- paint(p, "Shipping lane", only_sea = TRUE)
}

# Eight north-south services, connecting ports to the same marine trunk.
north_x <- c(29, 35, 41, 47, 53, 59, 65, 72)
south_x <- c(72, 65, 59, 53, 47, 41, 35, 29)
for (k in 1:8) {
  p <- list(c(north_x[k], 62), c(43, 55), c(49, 50),
            c(58, 50), c(63, 45), c(south_x[k], 38))
  shipping_routes[[12 + k]] <- p
  shipping_cells[[12 + k]] <- paint(p, "Shipping lane", only_sea = TRUE)
}
stopifnot(length(shipping_routes) == 20L,
          sum(in_sea) == 50L * 25L,
          any(in_sea & cells$type == "Off-route ocean"))

# Optional land obstacles; penalize a few discontinuous non-transport areas.
# These are not the 10% ocean penalty: ALL off-route sea cells remain penalized.
land_obstacles <- list(
  c(35, 15, 43, 24), c(57, 75, 64, 84), c(84, 45, 92, 55)
)
for (a in land_obstacles) {
  idx <- which(!in_sea & cells$x >= a[1] & cells$x <= a[3] &
                 cells$y >= a[2] & cells$y <= a[4] &
                 cells$type == "Ordinary land")
  cells$type[idx] <- "Penalty land"
}

# 4. Speed and cost classifications (hypothetical network).
# Speed and cost arrays are indexed by cell ID; use the SOURCE cell for
# the weight of each directed 8-neighbor edge, exactly as in the paper's code.
# 5->100, 19->1, 24->3, >=20 (except 24)->25, 15->15.
speed_by_type <- c("Ordinary land" = 15, "Highway" = 22,
                   "Railway" = 24, "Shipping lane" = 19,
                   "Off-route ocean" = 5, "Penalty land" = 5)
cells$speed <- unname(speed_by_type[cells$type])
cells$cost <- ifelse(cells$speed == 24, 3,
              ifelse(cells$speed >= 20, 25,
              ifelse(cells$speed == 5, 100,
              ifelse(cells$speed == 19, 1,
                     cells$speed))))
cell_values <- cells$speed
cost_values <- cells$cost

# Cell-level values for exporting the raster and plotting the resistance.
# These reproduce the exact edge-level formula below at each source cell.
cells$times <- 1 / cell_values
cells$resistance <- 0.5 * ((cells$times - 1/100) / (1/5 - 1/100)) +
                    0.5 * ((cost_values - 1) / (25 - 1))
stopifnot(all(is.finite(cells$resistance)),
          all(cells$resistance >= 0),
          all(cells$cost[cells$type == "Off-route ocean"] == 100),
          all(cells$cost[cells$type == "Shipping lane"] == 1),
          isTRUE(all.equal((100 - 1) / (25 - 1), 4.125)))

# 5. Queen adjacency: directed eight-neighbor cell pairs (source, target).
neighbor_deltas <- expand.grid(dx = -1:1, dy = -1:1)
neighbor_deltas <- subset(neighbor_deltas, dx != 0 | dy != 0)
neighbors <- do.call(rbind, lapply(seq_len(nrow(neighbor_deltas)), function(k) {
  xx <- cells$x + neighbor_deltas$dx[k]
  yy <- cells$y + neighbor_deltas$dy[k]
  keep <- xx >= 1 & xx <= n & yy >= 1 & yy <= n
  cbind(cells$id[keep], id_at(xx[keep], yy[keep]))
}))
colnames(neighbors) <- c("from", "to")
stopifnot(nrow(neighbors) == 78804L)

# A 10,000 x 10,000 dense adjacency matrix requires ~800 MB.
# Using a sparse Matrix preserves precisely the SAME indexed assignment and
# graph_from_adjacency_matrix() semantics without allocating empty entries.
adj_matrix <- Matrix::sparseMatrix(
  i = neighbors[, 1], j = neighbors[, 2],
  x = rep(1, nrow(neighbors)),
  dims = c(nrow(cells), nrow(cells))
)

# -----------------------------------------------------------------------------
# EXACT resistance and adjacency-weight expressions supplied by the authors.
# For each adjacent cell pair, distance and distance-cost multiplier are both 1.
# The source cell (neighbors[, 1]) determines time and cost, not the destination.
# -----------------------------------------------------------------------------
distances <- rep(1, nrow(neighbors))
times <- (distances / cell_values[neighbors[, 1]])
distances_cost <- rep(1, nrow(neighbors))
costs <- (distances_cost * cost_values[neighbors[, 1]])
normalized_time <- (times-1/100) / (1/5 - 1/100)
normalized_cost <- (costs-1) / (25 - 1)
weight_result <- 0.5*normalized_time + 0.5*normalized_cost
adj_matrix[cbind(neighbors[, 1], neighbors[, 2])] <- weight_result
g <- graph_from_adjacency_matrix(adj_matrix, mode = "directed", weighted = TRUE)

stopifnot(igraph::vcount(g) == nrow(cells),
          igraph::ecount(g) == nrow(neighbors),
          max(abs(weight_result - cells$resistance[neighbors[, 1]])) < 1e-12)
# 'distances' above is a numeric vector, so call igraph::distances explicitly
# later when verifying shortest-path totals.

# 6. One origin, three destinations, same graph for every route.
origin <- id_at(10, 15)
destinations <- c(D1 = id_at(91, 21), D2 = id_at(90, 88), D3 = id_at(13, 90))
route_colors <- c(D1 = "#0072B2", D2 = "#009E73", D3 = "#CC79A7")
route_paths <- list()
results <- list()

for (nm in names(destinations)) {
  dest <- destinations[[nm]]
  path_v <- shortest_paths(g, from = origin,
                           to = dest,
                           weights = E(g)$weight, mode = "out")$vpath[[1]]
  path_ids <- as.integer(as_ids(path_v))
  stopifnot(length(path_ids) >= 2L)
  calculated <- as.numeric(igraph::distances(g, v = origin,
                                              to = dest,
                                              weights = E(g)$weight, mode = "out"))
  # Independent sum of SOURCE-cell resistance on every traversed edge.
  summed <- sum(cells$resistance[head(path_ids, -1L)])
  stopifnot(isTRUE(all.equal(calculated, summed, tolerance = 1e-9)))
  route_paths[[nm]] <- transform(cells[path_ids, c("x", "y", "type", "resistance")],
                                 route = nm, path_order = seq_along(path_ids))
  results[[nm]] <- data.frame(route = nm, origin = origin, destination = dest,
                              number_of_cells = length(path_ids),
                              cumulative_resistance = calculated,
                              manually_summed_resistance = summed,
                              check_absolute_error = abs(calculated - summed),
                              ocean_route_cells = sum(cells$type[path_ids] == "Shipping lane"),
                              penalty_cells = sum(cells$cost[path_ids] == 100))
}
result_table <- do.call(rbind, results)
path_table <- do.call(rbind, route_paths)

# 7. Monotonicity checks at fixed travel time and at fixed cost.
test_cost <- c(1, 3, 15, 25, 100)
test_cost_resistance <- 0.5 * ((1/19 - 1/100)/(1/5 - 1/100)) +
                        0.5 * ((test_cost - 1)/(25 - 1))
stopifnot(all(diff(test_cost_resistance) > 0))
test_times <- c(1/100, 1/24, 1/19, 1/15, 1/5)
test_time_resistance <- 0.5 * ((test_times - 1/100)/(1/5 - 1/100)) +
                        0.5 * ((15 - 1)/(25 - 1))
stopifnot(all(diff(test_time_resistance) > 0))



# 8. Figures and machine-readable outputs.
# This section only modifies the visualization. All network construction,
# cost/travel-time definitions, resistance calculation, adjacency weighting,
# and shortest-path calculations above remain unchanged.
# Layout:
# a = transportation network classes
# b = transportation cost (paper-defined range: 1 to 25)
# c = travel time = 1/speed (paper-defined range: 1/100 to 1/5)
# d = shortest paths
# Requires: install.packages(c("patchwork"))

out_dir <- "Demo"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(cells, file.path(out_dir, "grid_speed_cost_resistance.csv"), row.names = FALSE)
write.csv(result_table, file.path(out_dir, "route_validation.csv"), row.names = FALSE)
write.csv(path_table, file.path(out_dir, "three_shortest_paths.csv"), row.names = FALSE)
write.csv(data.frame(shipping_route = rep(seq_along(shipping_cells), lengths(shipping_cells)),
                     cell_id = unlist(shipping_cells)),
          file.path(out_dir, "twenty_shipping_routes.csv"), row.names = FALSE)

library(patchwork)

cells$display_resistance <- pmin(cells$resistance, 1)
cells$travel_time <- 1 / cells$speed

locations <- data.frame(
  x = c(10, 91, 90, 13),
  y = c(15, 21, 88, 90),
  label = c("O", "D1", "D2", "D3")
)

class_order <- c("Ordinary land", "Highway", "Railway",
                 "Shipping lane", "Off-route ocean", "Penalty land")
category_colors <- c("Ordinary land" = "#e2e2de", "Highway" = "#efb663",
                     "Railway" = "#3f7097", "Shipping lane" = "#2da4a1",
                     "Off-route ocean" = "#d2e6ed", "Penalty land" = "#c8807f")
category_labels <- c("Ordinary land", "Highway", "Railway",
                     "Shipping lane", "Off-route ocean", "High-cost land")

route_label_values <- setNames(result_table$cumulative_resistance, result_table$route)
route_labels <- c(
  D1 = sprintf("O–D1  %.2f", route_label_values["D1"]),
  D2 = sprintf("O–D2  %.2f", route_label_values["D2"]),
  D3 = sprintf("O–D3  %.2f", route_label_values["D3"])
)

base_theme <- theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_blank(),
    axis.title = element_blank(),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 9),
    plot.tag = element_text(face = "bold", size = 18),
    plot.tag.position = c(0.02, 0.98),
    axis.text = element_text(size = 8)
  )

coord_map <- coord_fixed(xlim = c(0.5, 100.5), ylim = c(0.5, 100.5), expand = FALSE)

# Exact paper-defined plotting ranges
cost_limits <- c(1, 25)
cost_breaks <- c(1, 3, 15, 25)
travel_limits <- c(1/100, 1/5)
travel_breaks <- c(1/100, 1/24, 1/19, 1/15, 1/5)
travel_labels <- c("1/100", "1/24", "1/19", "1/15", "1/5")

p_a <- ggplot(cells, aes(x, y)) +
  geom_raster(aes(fill = factor(type, levels = class_order))) +
  scale_fill_manual(values = category_colors,
                    breaks = class_order,
                    labels = category_labels,
                    name = NULL) +
  coord_map +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE,
                             override.aes = list(color = NA))) +
  base_theme +
  theme(legend.position = "bottom")

# Cost shown within the paper-defined normalization range 1–25.
# Values above 25 (e.g., penalty cells = 100) are squished to the upper limit
# for display only, while the model calculation above remains unchanged.
p_b <- ggplot(cells, aes(x, y)) +
  geom_raster(aes(fill = cost)) +
  scale_fill_gradientn(
    colors = c("#fffce8", "#f6d27b", "#ec8f45", "#bf3b2c"),
    limits = cost_limits,
    breaks = cost_breaks,
    labels = as.character(cost_breaks),
    oob = scales::squish,
    name = "Cost"
  ) +
  coord_map +
  base_theme +
  theme(legend.position = "right")

# Travel time shown within the paper-defined normalization range 1/100–1/5.
p_c <- ggplot(cells, aes(x, y)) +
  geom_raster(aes(fill = travel_time)) +
  scale_fill_gradientn(
    colors = c("#f7fbff", "#c6dbef", "#6baed6", "#2171b5", "#08306b"),
    limits = travel_limits,
    breaks = travel_breaks,
    labels = travel_labels,
    oob = scales::squish,
    name = "Travel time"
  ) +
  coord_map +
  base_theme +
  theme(legend.position = "right")

# Panel d is simplified to the route map only.
p_d <- ggplot(cells, aes(x, y)) +
  geom_raster(aes(fill = display_resistance)) +
  geom_path(data = path_table,
            aes(x, y, color = route, group = route),
            linewidth = 1.0, inherit.aes = FALSE) +
  geom_point(data = locations, aes(x, y), inherit.aes = FALSE,
             shape = 21, fill = "white", color = "black", size = 3.0, stroke = 0.9) +
  geom_text(data = locations, aes(x, y, label = label), inherit.aes = FALSE,
            fontface = "bold", size = 3.7,
            nudge_x = c(-2.2, 2.0, 2.2, -2.2),
            nudge_y = c(-2.2, -2.2, 2.0, 2.0)) +
  scale_fill_gradientn(
    colors = c("#fffce8", "#f7d998", "#eda46b", "#cf6a59", "#8f1d3c"),
    limits = c(0, 1),
    guide = "none"
  ) +
  scale_color_manual(values = route_colors,
                     breaks = c("D1", "D2", "D3"),
                     labels = route_labels[c("D1", "D2", "D3")],
                     name = NULL) +
  coord_map +
  base_theme +
  theme(legend.position = "bottom")

layout_design <- "
AB
CD
"

combined_plot <- (p_a + p_b + p_c + p_d) +
  plot_layout(design = layout_design, widths = c(1, 1), heights = c(1, 1.08), guides = "keep") +
  plot_annotation(tag_levels = 'a')

ggsave(file.path(out_dir, "Supplementary_Figure_X_4panel_paper_ranges.png"), combined_plot,
       width = 13.5, height = 12.5, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Supplementary_Figure_X_4panel_paper_ranges.pdf"), combined_plot,
       width = 13.5, height = 12.5, bg = "white")

# Optional individual panels.
ggsave(file.path(out_dir, "panel_a_transport_network.png"), p_a, width = 6.2, height = 5.8, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "panel_b_cost_paper_range.png"), p_b, width = 6.2, height = 5.8, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "panel_c_travel_time_paper_range.png"), p_c, width = 6.2, height = 5.8, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "panel_d_routes.png"), p_d, width = 8.0, height = 6.2, dpi = 300, bg = "white")

print(result_table, row.names = FALSE)
cat("4-panel figure saved to: ", out_dir, "\n", sep = "")
cat("Main outputs: Supplementary_Figure_X_4panel_paper_ranges.png and .pdf\n")
