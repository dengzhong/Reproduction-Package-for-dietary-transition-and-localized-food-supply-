
library(igraph)
library(ggplot2)
library(patchwork)

out_dir <- "~/Desktop/Code availability/Demo"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Network setup
set.seed(20261010)
n <- 100L
cells <- expand.grid(x = seq_len(n), y = seq_len(n))
cells$id <- seq_len(nrow(cells))
id_at <- function(x, y) as.integer(x + (y - 1L) * n)

in_sea <- with(cells, x >= 26 & x <= 75 & y >= 38 & y <= 62)
cells$type <- ifelse(in_sea, "Off-route ocean", "Ordinary land")

polyline_ids <- function(waypoints) {
  selected <- integer()
  for (k in seq_len(nrow(waypoints) - 1L)) {
    a <- waypoints[k, ]
    b <- waypoints[k + 1L, ]
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
      x <- xy$x + offsets$dx[j]
      y <- xy$y + offsets$dy[j]
      ok <- x >= 1 & x <= n & y >= 1 & y <= n
      id_at(x[ok], y[ok])
    })))
  }
  
  if (only_sea) idx <- idx[in_sea[idx]]
  if (only_land) idx <- idx[!in_sea[idx]]
  cells$type[idx] <<- type
  invisible(idx)
}

# Transport corridors
highways <- list(
  list(c(8, 10), c(22, 18), c(25, 35), c(24, 65), c(23, 87), c(38, 94)),
  list(c(92, 9), c(83, 20), c(78, 34), c(77, 65), c(79, 84), c(94, 94)),
  list(c(5, 27), c(25, 29), c(42, 31), c(74, 30), c(96, 26)),
  list(c(5, 73), c(23, 70), c(47, 68), c(75, 69), c(96, 75)),
  list(c(12, 7), c(35, 14), c(58, 15), c(84, 12), c(97, 16)),
  list(c(10, 90), c(32, 85), c(52, 89), c(80, 88), c(97, 91))
)

for (p in highways) {
  paint(p, "Highway", only_land = TRUE, width = 1L)
}

railways <- list(
  list(c(3, 20), c(18, 24), c(25, 28), c(48, 34), c(75, 33), c(95, 40)),
  list(c(4, 82), c(17, 75), c(24, 67), c(47, 66), c(76, 66), c(97, 58)),
  list(c(15, 4), c(17, 25), c(20, 37), c(21, 63), c(19, 82), c(21, 98)),
  list(c(91, 4), c(86, 26), c(81, 37), c(80, 63), c(86, 85), c(92, 98)),
  list(c(8, 8), c(31, 21), c(45, 34), c(69, 36), c(92, 52)),
  list(c(7, 96), c(28, 81), c(42, 67), c(65, 64), c(96, 42))
)

for (p in railways) {
  paint(p, "Railway", only_land = TRUE)
}

shipping_routes <- vector("list", 20L)
shipping_cells <- vector("list", 20L)

west_y <- c(39, 41, 43, 45, 47, 49, 51, 53, 55, 57, 59, 61)
east_y <- c(60, 58, 56, 54, 52, 50, 48, 46, 44, 42, 40, 39)

for (k in 1:12) {
  p <- list(
    c(26, west_y[k]), c(37, 47), c(49, 50),
    c(58, 50), c(66, 53), c(75, east_y[k])
  )
  shipping_routes[[k]] <- p
  shipping_cells[[k]] <- paint(p, "Shipping lane", only_sea = TRUE)
}

north_x <- c(29, 35, 41, 47, 53, 59, 65, 72)
south_x <- c(72, 65, 59, 53, 47, 41, 35, 29)

for (k in 1:8) {
  p <- list(
    c(north_x[k], 62), c(43, 55), c(49, 50),
    c(58, 50), c(63, 45), c(south_x[k], 38)
  )
  shipping_routes[[12 + k]] <- p
  shipping_cells[[12 + k]] <- paint(p, "Shipping lane", only_sea = TRUE)
}

