library(gdxrrw)
library(dplyr)
library(readxl)
library(openxlsx)
library(raster)
library(terra)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
gams_dir <- Sys.getenv("GAMS_SYSDIR")
if (nzchar(gams_dir)) igdx(gams_dir, silent = TRUE)
if (.Platform$OS.type == "unix" && Sys.info()[["sysname"]] == "Darwin" && !nzchar(gams_dir)) {
  gams_dirs <- Sys.glob("/Library/Frameworks/GAMS.framework/Versions/*/Resources")
  if (length(gams_dirs)) igdx(tail(gams_dirs, 1), silent = TRUE)
}
output_dir <- "Output/food_related_emissions"
for (folder in c(output_dir, "Output/plots")) dir.create(folder, recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/08_postprocessing_food_related_emissions.pdf")

rgdx.var <- function(varname) {
  var.data <- data.frame(varname$val)
  var.dim <- length(varname$uels)
  domains <- varname$domains
  for (j in (1:(var.dim))) {
    if (domains[j] == "*") {
      domains[j] <- paste("X", j, sep = "")
    }
  }
  for (i in 1:var.dim) {
    dim           <- data.frame(varname$uels[[i]])
    dim$id        <- seq_along(dim[, 1])
    index         <- varname$domains[i]
    colnames(dim) <- c(index, "id")
    var.colname   <- paste("X", i, sep = "")
    var.data      <- merge(dim, var.data, by.x = "id", by.y = var.colname)
    var.data      <- var.data[, -which(colnames(var.data) == "id")]
  }
  var.data <- var.data[, c(var.dim:1, var.dim + 1)]
  colnames(var.data)[var.dim + 1]  <- c("value")
  colnames(var.data)[var.dim]      <- "field"
  attributes(var.data)$domains     <- varname$domains
  attributes(var.data)$type        <- "variable"
  attributes(var.data)$symName     <- varname$name
  attributes(var.data)$description <- varname$description
  return(var.data)
}

point_demand <- raster('Output/0.5by0.5/calib_2020_population_0.5by0.5.tif') %>%
  as.data.frame(., xy = TRUE) %>%
  na.omit() %>%
  filter(pop_WB_2020 >= 500) %>%
  dplyr::select(-3)

point_production <- raster('Output/0.5by0.5/calib_2020_point_production.tif') %>%
  as.data.frame(., xy = TRUE) %>%
  na.omit() %>%
  filter(prod >= 0) %>%
  dplyr::select(-3)

library(terra)
allland <- rast('Output/transport/alltransport_speed_new.tif')
allland <- ifel(allland == 19, NA, allland)
plot(allland)


start_index <- cellFromXY(allland, point_production)
demand_index <- cellFromXY(allland, point_demand)

country_ID <- raster("Input/Other data/countrylevel/country_ID_0.5_newest.tif") %>%
  as.data.frame(.,xy = TRUE)
mapping_region <- read_excel('Input/Other data/mapping country and region.xlsx',range = 'A1:D208')
country_ID <- left_join(country_ID,mapping_region,by = 'country_ID_0.5')


From_index <- cbind(point_production,start_index)
From_index <- left_join(From_index,country_ID,by = c('x','y'))

To_index <- cbind(point_demand,demand_index)
To_index <- left_join(To_index,country_ID,by = c('x','y'))


all_foods <- c("Bovine", "cereal", "eggs", "fruit", "legume_nuts", "milk",
           "oilcrop", "pig", "poultry", "root", "vegetable")
intensity_files <- c("emi_Bovine.gdx", "emi_cereal.gdx", "emi_Eggs.gdx", "emi_fruit.gdx",
                     "emi_pulses.gdx", "emi_Milk.gdx", "emi_oilcrop.gdx", "emi_Pork.gdx",
                     "emi_Poultry.gdx", "emi_root.gdx", "emi_vegetable.gdx")
names(intensity_files) <- all_foods

# Choose one food, a subset, or all_foods for the complete total.
foods <- all_foods

if (!length(foods) || anyNA(foods) || any(!foods %in% all_foods) || anyDuplicated(foods)) {
  stop("foods must contain unique food names from all_foods.")
}
result_tag <- if (setequal(foods, all_foods)) "all_foods" else paste(foods, collapse = "_")
point_results <- country_results <- vector("list", length(foods))
names(point_results) <- names(country_results) <- foods

for (food in foods) {
  index_name <- paste0("i_", food)
  trade <- rgdx.var(rgdx(file.path("Output/GAMS/optimize result", paste0(food, "_disHarv.gdx")), list(name = "x")))
  trade[[index_name]] <- as.numeric(gsub("i", "", trade[[index_name]]))
  trade$field <- as.numeric(gsub("j", "", trade$field))
  trade$from <- start_index[trade[[index_name]]]
  trade$to <- demand_index[trade$field]
  intensity_file <- file.path("Input/GAMS input", intensity_files[[food]])
  symbols <- gdxInfo(intensity_file, dump = FALSE, returnDF = TRUE)$parameters
  symbols <- symbols$name[symbols$dim == 1]
  if (length(symbols) != 1L) stop("Expected one emission-intensity parameter in ", intensity_file)
  intensity <- rgdx.param(intensity_file, symbols, names = c(index_name, "intensity"), squeeze = FALSE)
  intensity[[index_name]] <- as.numeric(gsub("i", "", as.character(intensity[[index_name]])))
  final <- trade %>%
    left_join(intensity, by = index_name) %>%
    mutate(food_emi = value * intensity) %>%
    left_join(From_index, by = c("from" = "start_index")) %>%
    left_join(To_index, by = c("to" = "demand_index")) %>%
    transmute(from = count.x, from_region = Region.x, to_iso = count.y, to_region = Region.y,
              to_x = to, lon = x.y, lat = y.y, emi = food_emi)
  point <- final %>% group_by(to_x, lon, lat) %>%
    summarise(emis = sum(emi, na.rm = TRUE), .groups = "drop") %>%
    dplyr::select(lon, lat, emis)
  names(point) <- c("x", "y", food)
  point_results[[food]] <- point
  country <- final %>% group_by(to_iso, to_region) %>%
    summarise(emis = sum(emi, na.rm = TRUE), .groups = "drop")
  country$item <- food
  country_results[[food]] <- country
}
emi_food_related <- point_results[[foods[1]]][, c("x", "y")]
for (food in foods) {
  emi_food_related <- full_join(emi_food_related, point_results[[food]], by = c("x", "y"))
}
# total always means the sum of the selected foods.
emi_food_related$total <- rowSums(emi_food_related[, foods, drop = FALSE], na.rm = TRUE)
emi_food_related_bau <- terra::rast(emi_food_related[, c("x", "y", "total")])
plot(emi_food_related_bau)
writeRaster(emi_food_related_bau,
            file.path(output_dir, paste0("000_food_related_emissions_LFS_Base_", result_tag, ".tif")),
            overwrite = TRUE)
all_emi_iso <- bind_rows(country_results)
total_food_related_emissions <- sum(all_emi_iso$emis) / 1000000
# Retain the original summary conversion for both category and selected totals.
food_emissions_summary <- all_emi_iso %>%
  group_by(item) %>%
  summarise(food_related_emissions = sum(emis) / 1000000, .groups = "drop")
selected_total <- data.frame(
  selected_foods = paste(foods, collapse = ", "),
  food_related_emissions = total_food_related_emissions
)
print(food_emissions_summary)
print(selected_total)
write.xlsx(list(country_results = all_emi_iso,
                by_food = food_emissions_summary,
                selected_total = selected_total),
           file.path(output_dir, paste0("food_related_emis_", result_tag, ".xlsx")),
           overwrite = TRUE)
