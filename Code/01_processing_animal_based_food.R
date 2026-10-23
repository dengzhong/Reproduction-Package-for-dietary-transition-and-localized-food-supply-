library(terra)
library(raster)
library(dplyr)
library(readxl)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")

# 1. Prepare baseline production
dir.create("Output/animal", recursive = TRUE, showWarnings = FALSE)
dir.create("Output/animal/intermediate", recursive = TRUE, showWarnings = FALSE)
beef <- rast("Input/Livestock Production Systems data/bvmeat_kg/bvmeat_kg_00.tif")
beef <- terra::extend(beef, terra::ext(-180, 180, -90, 90))
ID <- rast("Input/Other data/mapping_name1.tif")
crop_extent <- ext(ID)
crop_crs <- crs(ID)
ext(beef) <- crop_extent
crs(beef) <- crop_crs
writeRaster(beef, "Output/animal/intermediate/bvmeat_new.tif", overwrite = TRUE)
beef <- raster("Output/animal/intermediate/bvmeat_new.tif")
beef <- as.data.frame(beef,xy=TRUE)
beef$bvmeat_kg_00 <- beef$bvmeat_kg_00*100
beef <- rast(beef)
sgmeat <- rast("Input/Livestock Production Systems data/sgmeat_kg/sgmeat_kg_00.tif")
sgmeat <- aggregate(sgmeat, fact = 10, fun = sum)
pimeat <- rast("Input/Livestock Production Systems data/pimeat_kg/pimeat_kg_00.tif")
pimeat <- aggregate(pimeat, fact = 10, fun = sum)
pomeat <- rast("Input/Livestock Production Systems data/pomeat_kg/pomeat_kg_00.tif")
pomeat <- aggregate(pomeat, fact = 10, fun = sum)
bvmilk <- rast("Input/Livestock Production Systems data/bvmilk_kg/bvmilk_kg_00.tif")
bvmilk <- terra::extend(bvmilk, terra::ext(-180, 180, -90, 90))
ext(bvmilk) <- crop_extent
crs(bvmilk) <- crop_crs
writeRaster(bvmilk, "Output/animal/intermediate/bvmilk_new.tif", overwrite = TRUE)
bvmilk <- raster("Output/animal/intermediate/bvmilk_new.tif")
bvmilk <- as.data.frame(bvmilk,xy=TRUE)
bvmilk$bvmilk_kg_00 <- bvmilk$bvmilk_kg_00*100
sgmilk <- rast("Input/Livestock Production Systems data/sgmilk_kg/sgmilk_kg_00.tif")
sgmilk <- aggregate(sgmilk, fact = 10, fun = sum)
ext(sgmilk) <- crop_extent
crs(sgmilk) <- crop_crs
writeRaster(sgmilk, "Output/animal/intermediate/sgmilk_new.tif", overwrite = TRUE)
sgmilk <- raster("Output/animal/intermediate/sgmilk_new.tif")
sgmilk <- as.data.frame(sgmilk,xy=TRUE)
milk <- left_join(bvmilk,sgmilk,by=c("x","y"))
milk$milk <- apply(milk[,3:4],1,sum,na.rm=TRUE)
milk <- milk %>% dplyr::select(x,y,milk)
milk <-rast(milk)
poeggs <- rast("Input/Livestock Production Systems data/poeggs_kg/poeggs_kg_00.tif")
poeggs <- aggregate(poeggs, fact = 10, fun = sum)
ext(beef) <- crop_extent
crs(beef) <- crop_crs
ext(sgmeat) <- crop_extent
crs(sgmeat) <- crop_crs
ext(pimeat) <- crop_extent
crs(pimeat) <- crop_crs
ext(pomeat) <- crop_extent
crs(pomeat) <- crop_crs
ext(milk) <- crop_extent
crs(milk) <- crop_crs
ext(poeggs) <- crop_extent
crs(poeggs) <- crop_crs
writeRaster(beef, "Output/animal/beef.tif", overwrite = TRUE)
writeRaster(sgmeat, "Output/animal/goat.tif", overwrite = TRUE)
writeRaster(milk, "Output/animal/Milknew.tif", overwrite = TRUE)
writeRaster(pimeat, "Output/animal/Pignew.tif", overwrite = TRUE)
writeRaster(pomeat, "Output/animal/Poultrynew.tif", overwrite = TRUE)
writeRaster(poeggs, "Output/animal/Eggsnew.tif", overwrite = TRUE)

