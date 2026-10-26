library(terra)
library(sf)
library(dplyr)
library(tidyr)
library(readxl)
library(ggplot2)
pdfFonts(Arial = pdfFonts()$Helvetica)
# Run with Code availability as the working directory.
path <- file.path("Source Data file", "Fig1")
if (!dir.exists(path)) {
  stop("Set the working directory to the Code availability project root.")
}
crs_robinson <- "+proj=robin +datum=WGS84 +units=m +no_defs"
world <- st_read(file.path(path, "world.geojson"), quiet = TRUE) %>% filter(!grepl("ATA", SOC, ignore.case = TRUE))
world <- st_transform(world, crs_robinson)
map_grid <- project(rast(file.path(path, "Source Data Fig1a.tif")), crs_robinson, method = "near")
regions <- c("All", "Africa", "Asia", "Latin America", "Europe incl Russia", "North America & Oceania")
region_labels <- c("All", "Africa", "Asia", "LATAM", "EUR", "NAMO")
map_colors <- c("#EDE986", "#519A6E", "#1D2B59")
emission_colors <- c("#2B8ABB", "#EFEC70", "#D92117")
theme_set(theme_minimal(base_size = 12, base_family = "Arial") + theme(text = element_text(size = 12, color = "#000000"), axis.text = element_text(size = 12, color = "#000000"), axis.title = element_text(size = 12, color = "#000000"), legend.text = element_text(size = 12, color = "#000000"), legend.title = element_text(size = 12, color = "#000000"), plot.tag = element_text(size = 12, color = "#000000")))
map_plot <- function(file, multiplier, title, breaks, labels, colors, tag, total = NULL) {
  z <- as.data.frame(project(rast(file.path(path, file)), map_grid, method = "near"), xy = TRUE, na.rm = FALSE)
  names(z)[3] <- "value"
  z$value <- z$value * multiplier
  p <- ggplot(z, aes(x, y)) +
    geom_raster(aes(fill = value)) +
    geom_sf(data = world, inherit.aes = FALSE, fill = NA, color = "grey30", linewidth = 0.1) +
    scale_fill_gradientn(colors = colors, limits = range(breaks), breaks = breaks, labels = labels, oob = scales::squish, na.value = "transparent", name = title) +
    coord_sf(crs = crs_robinson, xlim = c(-17000000, 17000000), ylim = c(-6000000, 8500000), expand = FALSE) +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = grid::unit(58, "mm"), barheight = grid::unit(3, "mm"))) +
    labs(x = NULL, y = NULL, tag = tag) +
    theme(axis.text = element_blank(), axis.ticks = element_blank(), panel.grid = element_blank(), legend.position = "bottom", legend.title = element_text(size = 12, color = "#000000"), legend.text = element_text(size = 12, color = "#000000"), legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(0, "mm"), plot.tag = element_text(face = "bold", size = 12, color = "#000000"), plot.tag.position = c(0.02, 0.98), plot.margin = margin(4, 4, 2, 4))
  if (!is.null(total)) p <- p + annotate("text", x = -12000000, y = -4000000, label = total, parse = TRUE, family = "Arial", size = 12, size.unit = "pt", color = "#000000")
  p
}
sum_raster <- function(file) global(rast(file.path(path, file)), "sum", na.rm = TRUE)[1, 1]
p_a <- map_plot("Source Data Fig1a.tif", 1e-3, "Food-miles (million tkm)", seq(0, 100, 25), c("0", "25", "50", "75", ">100"), map_colors, "a", sprintf("atop(textstyle('%.2f trillion'), textstyle('tkm'))", sum_raster("Source Data Fig1a.tif") / 1e9))
p_b <- map_plot("Source Data Fig1b.tif", 1, "Distance food transported (km)", seq(0, 3000, 1000), c("0", "1000", "2000", ">3000"), map_colors, "b")
p_c <- map_plot("Source Data Fig1c.tif", 1e6, "Transport emissions (kt)", seq(0, 10, 2.5), c("0.0", "2.5", "5.0", "7.5", ">10"), emission_colors, "c", sprintf("atop(textstyle('%.1f'), textstyle(MtCO[textstyle(2)]))", sum_raster("Source Data Fig1c.tif") * 1000))
p_e <- map_plot("Source Data Fig1e.tif", 1, "Food-related emissions (kt)", seq(0, 400, 100), c("0", "100", "200", "300", ">400"), emission_colors, "e", sprintf("atop(textstyle('%.1f'), textstyle(MtCO[textstyle(2)]))", sum_raster("Source Data Fig1e.tif") / 1000))
bar_theme <- theme(panel.grid = element_blank(), axis.text = element_text(color = "black"), axis.line = element_line(color = "black", linewidth = 0.3), axis.ticks = element_line(color = "black", linewidth = 0.3), axis.ticks.length = grid::unit(-1, "mm"), axis.title.y = element_text(size = 12, color = "#000000"), legend.title = element_blank(), legend.text = element_text(size = 12, color = "#000000"), legend.key.size = grid::unit(3.5, "mm"), legend.spacing.y = grid::unit(0, "mm"), legend.margin = margin(0, 0, 0, 0), plot.tag = element_text(face = "bold", size = 12, color = "#000000"), plot.tag.position = c(0.02, 0.98), plot.margin = margin(7, 4, 4, 4))
transport <- read_excel(file.path(path, "Source Data Fig1.xlsx"), sheet = "Figure1d",range = "A1:E7") %>%
  select(Region, rail, road, sea) %>%
  pivot_longer(-Region, names_to = "Transport", values_to = "Percentage") %>%
  group_by(Region) %>% mutate(Percentage = Percentage / sum(Percentage)) %>% ungroup() %>%
  mutate(Region = factor(Region, regions), Transport = factor(Transport, c("rail", "road", "sea")), Label = if_else(Transport == "road" | (Transport == "rail" & Percentage >= 0.2), sprintf("%.2f%%", Percentage * 100), ""))
