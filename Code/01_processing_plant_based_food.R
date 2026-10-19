library(terra)
library(raster)
library(dplyr)
library(readxl)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/01_processing_plant_based_food.pdf")

spam_dir <- "Input/SPAM data"
items_dir <- "Output/plant"
output_dir <- "Output/0.5by0.5"
country_file <- "Input/Other data/countrylevel/country_ID_0.5_newest.tif"
statistics_file <- "Input/Other data/crop_production_demand.xlsx"
dir.create(items_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

crop_groups <- list(
  stimulant = c("Arabic Coffee", "Robust Coffee", "Tea", "Cocoa"),
  cereal = c("Wheat", "Rice", "Maize", "Barley", "Small Millet", "Pearl Millet", "Sorghum", "Other Cereals"),
  root = c("Potato", "Sweet Potato", "Yams", "Cassava", "Other Roots"),
  pulses = c("Bean", "Chickpea", "Cowpea", "Pigeon Pea", "Lentil", "Other Pulses"),
  nuts = c("Soybean", "Groundnut", "Coconut"),
  oilcrop = c("Oilpalm", "Sunflower", "Rapeseed", "Sesame Seed", "Other Oil Crops"),
  sugar = c("Sugarcane", "Sugarbeet"),
  fruit = c("Banana", "Plantain", "Citrus", "Other Tropical Fruit", "Temperate Fruit"),
  vegetable = c("Tomato", "Onion", "Other Vegetables")
)
crop_list <- c("cereal", "root", "pulses", "nuts", "oilcrop", "sugar", "fruit", "vegetable", "stimulant")

# 1. Combine crops into food groups.
for (crop_name in names(crop_groups)) {
  products <- crop_groups[[crop_name]]
  for (j in seq_along(products)) {
    crop_data <- raster(file.path(spam_dir, paste0(products[j], ".tif"))) %>%
      as.data.frame(xy = TRUE)
    if (j == 1L) {
      combined <- crop_data
      colnames(combined) <- c("x", "y", crop_name)
      production_values <- matrix(NA_real_, nrow(crop_data), length(products))
    }
    production_values[, j] <- crop_data[[make.names(products[j])]]
  }
  combined[[crop_name]] <- rowSums(production_values, na.rm = TRUE)
  combined[[crop_name]] <- ifelse(combined[[crop_name]] == 0, NA, combined[[crop_name]])
  combined <- rast(combined)
  plot(combined)
  writeRaster(combined, file.path(items_dir, paste0(crop_name, ".tif")), overwrite = TRUE)
}

# 2. Aggregate to 0.5 degrees and convert tonnes to thousand tonnes.
for (crop_name in crop_list) {
  production <- raster(file.path(items_dir, paste0(crop_name, ".tif"))) %>%
    aggregate(fact = 6, fun = sum) / 1000
  writeRaster(production, file.path(output_dir, paste0(crop_name, "_0.5by0.5.tif")), overwrite = TRUE)
}

# 3. Calibrate country production to 2020.
for (crop_name in crop_list) {
  crop_2000 <- raster(file.path(output_dir, paste0(crop_name, "_0.5by0.5.tif"))) %>%
    as.data.frame(xy = TRUE)
  country_ID <- raster(country_file) %>%
    as.data.frame(.,xy = TRUE)
  crop_2000_ID <- left_join(crop_2000, country_ID, by = c("x", "y"))
  colnames(crop_2000_ID) <- c("x", "y", paste0(crop_name, "_2000"), "ISO3")
  crop_country <- crop_2000_ID %>%
    group_by(ISO3) %>%
    summarize(!!crop_name := sum(!!sym(paste0(crop_name, "_2000")), na.rm = TRUE)) %>%
    filter(!is.na(ISO3))
  crop_2020 <- read_excel(statistics_file) %>%
    dplyr::select(ID_0, Item, production) %>%
    filter(ID_0 != '#N/A', Item == crop_name) %>%
    dplyr::select(ID_0, production)
  colnames(crop_2020) <- c("ISO3", "Value")
  crop_2020$ISO3 <- as.numeric(crop_2020$ISO3)
  crop_country <- left_join(crop_country, crop_2020, by = "ISO3") %>%
    mutate(Value = if_else(is.na(Value), !!sym(crop_name), Value),
           !!crop_name := if_else(!!sym(crop_name) == 0 & Value != 0, Value, !!sym(crop_name)),
           conver = Value / !!sym(crop_name),
           conver = if_else(is.na(conver) | is.infinite(conver), 1, conver))
  crop_2020_tif <- left_join(crop_2000_ID, crop_country, by = "ISO3") %>%
    mutate(!!paste0(crop_name, "_2020") := !!sym(paste0(crop_name, "_2000")) * conver) %>%
    dplyr::select(x, y, !!paste0(crop_name, "_2020"))
  crop_2020_tif_new <- rast(crop_2020_tif)
  country_ID <- rast(country_file)
  crop_extent <- ext(country_ID)
  crop_crs <- crs(country_ID)
  ext(crop_2020_tif_new) <- crop_extent
  crs(crop_2020_tif_new) <- crop_crs
  writeRaster(crop_2020_tif_new, file.path(output_dir, paste0("calib_2020_", crop_name, "_0.5by0.5.tif")), overwrite = TRUE)
}

# 4. Summarize calibrated production by country.
country_ID <- raster(country_file) %>%
  as.data.frame(xy = TRUE)
crop_country_check <- list()
for (crop_name in crop_list) {
  crop_calibrated <- raster(file.path(output_dir, paste0("calib_2020_", crop_name, "_0.5by0.5.tif"))) %>%
    as.data.frame(xy = TRUE)
  crop_calibrated_ID <- left_join(crop_calibrated, country_ID, by = c("x", "y"))
  colnames(crop_calibrated_ID) <- c("x", "y", "production_2020", "ISO3")
  crop_country <- crop_calibrated_ID %>%
    group_by(ISO3) %>%
    summarize(!!crop_name := sum(production_2020, na.rm = TRUE)) %>%
    filter(!is.na(ISO3))
  crop_country_check[[crop_name]] <- crop_country
}
