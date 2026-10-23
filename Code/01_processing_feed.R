library(terra)
library(raster)
library(dplyr)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/01_processing_feed.pdf")

source_dir <- "Input/Livestock Production Systems data/Livestock_production_systems-vVeS4eZt-/data"
feed_dir <- "Output/feed"
new_dir <- file.path(feed_dir, "new")
grid_dir <- file.path(feed_dir, "0.5deg")
adjust_dir <- file.path(grid_dir, "adjust")
year_dir <- file.path(feed_dir, "2020")
output_dir <- "Output/0.5by0.5/basic_feed_demand"
for (folder in c(feed_dir, new_dir, grid_dir, adjust_dir, year_dir, output_dir)) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
}
feed_types <- data.frame(
  source = c("bvmeat", "bvmilk", "pimeat", "po", "sgmeat", "sgmilk", "ls"),
  file = c("beef", "bvmilk", "pig", "poultry", "sgmeat", "sgmilk", "ls"),
  column = c("bvmeat", "bvmilk", "pig", "poultry", "sgmeat", "sgmilk", "ls")
)
ID <- rast("Input/Other data/mapping_name1.tif")
crop_extent <- ext(ID)
crop_crs <- crs(ID)

# 1. Prepare feed rasters and aggregate to 0.5 degrees.
for (i in seq_len(nrow(feed_types))) {
  source_name <- paste0(feed_types$source[i], "_grai_00")
  feed_name <- feed_types$file[i]
  production <- rast(file.path(source_dir, paste0(source_name, ".tif")))
  production <- terra::extend(production, terra::ext(-180, 180, -90, 90))
  ext(production) <- crop_extent
  crs(production) <- crop_crs
  if (i == 1L) plot(production)
  writeRaster(production, file.path(feed_dir, paste0(feed_name, "_feed.tif")), overwrite = TRUE)
  production <- raster(file.path(feed_dir, paste0(feed_name, "_feed.tif"))) %>%
    as.data.frame(xy = TRUE)
  production[[source_name]] <- production[[source_name]] * 100
  production <- rast(production)
  ext(production) <- crop_extent
  crs(production) <- crop_crs
  writeRaster(production, file.path(new_dir, paste0(feed_name, "_grain.tif")), overwrite = TRUE)
}
for (feed_name in feed_types$file) {
  production <- raster(file.path(new_dir, paste0(feed_name, "_grain.tif"))) %>%
    aggregate(fact = 6, fun = sum)
  writeRaster(production, file.path(grid_dir, paste0(feed_name, "_grain_0.5.tif")), overwrite = TRUE)
}
for (i in seq_len(nrow(feed_types))) {
  production <- raster(file.path(grid_dir, paste0(feed_types$file[i], "_grain_0.5.tif"))) %>%
    as.data.frame(xy = TRUE)
  if (i == 1L) grain <- production[, 1:2]
  grain[[feed_types$column[i]]] <- production[[paste0(feed_types$file[i], "_grain_0.5")]]
}
grain$ratio <- rowSums(grain[, 3:8], na.rm = TRUE) / grain$ls
grain_new <- grain[, 1:9]
grain_new[, 3:8] <- grain[, 3:8] / grain$ratio
grain_new$total <- rowSums(grain_new[, 3:8], na.rm = TRUE)
for (i in seq_len(nrow(feed_types))) {
  production <- rast(grain_new %>% dplyr::select(x, y, all_of(feed_types$column[i])))
  writeRaster(production, file.path(adjust_dir, paste0(feed_types$file[i], "_grain_0.5.tif")), overwrite = TRUE)
}

# 2. Calibrate total feed to 2020.
country_ID <-raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(xy = TRUE)
livestock_file <- ("Output/feed/0.5deg/adjust/ls_grain_0.5.tif")
livestock_2000 <- raster(livestock_file) %>%
  as.data.frame(xy = TRUE)
livestock_2000_ID <- left_join(livestock_2000, country_ID, by = c("x", "y"))
colnames(livestock_2000_ID) <- c("x", "y", "livestock_2000", "ISO3")
livestock_country <- livestock_2000_ID %>%
  group_by(ISO3) %>%
  summarize(livestock = sum(livestock_2000, na.rm = TRUE) / 1000000) %>%
  filter(!is.na(ISO3))
livestock_2020 <- read.csv('Input/Other data/feed_total_2020.csv') %>%
  dplyr::select(ID_0, Value) %>% filter(ID_0 != '#N/A')
colnames(livestock_2020) <- c("ISO3", "Value")
livestock_2020$ISO3 <- as.numeric(livestock_2020$ISO3)
livestock_country <- left_join(livestock_country, livestock_2020, by = "ISO3") %>%
  mutate(Value = if_else(is.na(Value), livestock, Value),
         livestock = if_else(livestock == 0 & Value != 0, Value, livestock),
         conver = Value / livestock,
         conver = if_else(is.na(conver) | is.infinite(conver), 1, conver))
livestock_2020_tif <- left_join(livestock_2000_ID, livestock_country, by = "ISO3") %>%
  mutate(livestock_2020 = livestock_2000 / 1000000 * conver) %>%
  dplyr::select(x, y, livestock_2020)