land_obstacles <- list(
  c(35, 15, 43, 24),
  c(57, 75, 64, 84),
  c(84, 45, 92, 55)
)

for (a in land_obstacles) {
  idx <- which(
    !in_sea &
      cells$x >= a[1] & cells$x <= a[3] &
      cells$y >= a[2] & cells$y <= a[4] &
      cells$type == "Ordinary land"
  )
  cells$type[idx] <- "Penalty land"
}

# Transport parameters
speed_by_type <- c(
  "Ordinary land" = 15,
  "Highway" = 22,
  "Railway" = 24,
  "Shipping lane" = 19,
  "Off-route ocean" = 5,
  "Penalty land" = 5
)

cells$speed <- unname(speed_by_type[cells$type])

cells$cost <- ifelse(cells$speed == 24, 3,
                     ifelse(cells$speed >= 20, 25,
                            ifelse(cells$speed == 5, 100,
                                   ifelse(cells$speed == 19, 1, cells$speed))))

cell_values <- cells$speed
cost_values <- cells$cost

cells$times <- 1 / cell_values
cells$resistance <- 0.5 * ((cells$times - 1/100) / (1/5 - 1/100)) +
  0.5 * ((cost_values - 1) / (25 - 1))

# Resistance and network graph
neighbor_deltas <- expand.grid(dx = -1:1, dy = -1:1)
neighbor_deltas <- subset(neighbor_deltas, dx != 0 | dy != 0)

neighbors <- do.call(rbind, lapply(seq_len(nrow(neighbor_deltas)), function(k) {
  xx <- cells$x + neighbor_deltas$dx[k]
  yy <- cells$y + neighbor_deltas$dy[k]
  keep <- xx >= 1 & xx <= n & yy >= 1 & yy <= n
  cbind(cells$id[keep], id_at(xx[keep], yy[keep]))
}))

adj_matrix <- Matrix::sparseMatrix(
  i = neighbors[, 1],
  j = neighbors[, 2],
  x = rep(1, nrow(neighbors)),
  dims = c(nrow(cells), nrow(cells))
)

distances <- rep(1, nrow(neighbors))
times <- distances / cell_values[neighbors[, 1]]
distances_cost <- rep(1, nrow(neighbors))
costs <- distances_cost * cost_values[neighbors[, 1]]

normalized_time <- (times - 1/100) / (1/5 - 1/100)
normalized_cost <- (costs - 1) / (25 - 1)
weight_result <- 0.5 * normalized_time + 0.5 * normalized_cost

adj_matrix[cbind(neighbors[, 1], neighbors[, 2])] <- weight_result
g <- graph_from_adjacency_matrix(adj_matrix, mode = "directed", weighted = TRUE)

stopifnot(
  vcount(g) == nrow(cells),
  ecount(g) == nrow(neighbors),
  max(abs(weight_result - cells$resistance[neighbors[, 1]])) < 1e-12
)

# Shortest paths
origin <- id_at(10, 15)

destinations <- c(
  D1 = id_at(91, 21),
  D2 = id_at(90, 88),
  D3 = id_at(13, 90)
)

route_colors <- c(
  D1 = "#0072B2",
  D2 = "#009E73",
  D3 = "#CC79A7"
)

route_paths <- list()
results <- list()

for (nm in names(destinations)) {
  dest <- destinations[[nm]]
  
  path_v <- shortest_paths(
    g, from = origin, to = dest,
    weights = E(g)$weight, mode = "out"
  )$vpath[[1]]
  
  path_ids <- as.integer(as_ids(path_v))
  
  calculated <- as.numeric(igraph::distances(
    g, v = origin, to = dest,
    weights = E(g)$weight, mode = "out"
  ))
  
  summed <- sum(cells$resistance[head(path_ids, -1L)])
  stopifnot(isTRUE(all.equal(calculated, summed, tolerance = 1e-9)))
  
  route_paths[[nm]] <- transform(
    cells[path_ids, c("x", "y", "type", "resistance")],
    route = nm,
    path_order = seq_along(path_ids)
  )
  
  results[[nm]] <- data.frame(
    route = nm,
    origin = origin,
    destination = dest,
    number_of_cells = length(path_ids),
    cumulative_resistance = calculated,
    manually_summed_resistance = summed,
    check_absolute_error = abs(calculated - summed),
    ocean_route_cells = sum(cells$type[path_ids] == "Shipping lane"),
    penalty_cells = sum(cells$cost[path_ids] == 100)
  )
}

