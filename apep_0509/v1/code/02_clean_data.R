# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 02_clean_data.R — Construct analysis panel with MGNREGA phase assignment
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# Load raw data
apy   <- readRDS(file.path(data_dir, "apy_raw.rds"))
fert  <- readRDS(file.path(data_dir, "fert_raw.rds"))
wages <- readRDS(file.path(data_dir, "wages_raw.rds"))
irr   <- readRDS(file.path(data_dir, "irr_raw.rds"))
rain  <- readRDS(file.path(data_dir, "rain_raw.rds"))
pop   <- readRDS(file.path(data_dir, "pop_raw.rds"))

# ==============================================================================
# 1. Construct MGNREGA Phase Assignment from Census 2001 data
# ==============================================================================
cat("=== Constructing MGNREGA Phase Assignment ===\n")

# Use Census 2001 population data
pop01 <- pop[Year == 2001]
cat(sprintf("Census 2001 observations: %d districts\n", nrow(pop01)))

# Compute backwardness index components
pop01[, `:=`(
  dist_code = `Dist Code`,
  state_code = `State Code`,
  state_name = `State Name`,
  dist_name = `Dist Name`,
  total_pop = `TOTAL POPULATION`,
  sc_pop = `SC TOTAL POPULATION`,
  st_pop = `ST TOTAL POPULATION`,
  lit_pop = `TOTAL LITERATES POPULATION`,
  ag_labor = `TOTAL AGRICULTURAL LABOUR POPULATION`,
  total_workers = `TOTAL WORKERS POPULATION`,
  lat = LATITUDE,
  lon = LONGITUDE
)]

# Remove districts with missing or zero population
pop01 <- pop01[!is.na(total_pop) & total_pop > 0]

# Compute index components
pop01[, `:=`(
  sc_st_share = (sc_pop + st_pop) / total_pop,
  lit_rate = lit_pop / total_pop,
  ag_labor_share = ag_labor / pmax(total_workers, 1)
)]

# Handle NAs
pop01[is.na(sc_st_share), sc_st_share := 0]
pop01[is.na(lit_rate), lit_rate := 0]
pop01[is.na(ag_labor_share), ag_labor_share := 0]

# Standardize and create composite backwardness index
# Higher = more backward (more SC/ST, more ag labor, less literate)
pop01[, backwardness_index :=
  scale(sc_st_share)[,1] +
  scale(ag_labor_share)[,1] +
  scale(-lit_rate)[,1]]

# Rank districts by backwardness (most backward = rank 1)
pop01[, backward_rank := frank(-backwardness_index)]

# Assign MGNREGA phases
# Phase I: 200 most backward districts (Feb 2006)
# Phase II: next 130 districts (Apr 2007)
# Phase III: remaining districts (Apr 2008)
n_dist <- nrow(pop01)
cat(sprintf("Districts with Census 2001 data: %d\n", n_dist))

pop01[, mgnrega_phase := fifelse(backward_rank <= 200, 1L,
                           fifelse(backward_rank <= 330, 2L, 3L))]

# First fully treated DLD year (agricultural year convention)
# Phase I (Feb 2006): first full ag year = 2006-07 = DLD year 2007
# Phase II (Apr 2007): first full ag year = 2007-08 = DLD year 2008
# Phase III (Apr 2008): first full ag year = 2008-09 = DLD year 2009
pop01[, first_treat_year := fifelse(mgnrega_phase == 1, 2007L,
                              fifelse(mgnrega_phase == 2, 2008L, 2009L))]

cat("\nMGNREGA Phase Distribution:\n")
print(pop01[, .(.N, mean_backward = mean(backwardness_index)),
            by = mgnrega_phase][order(mgnrega_phase)])

# Create baseline characteristics table
baseline <- pop01[, .(dist_code, state_code, state_name, dist_name,
                      lat, lon, total_pop,
                      sc_st_share, lit_rate, ag_labor_share,
                      backwardness_index, backward_rank,
                      mgnrega_phase, first_treat_year)]

# ==============================================================================
# 2. Define crop labor intensity classification
# ==============================================================================
cat("\n=== Classifying crops by labor intensity ===\n")