p_d <- ggplot(transport, aes(Region, Percentage, fill = Transport)) +
  geom_col(width = 0.9, color = "grey50", linewidth = 0.2) +
  geom_text(aes(label = Label, group = Transport), position = position_stack(vjust = 0.5), angle = 90, size = 12, size.unit = "pt", color = "#000000", family = "Arial", show.legend = FALSE) +
  scale_fill_manual(values = c(rail = "#F37E78", road = "#129392", sea = "#FFCC4F"), labels = c("Rail", "Road", "Sea")) +
  scale_x_discrete(labels = region_labels, expand = expansion(add = 0.15)) +
  scale_y_continuous(breaks = seq(0, 1, 0.25), labels = seq(0, 100, 25), expand = expansion(mult = c(0, 0))) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Contributions of transport\nmodes to emissions (%)", tag = "d") + bar_theme +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5), axis.ticks.x = element_blank())
food <- read_excel(file.path(path, "Source Data Fig1.xlsx"), sheet = "Figure1f", range = "A1:F1865") %>%
  filter(Region != "All") %>%
  mutate(Region = case_when(Region %in% c("Central America", "South America") ~ "Latin America", Region %in% c("North America", "Oceania") ~ "North America & Oceania", TRUE ~ Region)) %>%
  group_by(Region, group) %>% summarise(total = sum(total, na.rm = TRUE), .groups = "drop")
food <- bind_rows(food, food %>% group_by(Region) %>% summarise(total = sum(total), group = "All", .groups = "drop")) %>%
  group_by(group) %>% mutate(Percentage = total / sum(total)) %>% ungroup() %>%
  mutate(group = factor(group, c("All", "ABF", "Meat", "PBF", "MFS")), Region = factor(Region, regions[-1]))
p_f <- ggplot(food, aes(group, Percentage, fill = Region)) +
  geom_col(width = 0.9, color = "grey50", linewidth = 0.2) +
  scale_fill_manual(values = c("Africa" = "#EDF8FB", "Asia" = "#BFD3E6", "Latin America" = "#8C96C6", "Europe incl Russia" = "#9EBCDA", "North America & Oceania" = "#8856A7"), labels = c("Africa", "Asia", "LATAM", "EUR", "NAMO")) +
  scale_x_discrete(expand = expansion(add = 0.15)) +
  scale_y_continuous(breaks = seq(0, 1, 0.25), labels = seq(0, 100, 25), expand = expansion(mult = c(0, 0))) +
  labs(x = NULL, y = "Regional contributions\nto food-related emissions (%)", tag = "f") + bar_theme
plots <- list(p_a, p_b, p_c, p_d, p_e, p_f)
Figure1 <- gtable::gtable_matrix("Figure1", matrix(lapply(plots, ggplotGrob), nrow = 3, byrow = TRUE), widths = grid::unit(c(1, 1), "null"), heights = grid::unit(c(1, 1, 1), "null"), clip = "off")
for (i in seq_along(plots)) ggsave(file.path(path, paste0("Figure1", letters[i], ".svg")), plots[[i]], width = 110, height = 80, units = "mm", bg = "white")
ggsave(file.path(path, "Figure1.svg"), Figure1, width = 220, height = 240, units = "mm", bg = "white")
ggsave(file.path(path, "Figure1.png"), Figure1, width = 220, height = 240, units = "mm", dpi = 300, bg = "white")
if (interactive()) {
  grid::grid.newpage()
  grid::grid.draw(Figure1)
}
