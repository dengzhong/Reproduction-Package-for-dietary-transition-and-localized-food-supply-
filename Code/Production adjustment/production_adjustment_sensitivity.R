# Incomplete production adjustment from LFS-Base to LFS-EAT.
# Run from the project root. Requires gdxrrw; does not rerun optimization.
# Q_Base(i,k) = sum_j x_Base(i,j,k); Q_EAT(i,k) = sum_j x_EAT(i,j,k).
# R(i,k,alpha) = Q_EAT + alpha * max(Q_Base - Q_EAT, 0).

all_foods <- c("Bovine", "cereal", "eggs", "fruit", "legume_nuts", "milk",
               "oilcrop", "pig", "poultry", "root", "vegetable")
foods <- all_foods
alphas <- c(0, 0.2, 0.4)
base_dir <- "Output/GAMS/optimize result"
eat_dir <- "Output/GAMS/optimize result"
input_dir <- "Input/GAMS input"
production_raster <- "Output/0.5by0.5/calib_2020_point_production.tif"
population_raster <- "Output/0.5by0.5/calib_2020_population_0.5by0.5.tif"
country_raster <- "Input/Other data/countrylevel/country_ID_0.5_newest.tif"
# Summary emissions retain the original scripts' division by 1e6.
# Verify source mass/intensity units before assigning a physical unit label.
emission_divisor <- 1e6
keep_origin_details <- TRUE

intensity_files <- setNames(c("emi_Bovine.gdx", "emi_cereal.gdx", "emi_Eggs.gdx",
  "emi_fruit.gdx", "emi_pulses.gdx", "emi_Milk.gdx", "emi_oilcrop.gdx",
  "emi_Pork.gdx", "emi_Poultry.gdx", "emi_root.gdx", "emi_vegetable.gdx"), all_foods)

# Read shipment levels directly in sparse form, aggregating by origin label.
read_origin_output <- function(path, intensity = NULL, country_lookup = NULL) {
  g <- gdxrrw::rgdx(path, list(name = "x", field = "l", form = "sparse"))
  if (g$dim != 2L) stop("Expected a two-dimensional shipment variable: ", path)
  labels <- as.character(g$uels[[1]])
  output <- setNames(numeric(length(labels)), labels)
  if (nrow(g$val)) {
    values <- g$val[, ncol(g$val)]
    if (any(!is.finite(values)) || any(values < -1e-7)) stop("Invalid shipment levels: ", path)
    sums <- rowsum(pmax(values, 0), group = g$val[, 1], reorder = FALSE)
    output[as.integer(rownames(sums))] <- sums[, 1]
  }
  # GDX UEL lists can contain labels unrelated to the origin domain.
  # Only origins with positive shipments contribute to either scenario.
  # The union across scenarios below preserves Base-only origins.
  output <- output[output > 0]
  if (!is.null(intensity)) {
    origin <- labels[g$val[, 1]]
    destination <- as.character(g$uels[[2]])[g$val[, 2]]
    ef <- unname(intensity[origin])
    country <- map_country(destination, "j", country_lookup$demand)
    emissions <- pmax(g$val[, ncol(g$val)], 0) * ef / emission_divisor
    if (anyNA(emissions)) stop("Missing shipment emission intensity: ", path)
    consumption <- tapply(emissions, country, sum)
    return(list(output = output, consumption = consumption))
  }
  output
}

# Reconstruct the same shared location ordering used by the existing 08 script.
load_country_lookup <- function() {
  if (!requireNamespace("terra", quietly = TRUE)) stop("Install terra first.")
  production <- terra::as.data.frame(terra::rast(production_raster), xy = TRUE, na.rm = FALSE)
  demand <- terra::as.data.frame(terra::rast(population_raster), xy = TRUE, na.rm = FALSE)
  production <- production[complete.cases(production) & !is.na(production$prod) & production$prod >= 0, c("x", "y")]
  demand <- demand[complete.cases(demand) & !is.na(demand$pop_WB_2020) & demand$pop_WB_2020 >= 500, c("x", "y")]
  country <- terra::rast(country_raster)
  list(production = terra::extract(country, as.matrix(production))[, 1],
       demand = terra::extract(country, as.matrix(demand))[, 1])
}