# 2. Match country raster metadata
folder_path <- "Output/animal/"
country_tif <- "Output/basedata/country_ID.tif"
dir.create(file.path(folder_path, "new"), recursive = TRUE, showWarnings = FALSE)
country_tif <- rast(country_tif)
crop_extent <- ext(country_tif)
crop_crs <- crs(country_tif)
tif_files <- list.files(folder_path, pattern = "\\.tif", full.names = TRUE)
for (tif_file in tif_files) {
  raster_data <- rast(tif_file)
  ext(raster_data) <- crop_extent
  crs(raster_data) <- crop_crs
  output_file <- file.path(folder_path, paste0("new/cropped_", basename(tif_file)))
  writeRaster(raster_data, output_file, overwrite = TRUE)
}

# 3. Scale to 2020 and combine beef + goat
livestock_files <- list(
  list(file = "Output/animal/new/cropped_beef.tif", item = "Beef", output = "Output/animal/2020/beef_2020.tif"),
  list(file = "Output/animal/new/cropped_Poultrynew.tif", item = "Poultry", output = "Output/animal/2020/poultry_2020.tif"),
  list(file = "Output/animal/new/cropped_Eggsnew.tif", item = "Eggs", output = "Output/animal/2020/eggs_2020.tif"),
  list(file = "Output/animal/new/cropped_Milknew.tif", item = "Milk", output = "Output/animal/2020/milk_2020.tif"),
  list(file = "Output/animal/new/cropped_Pignew.tif", item = "Pigmeat", output = "Output/animal/2020/pig_2020.tif"),
  list(file = "Output/animal/new/cropped_goat.tif", item = "Goat", output = "Output/animal/2020/goat_2020.tif")
)
dir.create("Output/animal/2020", recursive = TRUE, showWarnings = FALSE)
for (livestock in livestock_files) {
  livestock_file <- livestock$file
  livestock_excel <- "Input/Other data/livestock.xlsx"
  item_name <- livestock$item
  output_file <- livestock$output
  country_ID <- raster("Output/basedata/country_ID.tif") %>%
    as.data.frame(xy = TRUE)
  livestock_2000 <- raster(livestock_file) %>%
    as.data.frame(xy = TRUE)
  livestock_2000_ID <- left_join(livestock_2000, country_ID, by = c("x", "y"))
  colnames(livestock_2000_ID) <- c("x", "y", "livestock_2000", "ISO3")
  livestock_country <- livestock_2000_ID %>%
    group_by(ISO3) %>%
    summarize(livestock = sum(livestock_2000, na.rm = TRUE) / 1000000) %>%
    filter(!is.na(ISO3))
  livestock_2020 <- read_excel(livestock_excel) %>%
    filter(Item == item_name) %>%
    dplyr::select(ISO3, Value)
  livestock_country <- left_join(livestock_country, livestock_2020, by = "ISO3") %>%
    mutate(Value = if_else(is.na(Value), livestock, Value),
           livestock = if_else(livestock == 0 & Value != 0, Value, livestock),
           conver = Value / livestock,
           conver = if_else(is.na(conver) | is.infinite(conver), 1, conver))
  livestock_2020_tif <- left_join(livestock_2000_ID, livestock_country, by = "ISO3") %>%
    mutate(livestock_2020 = livestock_2000 / 1000000 * conver) %>%
    dplyr::select(x, y, livestock_2020)
  livestock_2020_tif_new <- rast(livestock_2020_tif)
  country_ID <- rast("Output/basedata/country_ID.tif")
  crop_extent <- ext(country_ID)
  crop_crs <- crs(country_ID)
  ext(livestock_2020_tif_new) <- crop_extent
  crs(livestock_2020_tif_new) <- crop_crs
  writeRaster(livestock_2020_tif_new, output_file, overwrite = TRUE)
}
beef_2020 <- terra::rast("Output/animal/2020/beef_2020.tif")
goat_2020 <- terra::rast("Output/animal/2020/goat_2020.tif")
terra::compareGeom(beef_2020, goat_2020, stopOnError = TRUE)
bovine_2020 <- beef_2020 + goat_2020
names(bovine_2020) <- "Bovine_2020"
terra::writeRaster(
  bovine_2020,
  "Output/animal/2020/Bovine_2020.tif",
  overwrite = TRUE
)

