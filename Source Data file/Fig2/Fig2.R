library(terra)
library(sf)
library(dplyr)
library(tidyr)
library(readxl)
library(ggplot2)
pdfFonts(Arial = pdfFonts()$Helvetica)
# Run with Code availability as the working directory.
path <- file.path("Source Data file", "Fig2")
if (!dir.exists(path)) {
  stop("Set the working directory to the Code availability project root.")
}
# Plot the original longitude/latitude coordinates without reprojection.
world <- st_read(file.path(path, "world.geojson"), quiet = TRUE) %>% filter(!grepl("ATA", SOC, ignore.case = TRUE))
world_coordinates <- st_coordinates(world)
world_outline <- data.frame(
  x = world_coordinates[, "X"],
  y = world_coordinates[, "Y"],
  group = do.call(paste, c(as.data.frame(world_coordinates[, grepl("^L", colnames(world_coordinates)), drop = FALSE]), sep = "_"))
)
regions <- c("Africa", "Asia", "Latin America", "Europe incl Russia", "North America & Oceania")
region_labels <- c("Africa", "Asia", "LATAM", "EUR", "NAMO")
foods <- c("bovine", "pig", "poultry", "pulses", "vegetable", "fruit", "cereal", "root", "Other cereal", "milk", "eggs")
food_labels <- c("Bovine", "Pig", "Poultry", "Pulses", "Vegetable", "Fruit", "Cereal", "Root", "Other", "Milk", "Eggs")
food_colors <- setNames(c("#D04F4E", "#D87071", "#E19292", "#08519C", "#3182BD", "#6BAED6", "#006D2C", "#2CA25F", "#74C476", "#8856A7", "#8C96C6"), foods)
theme_set(theme_minimal(base_size = 12, base_family = "Arial") + theme(text = element_text(size = 12, color = "#000000"), axis.text = element_text(size = 12, color = "#000000"), axis.title = element_text(size = 12, color = "#000000"), legend.text = element_text(size = 12, color = "#000000"), legend.title = element_text(size = 12, color = "#000000"), plot.tag = element_text(size = 12, color = "#000000", face = "bold"), panel.grid = element_blank(), plot.tag.position = c(0.01, 0.99), plot.margin = margin(6, 6, 6, 6)))
map_plot <- function(file, layer, title, breaks, labels, colors, tag, signed = FALSE) {
  r <- rast(file.path(path, file))[[layer]]
  z <- as.data.frame(crop(r, ext(-180, 180, -56, 84)), xy = TRUE, na.rm = FALSE)
  names(z)[3] <- "Value"
  z$Value <- z$Value / 1000
  total <- global(r, "sum", na.rm = TRUE)[1, 1] / 1e9
  label <- sprintf(if (signed) "atop(textstyle('%+.2f trillion'), textstyle('tkm'))" else "atop(textstyle('%.2f trillion'), textstyle('tkm'))", total)
  ggplot(z, aes(x, y)) +
    geom_raster(aes(fill = Value)) +
    geom_path(data = world_outline, aes(x = x, y = y, group = group), inherit.aes = FALSE, color = "black", linewidth = 0.1) +
    scale_fill_gradientn(colors = colors, limits = range(breaks), breaks = breaks, labels = labels, oob = scales::squish, na.value = "transparent", name = title) +
    coord_equal(xlim = c(-180, 180), ylim = c(-56, 84), expand = FALSE) +
    annotate("text", x = -125, y = -40, label = label, parse = TRUE, family = "Arial", size = 12, size.unit = "pt", color = "#000000") +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = grid::unit(65, "mm"), barheight = grid::unit(3.5, "mm"))) +
    labs(x = NULL, y = NULL, tag = tag) +
    theme(axis.text = element_blank(), axis.ticks = element_blank(), legend.position = "bottom", legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(0, "mm"))
}
read_food <- function(sheet) read_excel(file.path(path, "Source Data Fig2.xlsx"), sheet = sheet, range = "A1:L6") %>%
  pivot_longer(-Region, names_to = "Food", values_to = "Value") %>%
  mutate(Region = factor(Region, regions), Food = factor(Food, foods))
bar_plot <- function(z, title, tag) ggplot(z, aes(Region, Value, fill = Food)) +
  geom_col(width = 0.92, color = "grey50", linewidth = 0.15) +
  scale_fill_manual(values = food_colors, breaks = foods, labels = food_labels, drop = FALSE, name = NULL) +
  scale_x_discrete(labels = region_labels, expand = expansion(add = 0.15)) +
  scale_y_continuous(breaks = seq(-0.5, 3, 0.5), expand = expansion(mult = c(0, 0.03))) +
  labs(x = NULL, y = title, tag = tag) +
  theme(axis.line = element_line(color = "black", linewidth = 0.3), axis.ticks = element_line(color = "black", linewidth = 0.3), axis.ticks.length = grid::unit(-1, "mm"), legend.position = "bottom", legend.key.size = grid::unit(4, "mm"), legend.spacing.x = grid::unit(1, "mm"), legend.margin = margin(0, 0, 0, 0))
p_a <- map_plot("Source Data Fig2a.tif", "total_distance_all_type", "Food-miles (million tkm)", seq(0, 100, 25), c("0", "25", "50", "75", ">100"), c("#EDE986", "#519A6E", "#1D2B59"), "a")
p_c <- map_plot("Source Data Fig2c.tif", "diff", "Changes in food-miles (million tkm)", seq(-500, 500, 250), c("<-500", "-250", "0", "250", ">500"), c("#106CA7", "white", "#BE1A23"), "c", TRUE)
food_b <- read_food("Figure2b")
food_d <- read_food("Figure2d")
totals <- food_d %>% group_by(Region) %>% summarise(Total = sum(Value), .groups = "drop")
p_b <- bar_plot(food_b, "Food-miles (trillion tkm)", "b") + guides(fill = guide_legend(nrow = 3, byrow = FALSE))
p_d <- bar_plot(food_d, "Changes in food-miles\n(trillion tkm)", "d") +
  geom_hline(yintercept = 0, color = "red", linetype = "dotted", linewidth = 0.5) +
  geom_point(data = totals, aes(Region, Total), inherit.aes = FALSE, color = "red", size = 1.6) +
  annotate("text", x = 3.9, y = 2.35, label = "Changes in\nfood-miles", family = "Arial", size = 12, size.unit = "pt", color = "#000000") +
  annotate("curve", x = 3.2, y = 2.35, xend = 2.1, yend = totals$Total[totals$Region == "Asia"] + 0.08, curvature = 0.25, color = "red", linewidth = 0.4, arrow = grid::arrow(length = grid::unit(2, "mm"))) +
  coord_cartesian(ylim = c(-0.65, 2.7), clip = "off") +
  theme(legend.position = "none")
plots <- list(p_a, p_b, p_c, p_d)
Figure2 <- gtable::gtable_matrix("Figure2", matrix(lapply(plots, ggplotGrob), nrow = 2, byrow = TRUE), widths = grid::unit(c(1, 1), "null"), heights = grid::unit(c(1, 1), "null"), clip = "off")
for (i in seq_along(plots)) ggsave(file.path(path, paste0("Figure2", letters[i], ".svg")), plots[[i]], width = 140, height = 115, units = "mm", bg = "white")
ggsave(file.path(path, "Figure2.svg"), Figure2, width = 280, height = 230, units = "mm", bg = "white")
ggsave(file.path(path, "Figure2.png"), Figure2, width = 280, height = 230, units = "mm", dpi = 300, bg = "white")
if (interactive()) {
  grid::grid.newpage()
  grid::grid.draw(Figure2)
}