livestock_2020_tif_new <- rast(livestock_2020_tif)
country_ID <-rast("Input/Other data/countrylevel/country_ID_0.5_newest.tif")
crop_extent <- ext(country_ID)
crop_crs <- crs(country_ID)
ext(livestock_2020_tif_new) <- crop_extent
crs(livestock_2020_tif_new) <- crop_crs
writeRaster(livestock_2020_tif_new, "Output/feed/2020/ls_feed_2020.tif", overwrite = TRUE)
country_ID <-raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(xy = TRUE)
ls_2020 <- raster("Output/feed/2020/ls_feed_2020.tif") %>%
  as.data.frame(xy = TRUE)
ls_2020_ID <- left_join(ls_2020, country_ID, by = c("x", "y"))
colnames(ls_2020_ID) <- c("x", "y", "ls_2020", "ISO3")
ls_2020_country <- ls_2020_ID %>%
  group_by(ISO3) %>%
  summarize(ls = sum(ls_2020, na.rm = TRUE)) %>%
  filter(!is.na(ISO3))

# 3. Split total feed into crop and oil contributions.
country_ID <-raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(xy = TRUE)
ls_2020 <- raster("Output/feed/2020/ls_feed_2020.tif") %>%
  as.data.frame(xy = TRUE)
ls_2020_ID <- left_join(ls_2020, country_ID, by = c("x", "y"))
colnames(ls_2020_ID) <- c("x", "y", "ls_2020", "ISO3")
ls_2020_country <- ls_2020_ID %>%
  group_by(ISO3) %>%
  summarize(ls = sum(ls_2020, na.rm = TRUE)) %>%
  filter(!is.na(ISO3))
ratio_2020 <- read.csv('Input/Other data/feed_fodder_ratio_2020.csv') %>%
  dplyr::select(ID_0, Crop,Oil)
colnames(ratio_2020) <- c("ISO3", "Crop","Oil")
ls_2020_country <- left_join(ls_2020_country, ratio_2020, by = "ISO3")
crop_feed_2020_tif <- left_join(ls_2020_ID, ls_2020_country, by = "ISO3") %>%
  mutate(crop_feed = ls_2020 * Crop) %>%
  dplyr::select(x, y, crop_feed)
Oil_feed_2020_tif <- left_join(ls_2020_ID, ls_2020_country, by = "ISO3") %>%
  mutate(Oil_feed = ls_2020 * Oil) %>%
  dplyr::select(x, y, Oil_feed)
Oil_feed_2020_tif_new <- rast(Oil_feed_2020_tif)
Crop_feed_2020_tif_new <- rast(crop_feed_2020_tif)
country_ID <-rast("Input/Other data/countrylevel/country_ID_0.5_newest.tif")
crop_extent <- ext(country_ID)
crop_crs <- crs(country_ID)
ext(Oil_feed_2020_tif_new) <- crop_extent
crs(Oil_feed_2020_tif_new) <- crop_crs
ext(Crop_feed_2020_tif_new) <- crop_extent
crs(Crop_feed_2020_tif_new) <- crop_crs
writeRaster(Crop_feed_2020_tif_new, "Output/feed/2020/Crop_feed_2020.tif", overwrite = TRUE)
writeRaster(Oil_feed_2020_tif_new, "Output/feed/2020/Oil_feed_2020.tif", overwrite = TRUE)
country_ID <-raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(xy = TRUE)
Crop_2020 <- raster("Output/feed/2020/Crop_feed_2020.tif") %>%
  as.data.frame(xy = TRUE)
Crop_2020_ID <- left_join(Crop_2020, country_ID, by = c("x", "y"))
colnames(Crop_2020_ID) <- c("x", "y", "Crop_2020", "ISO3")
Crop_2020_country <- Crop_2020_ID %>%
  group_by(ISO3) %>%
  summarize(Crop = sum(Crop_2020, na.rm = TRUE)) %>%
  filter(!is.na(ISO3))

# 4. Allocate feed to livestock categories.
for (i in seq_len(nrow(feed_types))) {
  production <- raster(file.path(grid_dir, paste0(feed_types$file[i], "_grain_0.5.tif"))) %>%
    as.data.frame(xy = TRUE)
  if (i == 1L) grain <- production[, 1:2]
  grain[[feed_types$column[i]]] <- production[[paste0(feed_types$file[i], "_grain_0.5")]]
}
livestock_feed_ratio <- grain[, 1:8]
livestock_feed_ratio[, 3:8] <- grain[, 3:8] / rowSums(grain_new[, 3:8], na.rm = TRUE)
for (feed_group in c("Crop", "Oil")) {
  total_name <- if (feed_group == "Crop") "crop_feed" else "Oil_feed"
  feed_data <- raster(file.path(year_dir, paste0(feed_group, "_feed_2020.tif"))) %>%
    as.data.frame(xy = TRUE)
  feed_data <- cbind(feed_data, livestock_feed_ratio[, 3:8])
  animal_types <- c(total_name, paste0(feed_group, "_feed_", feed_types$column[1:6]))
  for (i in seq_len(6L)) {
    feed_data[[animal_types[i + 1L]]] <- feed_data[[total_name]] * feed_data[[feed_types$column[i]]]
  }
  feed_data <- feed_data %>% dplyr::select(x, y, all_of(animal_types))
  for (animal_type in animal_types) {
    feed_raster <- rast(feed_data %>% dplyr::select(x, y, all_of(animal_type)))
    writeRaster(feed_raster, file.path(output_dir, paste0(animal_type, "_.tif")), overwrite = TRUE)
  }
}
