library(terra)
library(sf)
library(dplyr)
library(ggplot2)
pdfFonts(Arial = pdfFonts()$Helvetica)
# Run with Code availability as the working directory.
path <- file.path("Source Data file", "Fig3")
if (!dir.exists(path)) {
  stop("Set the working directory to the Code availability project root.")
}
crs_robinson <- "+proj=robin +datum=WGS84 +units=m +no_defs"
world <- st_read(file.path(dirname(path), "Fig1", "world.geojson"), quiet = TRUE) %>% filter(!grepl("ATA", SOC, ignore.case = TRUE))
world <- st_transform(world, crs_robinson)
map_grid <- project(rast(file.path(path, "Source Data Fig3a.tif")), crs_robinson, method = "near")
emission_colors <- c("#2B8ABB", "#EFEC70", "#D92117")
change_colors <- c("#106CA7", "white", "#BE1A23")
theme_set(theme_minimal(base_size = 12, base_family = "Arial") + theme(text = element_text(size = 12, color = "#000000"), axis.text = element_blank(), axis.title = element_blank(), axis.ticks = element_blank(), panel.grid = element_blank(), legend.position = "bottom", legend.text = element_text(size = 12, color = "#000000"), legend.title = element_text(size = 12, color = "#000000"), legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(0, "mm"), plot.tag = element_text(size = 12, color = "#000000", face = "bold"), plot.tag.position = c(0.02, 0.98), plot.margin = margin(5, 5, 3, 5)))
map_plot <- function(file, multiplier, title, breaks, labels, colors, tag, signed = FALSE) {
  r <- rast(file.path(path, file))
  total <- global(r, "sum", na.rm = TRUE)[1, 1] * multiplier / 1000
  z <- as.data.frame(project(r, map_grid, method = "near"), xy = TRUE, na.rm = FALSE)
  names(z)[3] <- "Value"
  z$Value <- z$Value * multiplier
  label <- sprintf(if (signed) "atop(textstyle('%+.1f'), textstyle(MtCO[textstyle(2)]))" else "atop(textstyle('%.1f'), textstyle(MtCO[textstyle(2)]))", total)
  ggplot(z, aes(x, y)) +
    geom_raster(aes(fill = Value)) +
    geom_sf(data = world, inherit.aes = FALSE, fill = NA, color = "black", linewidth = 0.1) +
    scale_fill_gradientn(colors = colors, limits = range(breaks), breaks = breaks, labels = labels, oob = scales::squish, na.value = "transparent", name = title) +
    coord_sf(crs = crs_robinson, xlim = c(-17000000, 17000000), ylim = c(-6000000, 8500000), expand = FALSE) +
    annotate("text", x = -12000000, y = -4000000, label = label, parse = TRUE, family = "Arial", size = 12, size.unit = "pt", color = "#000000") +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = grid::unit(72, "mm"), barheight = grid::unit(3.5, "mm"))) +
    labs(tag = tag)
}
p_a <- map_plot("Source Data Fig3a.tif", 1e6, "Transport emissions (kt)", seq(0, 10, 2.5), c("0.0", "2.5", "5.0", "7.5", ">10"), emission_colors, "a")
p_b <- map_plot("Source Data Fig3b.tif", 1e6, "Changes in transport emissions (kt)", seq(-10, 10, 5), c("<-10", "-5", "0", "5", ">10"), change_colors, "b", TRUE)
p_c <- map_plot("Source Data Fig3c.tif", 1, "Food-related emissions (kt)", seq(0, 400, 100), c("0", "100", "200", "300", ">400"), emission_colors, "c")
p_d <- map_plot("Source Data Fig3d.tif", 1, "Changes in food-related emissions (kt)", seq(-200, 200, 100), c("<-200", "-100", "0", "100", ">200"), change_colors, "d", TRUE)
plots <- list(p_a, p_b, p_c, p_d)
Figure3 <- gtable::gtable_matrix("Figure3", matrix(lapply(plots, ggplotGrob), nrow = 2, byrow = TRUE), widths = grid::unit(c(1, 1), "null"), heights = grid::unit(c(1, 1), "null"), clip = "off")
for (i in seq_along(plots)) ggsave(file.path(path, paste0("Figure3", letters[i], ".svg")), plots[[i]], width = 140, height = 95, units = "mm", bg = "white")
ggsave(file.path(path, "Figure3.svg"), Figure3, width = 280, height = 190, units = "mm", bg = "white")
ggsave(file.path(path, "Figure3.png"), Figure3, width = 280, height = 190, units = "mm", dpi = 300, bg = "white")
if (interactive()) {
  grid::grid.newpage()
  grid::grid.draw(Figure3)
}
