library(terra)
library(sf)
library(dplyr)
library(ggplot2)
pdfFonts(Arial = pdfFonts()$Helvetica)
# Run with Code availability as the working directory.
path <- file.path("Source Data file", "Fig4")
if (!dir.exists(path)) {
  stop("Set the working directory to the Code availability project root.")
}
crs_robinson <- "+proj=robin +datum=WGS84 +units=m +no_defs"
transport <- rast(file.path(dirname(path), "Fig3", "Source Data Fig3b.tif"))
food <- rast(file.path(dirname(path), "Fig3", "Source Data Fig3d.tif"))
stopifnot(compareGeom(transport, food))
type <- ifel(transport < 0 & food < 0, 1, ifel(transport > 0 & food > 0, 2, ifel(transport < 0 & food > 0, 3, ifel(transport > 0 & food < 0, 4, NA))))
type <- project(type, crs_robinson, method = "near")
df <- as.data.frame(type, xy = TRUE, na.rm = FALSE)
names(df)[3] <- "Type"
labels <- c("Synergies", "Joint increases", "Trade-offs in food-related emissions", "Trade-offs in transport emissions")
df$Type <- factor(df$Type, levels = 1:4, labels = labels)
world <- st_read(file.path(dirname(path), "Fig1", "world.geojson"), quiet = TRUE) %>% filter(!grepl("ATA", SOC, ignore.case = TRUE))
world <- st_transform(world, crs_robinson)
p1 <- ggplot(df, aes(x, y)) +
  geom_raster(aes(fill = Type)) +
  geom_sf(data = world, inherit.aes = FALSE, fill = NA, color = "black", linewidth = 0.1) +
  scale_fill_manual(values = setNames(c("#ABCAD7", "#9D5E58", "#E64B35", "#FAF0CD"), labels), breaks = labels, drop = FALSE, na.value = "transparent", name = NULL) +
  coord_sf(crs = crs_robinson, xlim = c(-17000000, 17000000), ylim = c(-6000000, 8500000), expand = FALSE) +
  guides(fill = guide_legend(nrow = 2, byrow = FALSE)) +
  theme_minimal(base_size = 12, base_family = "Arial") +
  theme(text = element_text(size = 12, color = "#000000"), axis.text = element_blank(), axis.title = element_blank(), axis.ticks = element_blank(), panel.grid = element_blank(), legend.position = "bottom", legend.text = element_text(size = 12, color = "#000000"), legend.key = element_rect(color = "grey60", linewidth = 0.2), legend.key.size = grid::unit(4.5, "mm"), legend.spacing.x = grid::unit(2, "mm"), legend.margin = margin(0, 0, 0, 0), legend.box.spacing = grid::unit(1, "mm"), plot.background = element_rect(fill = "white", color = NA), plot.margin = margin(5, 5, 5, 5))
ggsave(file.path(path, "Figure4.svg"), p1, width = 220, height = 120, units = "mm", bg = "white")
ggsave(file.path(path, "Figure4.png"), p1, width = 220, height = 120, units = "mm", dpi = 300, bg = "white")
if (interactive()) print(p1)