map_country <- function(labels, prefix, countries) {
  invalid <- is.na(labels) | !grepl(paste0("^", prefix, "[0-9]+$"), labels)
  if (any(invalid)) stop("Unexpected spatial labels (expected ", prefix,
                         " followed by an integer): ",
                         paste(head(labels[invalid], 10), collapse = ", "))
  index <- as.integer(sub(paste0("^", prefix), "", labels))
  if (anyNA(index) || any(index < 1 | index > length(countries))) stop("Spatial label out of range.")
  result <- as.character(countries[index])
  # Preserve unassigned cells explicitly so country sums still match global sums.
  result[is.na(result)] <- "UNMAPPED"
  result
}

read_intensity <- function(path) {
  info <- gdxrrw::gdxInfo(path, dump = FALSE, returnDF = TRUE)$parameters
  symbols <- info$name[info$dim == 1L]
  if (length(symbols) != 1L) stop("Expected one intensity parameter: ", path)
  g <- gdxrrw::rgdx(path, list(name = symbols, form = "sparse"), squeeze = FALSE)
  intensity <- setNames(numeric(length(g$uels[[1]])), as.character(g$uels[[1]]))
  if (nrow(g$val)) intensity[g$val[, 1]] <- g$val[, ncol(g$val)]
  if (any(!is.finite(intensity)) || any(intensity < 0)) stop("Invalid intensity: ", path)
  intensity
}

# Table layout follows the supplied manuscript template. Values are not rounded.
# Units follow the source intensities and emission_divisor used above.
build_emissions_table <- function(results) {
  food_labels <- c(cereal = "Cereal", Bovine = "Bovine", eggs = "Eggs", fruit = "Fruit",
    legume_nuts = "Pulses", milk = "Milk", oilcrop = "Oil crop", pig = "Pig",
    poultry = "Poultry", root = "Root", vegetable = "Vegetable")
  # legume_nuts retains the underlying combined pulses-and-nuts category;
  # "Pulses" is only the display label requested by the table template.
  selected <- results$BAU$by_food$food
  order <- names(food_labels)[names(food_labels) %in% selected]
  table <- data.frame("Food category" = unname(food_labels[order]),
                      "Emissions type" = rep("Food-related", length(order)),
                      check.names = FALSE)
  scenario_columns <- c("LFS-Base" = "BAU", "LFS-EAT" = "EAT",
                        "LFS-EATR20" = "EATR20", "LFS-EATR40" = "EATR40")
  for (column in names(scenario_columns)) {
    values <- results[[scenario_columns[[column]]]]$by_food
    if (anyDuplicated(values$food) || !setequal(values$food, selected)) {
      stop("Scenario food categories do not match: ", column)
    }
    table[[column]] <- values$food_related_emissions[match(order, values$food)]
  }
  if (anyNA(table)) stop("Missing values in the emissions comparison table.")
  total <- table[1, , drop = FALSE]
  total[["Food category"]] <- if (setequal(selected, all_foods)) "Total" else "Selected total"
  for (column in names(scenario_columns)) total[[column]] <- sum(table[[column]])
  table <- rbind(table, total)
  rownames(table) <- NULL
  table
}