# Labor-intensive crops: require significant manual labor for planting,
# transplanting, weeding, harvesting
# Less labor-intensive: can be mechanized more easily
crop_classification <- data.table(
  crop = c("RICE", "WHEAT", "COTTON", "SUGARCANE", "MAIZE",
           "SORGHUM", "PEARL MILLET", "FINGER MILLET",
           "CHICKPEA", "PIGEONPEA", "GROUNDNUT",
           "RAPESEED AND MUSTARD", "SOYABEAN", "BARLEY",
           "SESAMUM", "CASTOR", "LINSEED", "SAFFLOWER", "SUNFLOWER"),
  labor_intensive = c(TRUE, FALSE, TRUE, TRUE, FALSE,
                      FALSE, FALSE, FALSE,
                      FALSE, FALSE, TRUE,
                      FALSE, FALSE, FALSE,
                      TRUE, FALSE, FALSE, FALSE, FALSE),
  crop_group = c("cereal", "cereal", "cash", "cash", "cereal",
                 "coarse_cereal", "coarse_cereal", "coarse_cereal",
                 "pulse", "pulse", "oilseed",
                 "oilseed", "oilseed", "cereal",
                 "oilseed", "oilseed", "oilseed", "oilseed", "oilseed")
)

cat("Labor-intensive crops: ", paste(crop_classification[labor_intensive == TRUE, crop], collapse = ", "), "\n")
cat("Less labor-intensive: ", paste(crop_classification[labor_intensive == FALSE, crop], collapse = ", "), "\n")

# ==============================================================================
# 3. Reshape crop yields to long format
# ==============================================================================
cat("\n=== Reshaping crop data to long format ===\n")

# Filter to analysis period (2000-2017)
apy_analysis <- apy[Year >= 2000 & Year <= 2017]

# Key crops for analysis
key_crops <- c("RICE", "WHEAT", "COTTON", "SUGARCANE", "MAIZE",
               "SORGHUM", "PEARL MILLET", "CHICKPEA", "PIGEONPEA",
               "GROUNDNUT", "SOYABEAN", "RAPESEED AND MUSTARD")

# Melt to long format: one row per district × year × crop
yield_cols <- paste(key_crops, "YIELD")
area_cols <- paste(key_crops, "AREA")
prod_cols <- paste(key_crops, "PRODUCTION")

# Build long panel
crop_long <- rbindlist(lapply(key_crops, function(crop) {
  yield_col <- paste(crop, "YIELD")
  area_col <- paste(crop, "AREA")
  prod_col <- paste(crop, "PRODUCTION")

  dt <- apy_analysis[, .(
    dist_code = `Dist Code`,
    year = Year,
    state_code = `State Code`,
    state_name = `State Name`,
    yield = get(yield_col),
    area = get(area_col),
    production = get(prod_col)
  )]
  dt[, crop := crop]
  return(dt)
}))

# Remove rows where yield is NA or zero (crop not grown in that district-year)
crop_long <- crop_long[!is.na(yield) & yield > 0 & !is.na(area) & area > 0]

# Add log yield
crop_long[, log_yield := log(yield)]

# Merge crop classification
crop_long <- merge(crop_long, crop_classification, by = "crop", all.x = TRUE)

cat(sprintf("Crop panel: %d obs, %d districts, %d crops, years %d-%d\n",
            nrow(crop_long), length(unique(crop_long$dist_code)),
            length(unique(crop_long$crop)),
            min(crop_long$year), max(crop_long$year)))

# ==============================================================================
# 4. Merge MGNREGA treatment assignment
# ==============================================================================
cat("\n=== Merging MGNREGA treatment ===\n")

crop_long <- merge(crop_long, baseline[, .(dist_code, mgnrega_phase, first_treat_year,
                                           sc_st_share, lit_rate, ag_labor_share,
                                           backwardness_index, lat, lon)],
                   by = "dist_code", all.x = TRUE)

# Remove districts without phase assignment (shouldn't happen)
crop_long <- crop_long[!is.na(mgnrega_phase)]

# Create treatment indicators
crop_long[, `:=`(
  post = as.integer(year >= first_treat_year),
  treated = as.integer(mgnrega_phase <= 2),  # Phase I/II treated before Phase III
  event_time = year - first_treat_year
)]

# For CS-DiD: cohort variable (first treatment year, 0 for never-treated)
# Since all districts are eventually treated, use Infinity for Phase III
# until 2009, then they become treated
crop_long[, cohort := first_treat_year]

cat(sprintf("Analysis panel: %d obs\n", nrow(crop_long)))
cat("Phase × post distribution:\n")
print(crop_long[, .N, by = .(mgnrega_phase, post)][order(mgnrega_phase, post)])

