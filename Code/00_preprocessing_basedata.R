library(terra)
library(raster)
library(dplyr)
library(readxl)
library(sf)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")

for (folder in c("Output/basedata", "Output/basedata", "Output/0.5by0.5")) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
}

# 1. Rasterize country boundaries.
shpfile <- st_read("Input/Other data/countrylevel/gadm36_countrylevel（无南极洲）.shp")
spat_vector <- vect(shpfile)
r <- rast(nrows = 2160, ncols = 4320,
          xmin = -180, xmax = 180,
          ymin = -90, ymax = 90,
          crs = st_crs(shpfile)$proj4string)
country_ID <- rasterize(spat_vector, r, field = "GID_0")
writeRaster(country_ID, "Output/basedata/country_ID.tif", overwrite = TRUE)

# 2. Aggregate and calibrate population to 2020.
country_ID <- raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(.,xy = TRUE)
population <- rast("Input/Other data/population/poplution_2020/gpw-v4-population-count_2020.tif")
population <- terra::extend(population, terra::ext(-180, 180, -90, 90))
writeRaster(population,"Output/basedata/00_population-count_2020.tif")
population <- raster("Output/basedata/00_population-count_2020.tif") %>%
  aggregate(fact = 60, fun = sum) %>%
  as.data.frame(.,xy=TRUE)
population_2020_ID <- cbind(population,country_ID[,3])
colnames(population_2020_ID) <- c("x", "y","pop_2020", "ISO3")
population_country <- population_2020_ID %>%
  group_by(ISO3) %>%
  summarize(pop = sum(pop_2020, na.rm = TRUE)) %>%
  filter(!is.na(ISO3))
pop_2020 <- read_excel("Input/Other data/population_WB.xlsx")
colnames(pop_2020) <- c("ISO3", "Value")
population_country <- left_join(population_country, pop_2020, by = "ISO3") %>%
  mutate(Value = if_else(is.na(Value), pop, Value),
         pop = if_else(pop == 0 & Value != 0, Value, pop),
         conver = Value / pop,
         conver = if_else(is.na(conver) | is.infinite(conver), 1, conver))
population_2020_tif <- left_join(population_2020_ID, population_country, by = "ISO3") %>%
  mutate(pop_WB_2020 = pop_2020 * conver) %>%
  dplyr::select(x, y, pop_WB_2020)
population_2020_tif_new <- rast(population_2020_tif)
country_ID <- rast("Input/Other data/countrylevel/country_ID_0.5_newest.tif")
crop_extent <- ext(country_ID)
crop_crs <- crs(country_ID)
ext(population_2020_tif_new) <- crop_extent
crs(population_2020_tif_new) <- crop_crs
writeRaster(population_2020_tif_new, paste0("Output/0.5by0.5/calib_2020_", 'population', "_0.5by0.5.tif"), overwrite = TRUE)

# 3. Summarize calibrated population by country.
country_ID <- raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(.,xy = TRUE)
population <- raster("Output/0.5by0.5/calib_2020_population_0.5by0.5.tif") %>%
  as.data.frame(.,xy=TRUE)
population_2020_ID <- left_join(population, country_ID, by = c("x", "y"))
colnames(population_2020_ID) <- c("x", "y","pop_2020", "ISO3")
population_country <- population_2020_ID %>%
  group_by(ISO3) %>%
  summarize(pop = sum(pop_2020, na.rm = TRUE)) %>%
  filter(!is.na(ISO3))
