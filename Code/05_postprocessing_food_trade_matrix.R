library(gdxrrw)
library(dplyr)
library(raster)
library(terra)

if (!dir.exists("Input")) stop("Set the working directory to the Code availability project folder.")
output_dir <- "Output/GAMS"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("Output/plots", recursive = TRUE, showWarnings = FALSE)
if (!interactive() && grDevices::dev.cur() == 1L) grDevices::pdf("Output/plots/05_postprocessing_food_trade_matrix.pdf")

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

point_demand <- raster::raster("Output/0.5by0.5/calib_2020_population_0.5by0.5.tif") %>%
  as.data.frame(xy = TRUE) %>%
  na.omit() %>%
  filter(pop_WB_2020 >= 500)
point_production <- raster::raster("Output/0.5by0.5/calib_2020_point_production.tif") %>%
  as.data.frame(xy = TRUE) %>%
  na.omit() %>%
  filter(prod >= 0)
allland <- terra::rast("Output/transport/alltransport_speed_new.tif")
allland <- terra::ifel(allland == 19, NA, allland)
plot(allland)
start_index <- terra::cellFromXY(allland, point_production)
demand_index <- terra::cellFromXY(allland, point_demand)

foods <- c("cereal", "Bovine", "eggs", "fruit", "legume_nuts", "milk",
           "oilcrop", "pig", "poultry", "root", "vegetable")
data_list <- vector("list", length(foods))
for (k in seq_along(foods)) {
  food <- foods[k]
  trade <- rgdx.var(rgdx(file.path(output_dir, "optimize result", paste0(food, "_disHarv.gdx")),
                        list(name = "x")))
  trade$from <- start_index[as.numeric(gsub("i", "", trade[[paste0("i_", food)]]))]
  trade$to <- demand_index[as.numeric(gsub("j", "", trade$field))]
  data_list[[k]] <- trade[, c("from", "to", "value")]
}
combined_data <- do.call(rbind, data_list)
source_all <- combined_data %>%
  group_by(from) %>%
  summarise(to_list = list(unique(to)), .groups = "drop")
saveRDS(source_all, file.path(output_dir, "source_all.rds"))