# 4. Aggregate to 0.5 degrees
dir.create("Output/0.5by0.5", recursive = TRUE, showWarnings = FALSE)
livestock_list <- c("Bovine", "eggs", "milk", "pig", "poultry")
for (livestock_name in livestock_list) {
  production <- raster(paste0("Output/animal/2020/", livestock_name, "_2020.tif")) %>%
    aggregate(fact = 6, fun = sum)
  production <- calc(production, fun = function(x) ifelse(x == 0, NA, x))
  writeRaster(production, paste0("Output/0.5by0.5/", livestock_name, "_0.5by0.5.tif"), overwrite = TRUE)
}

# 5. Recalibrate country totals
for (livestock_name in livestock_list) {
  livestock_input <- raster(paste0("Output/0.5by0.5/", livestock_name, "_0.5by0.5.tif")) %>%
    as.data.frame(xy = TRUE)
  country_ID <- raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
    as.data.frame(.,xy = TRUE)
  livestock_input_ID <- left_join(livestock_input, country_ID, by = c("x", "y"))
  colnames(livestock_input_ID) <- c("x", "y", paste0(livestock_name, "_input"), "ISO3")
  livestock_country <- livestock_input_ID %>%
    group_by(ISO3) %>%
    summarize(!!livestock_name := sum(!!sym(paste0(livestock_name, "_input")), na.rm = TRUE)) %>%
    filter(!is.na(ISO3))
  livestock_2020 <- read_excel("Input/Other data/livestock_new.xlsx") %>%
    dplyr::select(ID_0, Item, Value) %>%
    filter(ID_0 != '#N/A', Item == livestock_name) %>%
    dplyr::select(ID_0, Value)
  colnames(livestock_2020) <- c("ISO3", "Value")
  livestock_2020$ISO3 <- as.numeric(livestock_2020$ISO3)
  livestock_country <- left_join(livestock_country, livestock_2020, by = "ISO3") %>%
    mutate(Value = if_else(is.na(Value), !!sym(livestock_name), Value),
           !!livestock_name := if_else(!!sym(livestock_name) == 0 & Value != 0, Value, !!sym(livestock_name)),
           conver = Value / !!sym(livestock_name),
           conver = if_else(is.na(conver) | is.infinite(conver), 1, conver))
  livestock_2020_tif <- left_join(livestock_input_ID, livestock_country, by = "ISO3") %>%
    mutate(!!paste0(livestock_name, "_2020") := !!sym(paste0(livestock_name, "_input")) * conver) %>%
    dplyr::select(x, y, !!paste0(livestock_name, "_2020"))
  livestock_2020_tif_new <- rast(livestock_2020_tif)
  country_ID <- rast("Input/Other data/countrylevel/country_ID_0.5_newest.tif")
  livestock_extent <- ext(country_ID)
  livestock_crs <- crs(country_ID)
  ext(livestock_2020_tif_new) <- livestock_extent
  crs(livestock_2020_tif_new) <- livestock_crs
  writeRaster(livestock_2020_tif_new, paste0("Output/0.5by0.5/calib_2020_", livestock_name, "_0.5by0.5.tif"), overwrite = TRUE)
}