run_sensitivity <- function() {
  if (!length(foods) || anyNA(foods) || anyDuplicated(foods) || any(!foods %in% all_foods)) {
    stop("Choose unique names from all_foods.")
  }
  if (!length(alphas) || any(!is.finite(alphas)) || any(alphas < 0 | alphas > 1) ||
      anyDuplicated(alphas) || !all(c(0, 0.2, 0.4) %in% alphas)) {
    stop("alphas must be unique, between zero and one, and include 0, 0.2, 0.4.")
  }
  if (!is.finite(emission_divisor) || emission_divisor <= 0) stop("Invalid emission_divisor.")
  required <- c(file.path(base_dir, paste0(foods, "_disHarv.gdx")),
                file.path(eat_dir, paste0(foods, "_disHarv_eat.gdx")),
                file.path(input_dir, intensity_files[foods]),
                production_raster, population_raster, country_raster)
  missing <- required[!file.exists(required)]
  if (length(missing)) stop("Missing required files:\n", paste(missing, collapse = "\n"))
  if (!requireNamespace("gdxrrw", quietly = TRUE)) stop("Install gdxrrw first.")
  gams_dir <- Sys.getenv("GAMS_SYSDIR")
  if (!nzchar(gams_dir) && Sys.info()[["sysname"]] == "Darwin") {
    gams_dir <- "/Library/Frameworks/GAMS.framework/Versions/Current/Resources"
  }
  if (nzchar(gams_dir)) gdxrrw::igdx(gams_dir, silent = TRUE) else gdxrrw::igdx(silent = TRUE)
  country_lookup <- load_country_lookup()
  country_results <- vector("list", length(foods))
  origin_details <- setNames(vector("list", length(foods)), foods)
  results <- vector("list", length(foods))
  for (k in seq_along(foods)) {
    food <- foods[k]
    intensity <- read_intensity(file.path(input_dir, intensity_files[[food]]))
    base_result <- read_origin_output(file.path(base_dir, paste0(food, "_disHarv.gdx")),
                                    intensity, country_lookup)
    base <- base_result$output
    eat_result <- read_origin_output(file.path(eat_dir, paste0(food, "_disHarv_eat.gdx")),
                                   intensity, country_lookup)
    eat <- eat_result$output
    # Include origins absent from either shipment result; their output is zero.
    origins <- union(names(base), names(eat))
    q_base <- unname(base[origins]); q_base[is.na(q_base)] <- 0
    q_eat <- unname(eat[origins]); q_eat[is.na(q_eat)] <- 0
    ef <- unname(intensity[origins])
    active <- q_base > 0 | q_eat > 0
    if (anyNA(ef[active])) stop("Missing intensity for active origins in ", food)
    ef[!active & is.na(ef)] <- 0
    reduction <- pmax(q_base - q_eat, 0)
    e_base <- sum(q_base * ef) / emission_divisor
    e_eat <- sum(q_eat * ef) / emission_divisor
    residual_full <- sum(reduction * ef) / emission_divisor
    results[[k]] <- data.frame(food = food, alpha = alphas,
      production_LFS_Base = sum(q_base), production_LFS_EAT = sum(q_eat),
      retained_production = alphas * sum(reduction),
      realized_production = sum(q_eat) + alphas * sum(reduction),
      emissions_LFS_Base = e_base, emissions_LFS_EAT = e_eat,
      additional_emissions = alphas * residual_full,
      realized_emissions = e_eat + alphas * residual_full)
    producer_country <- map_country(origins, "i", country_lookup$production)
    residual_country <- tapply(reduction * ef / emission_divisor, producer_country, sum)
    countries <- Reduce(union, list(names(base_result$consumption), names(eat_result$consumption), names(residual_country)))
    bau_consumption <- unname(base_result$consumption[countries]); bau_consumption[is.na(bau_consumption)] <- 0
    consumption <- unname(eat_result$consumption[countries]); consumption[is.na(consumption)] <- 0
    residual <- unname(residual_country[countries]); residual[is.na(residual)] <- 0
    country_results[[k]] <- do.call(rbind, lapply(alphas, function(a) {
      data.frame(food = food, alpha = a, country_ID_0.5 = countries,
        BAU_consumption_emissions = bau_consumption,
        consumption_emissions = consumption,
        additional_production_emissions = a * residual,
        adjusted_food_related_emissions = consumption + a * residual)
    }))
    country_check <- aggregate(adjusted_food_related_emissions ~ alpha, country_results[[k]], sum)
    expected <- results[[k]]$realized_emissions[match(country_check$alpha, results[[k]]$alpha)]
    if (!isTRUE(all.equal(country_check$adjusted_food_related_emissions, expected, tolerance = 1e-8))) {
      stop("Country/global emission totals do not match for ", food)
    }
    if (keep_origin_details) {
      detail <- data.frame(food = food, origin = origins, country_ID_0.5 = producer_country, Q_Base = q_base,
                           Q_EAT = q_eat, intensity = ef, production_reduction = reduction)
      for (a in alphas) {
        suffix <- format(a, scientific = FALSE, trim = TRUE)
        detail[[paste0("R_alpha_", suffix)]] <- q_eat + a * reduction
        detail[[paste0("emissions_alpha_", suffix)]] <- (q_eat + a * reduction) * ef / emission_divisor
      }
      origin_details[[food]] <- detail
    }
  }
  country_by_food <- do.call(rbind, country_results)
  country_total <- aggregate(country_by_food[, c("BAU_consumption_emissions", "consumption_emissions", "additional_production_emissions",
    "adjusted_food_related_emissions")],
    by = country_by_food[, c("alpha", "country_ID_0.5")], FUN = sum)
  by_food <- do.call(rbind, results)
  totals <- aggregate(by_food[, setdiff(names(by_food), c("food", "alpha"))],
                      by = list(alpha = by_food$alpha), FUN = sum)
  add_comparison <- function(d) {
    d$reduction_vs_LFS_Base <- d$emissions_LFS_Base - d$realized_emissions
    d$reduction_percent_vs_LFS_Base <- ifelse(d$emissions_LFS_Base == 0, NA_real_,
      100 * d$reduction_vs_LFS_Base / d$emissions_LFS_Base)
    d
  }
  by_food <- add_comparison(by_food); totals <- add_comparison(totals)
  totals$selected_foods <- paste(foods, collapse = ", ")
  # All five scenarios expose identical fields and emission column names.
  scenario_result <- function(global_column, country_column, alpha = alphas[1]) {
    select_alpha <- function(d) d[abs(d$alpha - alpha) < 1e-10, , drop = FALSE]
    extract_emissions <- function(d, keys, column) {
      out <- d[, c(keys, column), drop = FALSE]
      names(out)[names(out) == column] <- "food_related_emissions"
      rownames(out) <- NULL
      out
    }
    list(
      by_food = extract_emissions(select_alpha(by_food), "food", global_column),
      total = select_alpha(totals)[[global_column]],
      country_by_food = extract_emissions(select_alpha(country_by_food),
        c("food", "country_ID_0.5"), country_column),
      country_total = extract_emissions(select_alpha(country_total),
        "country_ID_0.5", country_column))
  }
  invisible(list(
    BAU = scenario_result("emissions_LFS_Base", "BAU_consumption_emissions"),
    EAT = scenario_result("emissions_LFS_EAT", "consumption_emissions"),
    EATR0 = scenario_result("realized_emissions", "adjusted_food_related_emissions", 0),
    EATR20 = scenario_result("realized_emissions", "adjusted_food_related_emissions", 0.2),
    EATR40 = scenario_result("realized_emissions", "adjusted_food_related_emissions", 0.4)))
}

sensitivity_results <- run_sensitivity()
BAU_results <- sensitivity_results$BAU
EAT_results <- sensitivity_results$EAT
EATR0_results <- sensitivity_results$EATR0
EATR20_results <- sensitivity_results$EATR20
EATR40_results <- sensitivity_results$EATR40

# Four-scenario comparison table; no files are exported.
emissions_comparison_table <- build_emissions_table(sensitivity_results)