# ==============================================================================
# 5. Prepare fertilizer panel
# ==============================================================================
cat("\n=== Preparing fertilizer panel ===\n")

fert_panel <- fert[Year >= 2000 & Year <= 2017,
                   .(dist_code = `Dist Code`, year = Year,
                     nitrogen_ha = `NITROGEN PER HA OF GCA`,
                     phosphate_ha = `PHOSPHATE PER HA OF GCA`,
                     potash_ha = `POTASH PER HA OF GCA`,
                     total_fert_ha = `TOTAL PER HA OF GCA`)]

fert_panel <- fert_panel[!is.na(total_fert_ha) & total_fert_ha >= 0]
fert_panel[total_fert_ha > 0, log_fert_total := log(total_fert_ha)]

fert_panel <- merge(fert_panel, baseline[, .(dist_code, state_code, mgnrega_phase, first_treat_year)],
                    by = "dist_code", all.x = TRUE)
fert_panel <- fert_panel[!is.na(mgnrega_phase)]
fert_panel[, `:=`(post = as.integer(year >= first_treat_year),
                   event_time = year - first_treat_year,
                   cohort = first_treat_year)]

cat(sprintf("Fertilizer panel: %d obs, %d districts\n",
            nrow(fert_panel), length(unique(fert_panel$dist_code))))

# ==============================================================================
# 6. Prepare wages panel
# ==============================================================================
cat("\n=== Preparing wages panel ===\n")

wage_panel <- wages[Year >= 2000 & Year <= 2013,
                    .(dist_code = `Dist Code`, year = Year,
                      wage_male = `DISTRICT MALE FIELD LABOUR`,
                      wage_female = `DISTRICT FEMALE FIELD LABOUR`,
                      state_wage_male = `STATE MALE AVERAGE FIELD LABOUR`,
                      state_wage_female = `STATE FEMALE AVERAGE FIELD LABOUR`)]

wage_panel <- wage_panel[!is.na(wage_male) & wage_male > 0]
wage_panel[, `:=`(log_wage_male = log(wage_male),
                   log_wage_female = log(wage_female))]

wage_panel <- merge(wage_panel, baseline[, .(dist_code, state_code, mgnrega_phase, first_treat_year)],
                    by = "dist_code", all.x = TRUE)
wage_panel <- wage_panel[!is.na(mgnrega_phase)]
wage_panel[, `:=`(post = as.integer(year >= first_treat_year),
                   event_time = year - first_treat_year,
                   cohort = first_treat_year)]

cat(sprintf("Wage panel: %d obs, %d districts, years %d-%d\n",
            nrow(wage_panel), length(unique(wage_panel$dist_code)),
            min(wage_panel$year), max(wage_panel$year)))

# ==============================================================================
# 7. Prepare irrigation panel
# ==============================================================================
cat("\n=== Preparing irrigation panel ===\n")

# Extract irrigated area for key crops
irr_long <- rbindlist(lapply(key_crops, function(crop) {
  irr_col <- paste(crop, "IRRIGATED AREA")
  if (!irr_col %in% names(irr)) return(NULL)
  dt <- irr[Year >= 2000 & Year <= 2017,
            .(dist_code = `Dist Code`, year = Year,
              irr_area = get(irr_col))]
  dt[, crop := crop]
  return(dt)
}))

irr_long <- irr_long[!is.na(irr_area)]

# Merge with crop area to get irrigated share
irr_panel <- merge(crop_long[, .(dist_code, year, crop, area)],
                   irr_long,
                   by = c("dist_code", "year", "crop"), all.x = TRUE)
irr_panel[, irr_share := fifelse(!is.na(irr_area) & area > 0,
                                  pmin(irr_area / area, 1), NA_real_)]

cat(sprintf("Irrigation panel: %d obs with non-missing irr_share\n",
            sum(!is.na(irr_panel$irr_share))))

# ==============================================================================
# 8. Prepare rainfall controls
# ==============================================================================
cat("\n=== Preparing rainfall controls ===\n")

rain_panel <- rain[Year >= 2000,
                   .(dist_code = `Dist Code`, year = Year,
                     annual_rain = `ANNUAL RAINFALL`)]
rain_panel <- rain_panel[!is.na(annual_rain)]

