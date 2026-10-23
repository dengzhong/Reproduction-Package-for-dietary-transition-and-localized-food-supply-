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
output_dir <- "Output/regional_food_trade"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/09_postprocessing_regional_food_trade.pdf")

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


region_map <- function(x) {
  case_when(x == "Central America" ~ "South America",
            x %in% c("North America", "Oceania") ~ "North America & Oceania",
            TRUE ~ x)
}
foods <- c("Bovine", "cereal", "eggs", "fruit", "legume_nuts", "milk",
           "oilcrop", "pig", "poultry", "root", "vegetable")
regional_results <- country_results <- vector("list", length(foods))
for (k in seq_along(foods)) {
  food <- foods[k]
  index_name <- paste0("i_", food)
  trade <- rgdx.var(rgdx(file.path("Output/GAMS/optimize result", paste0(food, "_disHarv.gdx")), list(name = "x")))
  trade[[index_name]] <- as.numeric(sub("i", "", trade[[index_name]]))
  trade$field <- as.numeric(sub("j", "", trade$field))
  trade$from <- start_index[trade[[index_name]]]
  trade$to <- demand_index[trade$field]
  flows <- trade %>%
    left_join(From_index, by = c("from" = "start_index")) %>%
    left_join(To_index, by = c("to" = "demand_index")) %>%
    transmute(from_country = count.x, to_country = count.y,
              from_region = region_map(Region.x), to_region = region_map(Region.y), value)
  regional_results[[k]] <- flows %>% group_by(from_region, to_region) %>%
    summarise(tradeValue = sum(value), .groups = "drop") %>% mutate(Item = food)
  country_results[[k]] <- flows %>% group_by(from_country, to_country, from_region, to_region) %>%
    summarise(tradeValue = sum(value), .groups = "drop") %>% mutate(Item = food)
}
LFS_Base_trade <- bind_rows(regional_results)
country_trade <- bind_rows(country_results)
write.xlsx(LFS_Base_trade, file.path(output_dir, "LFS_Base_trade.xlsx"))
write.xlsx(country_trade, file.path(output_dir, "LFS_Base_country_trade.xlsx"))

regions <- sort(unique(c(LFS_Base_trade$from_region, LFS_Base_trade$to_region)))
summary <- expand.grid(Region = regions, Item = foods, stringsAsFactors = FALSE)
exports <- LFS_Base_trade %>% filter(from_region != to_region) %>%
  group_by(Region = from_region, Item) %>% summarise(exports = sum(tradeValue), .groups = "drop")
imports <- LFS_Base_trade %>% filter(from_region != to_region) %>%
  group_by(Region = to_region, Item) %>% summarise(imports = sum(tradeValue), .groups = "drop")
internal <- LFS_Base_trade %>% filter(from_region == to_region) %>%
  group_by(Region = from_region, Item) %>% summarise(internal_supply = sum(tradeValue), .groups = "drop")
summary <- summary %>% left_join(exports, by = c("Region", "Item")) %>%
  left_join(imports, by = c("Region", "Item")) %>% left_join(internal, by = c("Region", "Item")) %>%
  mutate(across(c(exports, imports, internal_supply), ~ coalesce(.x, 0)),
         total_supply = internal_supply + exports, total_demand = internal_supply + imports,
         net_exports = exports - imports,
         import_share = if_else(total_demand > 0, imports / total_demand, NA_real_))

international <- country_trade %>% filter(from_country != to_country)
international_exports <- international %>% group_by(Region = from_region, Item) %>%
  summarise(exports = sum(tradeValue), .groups = "drop")
international_imports <- international %>% group_by(Region = to_region, Item) %>%
  summarise(imports = sum(tradeValue), .groups = "drop")
international_summary <- expand.grid(Region = regions, Item = foods, stringsAsFactors = FALSE) %>%
  left_join(international_exports, by = c("Region", "Item")) %>%
  left_join(international_imports, by = c("Region", "Item")) %>%
  mutate(across(c(exports, imports), ~ coalesce(.x, 0)), net_exports = exports - imports)
write.xlsx(list(regional_trade = summary, international_trade = international_summary),
           file.path(output_dir, "LFS_Base_imports_exports.xlsx"))