result_table <- do.call(rbind, results)
path_table <- do.call(rbind, route_paths)

# Numerical checks
test_cost <- c(1, 3, 15, 25, 100)
test_cost_r <- 0.5 * ((1/19 - 1/100) / (1/5 - 1/100)) +
  0.5 * ((test_cost - 1) / (25 - 1))

test_times <- c(1/100, 1/24, 1/19, 1/15, 1/5)
test_time_r <- 0.5 * ((test_times - 1/100) / (1/5 - 1/100)) +
  0.5 * ((15 - 1) / (25 - 1))

stopifnot(
  all(diff(test_cost_r) > 0),
  all(diff(test_time_r) > 0)
)

# Data exports
write.csv(cells, file.path(out_dir, "grid_speed_cost_resistance.csv"), row.names = FALSE)
write.csv(result_table, file.path(out_dir, "route_validation.csv"), row.names = FALSE)
write.csv(path_table, file.path(out_dir, "three_shortest_paths.csv"), row.names = FALSE)

write.csv(
  data.frame(
    shipping_route = rep(seq_along(shipping_cells), lengths(shipping_cells)),
    cell_id = unlist(shipping_cells)
  ),
  file.path(out_dir, "twenty_shipping_routes.csv"),
  row.names = FALSE
)

# Figure contract: synthetic network demonstration, not empirical geography.
# Four matched maps link transport classes to cost, time and least-cost routes.
# All 10,000 cells and all three paths are retained; no display clipping.
# R-only exports: 183 x 190 mm, editable PDF/SVG and 600 dpi PNG.
# Figure panels
cells$travel_time <- 1 / cells$speed
locations <- data.frame(
  x = c(10, 91, 90, 13), y = c(15, 21, 88, 90),
  label = c("O", "D1", "D2", "D3"),
  label_x = c(7, 94, 93, 10), label_y = c(10, 16, 93, 95)
)
class_order <- c("Ordinary land", "Highway", "Railway",
                 "Shipping lane", "Off-route ocean", "Penalty land")
category_colors <- c("Ordinary land" = "#ECEDE9", "Highway" = "#D9AD6C",
                     "Railway" = "#597894", "Shipping lane" = "#479C99",
                     "Off-route ocean" = "#D5E7EB", "Penalty land" = "#B87D79")
category_labels <- c("Ordinary land", "Highway", "Railway", "Shipping lane",
                     "Off-route ocean", "High-cost land")
base_theme <- theme_minimal(base_size = 7, base_family = "Arial") +
  theme(
    panel.grid = element_blank(), axis.title = element_blank(),
    axis.text = element_text(size = 12, colour = "#616970"),
    axis.ticks = element_blank(),
    panel.border = element_rect(fill = NA, colour = "#CBD0D3", linewidth = 0.25),
    plot.title = element_text(size = 12, face = "bold", colour = "black",
                              margin = margin(b = 5)),
    plot.tag = element_text(size = 9, face = "bold"),
    legend.position = "bottom", legend.title = element_blank(),
    legend.text = element_text(size = 12),
    legend.key.size = grid::unit(2.5, "mm"),
    legend.spacing.x = grid::unit(1, "mm"),
    legend.margin = margin(t = 3),
    plot.margin = margin(5, 5, 3, 5)
  )