# Note: ICRISAT rainfall data ends in 2003. Will use for pre-period controls only.
cat(sprintf("Rainfall: %d obs, years %d-%d\n",
            nrow(rain_panel), min(rain_panel$year), max(rain_panel$year)))
if (max(rain_panel$year) < 2010) {
  cat("WARNING: Rainfall data ends before treatment period. Using baseline rainfall as control.\n")
  # Compute district-level average rainfall as baseline control
  rain_baseline <- rain[Year >= 1990 & Year <= 2003,
                        .(mean_rainfall = mean(`ANNUAL RAINFALL`, na.rm = TRUE),
                          sd_rainfall = sd(`ANNUAL RAINFALL`, na.rm = TRUE)),
                        by = .(`Dist Code`)]
  setnames(rain_baseline, "Dist Code", "dist_code")
  saveRDS(rain_baseline, file.path(data_dir, "rain_baseline.rds"))
}

# ==============================================================================
# 9. Create aggregate district-year panel
# ==============================================================================
cat("\n=== Creating aggregate district-year panel ===\n")

# Aggregate yields across crops (area-weighted)
agg_panel <- crop_long[, .(
  total_area = sum(area, na.rm = TRUE),
  total_production = sum(production, na.rm = TRUE),
  n_crops = .N,
  # Area-weighted average yield
  avg_yield = weighted.mean(yield, area, na.rm = TRUE),
  # Share of labor-intensive crops
  labor_intensive_share = sum(area[labor_intensive == TRUE], na.rm = TRUE) /
    sum(area, na.rm = TRUE),
  # HHI (crop concentration)
  hhi = sum((area / sum(area, na.rm = TRUE))^2, na.rm = TRUE)
), by = .(dist_code, year, state_code, state_name, mgnrega_phase,
          first_treat_year, sc_st_share, lit_rate, ag_labor_share,
          backwardness_index)]

agg_panel[, `:=`(
  log_avg_yield = log(avg_yield),
  diversification = 1 - hhi,
  post = as.integer(year >= first_treat_year),
  event_time = year - first_treat_year,
  cohort = first_treat_year
)]

# Merge fertilizer
agg_panel <- merge(agg_panel,
                   fert_panel[, .(dist_code, year, total_fert_ha, log_fert_total)],
                   by = c("dist_code", "year"), all.x = TRUE)

# Merge wages
agg_panel <- merge(agg_panel,
                   wage_panel[, .(dist_code, year, wage_male, log_wage_male,
                                  wage_female, log_wage_female)],
                   by = c("dist_code", "year"), all.x = TRUE)

# Merge rainfall baseline
if (exists("rain_baseline")) {
  agg_panel <- merge(agg_panel, rain_baseline, by = "dist_code", all.x = TRUE)
}

cat(sprintf("Aggregate panel: %d obs, %d districts, years %d-%d\n",
            nrow(agg_panel), length(unique(agg_panel$dist_code)),
            min(agg_panel$year), max(agg_panel$year)))

# ==============================================================================
# 10. Save analysis-ready datasets
# ==============================================================================
cat("\n=== Saving analysis datasets ===\n")

saveRDS(crop_long, file.path(data_dir, "crop_panel.rds"))
saveRDS(fert_panel, file.path(data_dir, "fert_panel.rds"))
saveRDS(wage_panel, file.path(data_dir, "wage_panel.rds"))
saveRDS(irr_panel, file.path(data_dir, "irr_panel.rds"))
saveRDS(agg_panel, file.path(data_dir, "agg_panel.rds"))
saveRDS(baseline, file.path(data_dir, "baseline.rds"))
saveRDS(crop_classification, file.path(data_dir, "crop_classification.rds"))

cat("All datasets saved successfully.\n")

# Print summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Districts: %d across %d states\n",
            nrow(baseline), length(unique(baseline$state_code))))
cat(sprintf("Phase I districts: %d\n", sum(baseline$mgnrega_phase == 1)))
cat(sprintf("Phase II districts: %d\n", sum(baseline$mgnrega_phase == 2)))
cat(sprintf("Phase III districts: %d\n", sum(baseline$mgnrega_phase == 3)))
cat(sprintf("Crop-district-year obs: %d\n", nrow(crop_long)))
cat(sprintf("Crops analyzed: %s\n", paste(key_crops, collapse = ", ")))
cat(sprintf("Year range: %d-%d\n", min(crop_long$year), max(crop_long$year)))