coord_map <- coord_fixed(xlim = c(0.5, 100.5), ylim = c(0.5, 100.5), expand = FALSE)
map_base <- function(title) {
  ggplot(cells, aes(x, y)) + coord_map +
    scale_x_continuous(breaks = c(25, 50, 75, 100)) +
    scale_y_continuous(breaks = c(25, 50, 75, 100)) +
    labs(title = title) + base_theme
}
bar_guide <- function() guide_colourbar(
  direction = "horizontal", barwidth = grid::unit(48, "mm"),
  barheight = grid::unit(2.2, "mm"),
  ticks.colour = "#FFFFFF", frame.colour = "black"
)
p_a <- map_base("Transport network") +
  geom_raster(aes(fill = factor(type, levels = class_order))) +
  scale_fill_manual(values = category_colors, breaks = class_order,
                    labels = category_labels) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))
p_b <- map_base("Transport cost") +
  geom_raster(aes(fill = cost)) +
  scale_fill_gradientn(
    colours = c("#FCF6E9", "#E5BE83", "#BC7952", "#77433C"),
    limits = c(1, 100), breaks = c(1, 25, 50, 75, 100), guide = bar_guide()
  )
p_c <- map_base("Travel time per unit distance") +
  geom_raster(aes(fill = travel_time)) +
  scale_fill_gradientn(
    colours = c("#F0F6FA", "#BED6E3", "#719DBA", "#335D7E"),
    limits = c(0.01, 0.2), breaks = c(0.01, 0.05, 0.10, 0.15, 0.20),
    labels = c("0.01", "0.05", "0.10", "0.15", "0.20"), guide = bar_guide()
  )
# White route halos separate paths from the complete resistance field.
p_d <- map_base("Resistance and least-cost paths") +
  geom_raster(aes(fill = resistance)) +
  scale_fill_gradientn(
    colours = c("#FAFAFA", "#E4D0CE", "#CEA6A3", "#B87D79"),
    limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1),
    guide = bar_guide()
  ) +
  geom_path(data = path_table, aes(x, y, group = route),
            inherit.aes = FALSE, colour = "white", linewidth = 1.05) +
  geom_path(data = path_table, aes(x, y, colour = route, group = route,
                                 linetype = route),
            inherit.aes = FALSE, linewidth = 0.55) +
  geom_point(data = locations, aes(x, y), inherit.aes = FALSE,
             shape = 21, fill = "white", colour = "#25333D", size = 3, stroke = 0.45) +
  geom_text(data = locations, aes(label_x, label_y, label = label),
            inherit.aes = FALSE, fontface = "bold", family = "Arial", size = 3) +
  scale_colour_manual(values = route_colors, guide = "none") +
  scale_linetype_manual(values = c(D1 = "solid", D2 = "longdash", D3 = "dotdash"),
                        guide = "none")

# Equal map geometry; bottom legend space is reserved consistently in every panel.
combined_plot <- (p_a + p_b + p_c + p_d) +
  plot_layout(ncol = 2, widths = c(1, 1), heights = c(1, 1)) +
  plot_annotation(
    tag_levels = "a",
    caption = paste0(
      "Synthetic 100 x 100 grid; eight-neighbour directed network.\n",
      "O: origin; D1-D3: destinations. Cumulative resistance: ",
      paste(sprintf("O-D%s = %.2f", sub("D", "", result_table$route),
                    result_table$cumulative_resistance), collapse = "; "), "."
    ),
    theme = theme(plot.caption = element_text(size = 12, family = "Arial",
                                              colour = "black", hjust = 0,
                                              margin = margin(t = 6)))
  )

# Publication-size output with editable text in both vector formats.
width_mm <- 183
height_mm <- 190
figure_prefix <- file.path(out_dir, "Supplementary_Figure_X_4panel")
ggsave(paste0(figure_prefix, ".png"), combined_plot,
       width = width_mm, height = height_mm, units = "mm", dpi = 600, bg = "white")
grDevices::cairo_pdf(paste0(figure_prefix, ".pdf"),
                     width = width_mm / 25.4, height = height_mm / 25.4, family = "Arial")
print(combined_plot)
invisible(dev.off())
svglite::svglite(paste0(figure_prefix, ".svg"),
                 width = width_mm / 25.4, height = height_mm / 25.4)
print(combined_plot)
invisible(dev.off())
print(result_table)
