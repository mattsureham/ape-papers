## 02_clean_data.R — Construct analysis panel
## Municipality-year panel: business counts, employment, urbanization

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Process CEMPRE raw files (Tables 6449 and 6450)
# ============================================================================
cat("=== Processing CEMPRE data ===\n")

# Table 6449: enterprises (variable 2585 = n_enterprises, 707 = employment, 662 = wages)
# Table 6450: local units (variable 706 = n_units, 707 = employment, 708 = salaried, 662 = wages)

process_cempre <- function(table_id, years) {
  results <- list()
  for (yr in years) {
    fpath <- file.path(data_dir, sprintf("raw_%s_%d.csv", table_id, yr))
    if (!file.exists(fpath) || file.size(fpath) < 100) next

    dt <- fread(fpath)
    dt[, muni_code := as.integer(substr(D1C, 1, 7))]
    dt[, year := yr]
    dt[, var_code := as.integer(D2C)]
    dt[, value := as.numeric(gsub("[^0-9.-]", "", V))]

    # Keep only the key variables (not percentages)
    dt <- dt[var_code < 100000 & !is.na(value), .(muni_code, year, var_code, value)]
    results[[length(results) + 1]] <- dt
  }
  rbindlist(results)
}

# Table 6449: enterprises (2015-2021)
ent_long <- process_cempre("6449", 2015:2021)
ent_wide <- dcast(ent_long, muni_code + year ~ var_code, value.var = "value")
setnames(ent_wide, old = c("2585", "707", "708", "662"),
         new = c("n_enterprises", "emp_total_ent", "emp_salaried_ent", "wages_ent"),
         skip_absent = TRUE)
cat(sprintf("Enterprises: %d rows, %d munis, years %s\n",
            nrow(ent_wide), uniqueN(ent_wide$muni_code),
            paste(sort(unique(ent_wide$year)), collapse=",")))

# Table 6450: local units (2015-2021)
unit_long <- process_cempre("6450", 2015:2021)
unit_wide <- dcast(unit_long, muni_code + year ~ var_code, value.var = "value")
setnames(unit_wide, old = c("706", "707", "708", "662"),
         new = c("n_units", "emp_total", "emp_salaried", "wages"),
         skip_absent = TRUE)
cat(sprintf("Local units: %d rows, %d munis\n", nrow(unit_wide), uniqueN(unit_wide$muni_code)))

# ============================================================================
# 2. Load population data
# ============================================================================
cat("\n=== Loading population ===\n")
pop <- fread(file.path(data_dir, "population.csv"))
cat(sprintf("Population: %d rows, years %s\n", nrow(pop), paste(sort(unique(pop$year)), collapse=",")))

# 2022 population is missing from SIDRA — extrapolate from 2021
if (!2022 %in% pop$year) {
  # Use 2021 population for 2022 (conservative)
  pop_2022 <- pop[year == 2021]
  pop_2022[, year := 2022L]
  pop <- rbindlist(list(pop, pop_2022))
  cat("Extrapolated 2022 population from 2021\n")
}

# Extrapolate earlier years from 2019
for (yr in c(2015, 2016, 2017, 2018)) {
  if (!yr %in% pop$year) {
    pop_yr <- pop[year == 2019]
    pop_yr[, year := as.integer(yr)]
    pop <- rbindlist(list(pop, pop_yr))
    cat(sprintf("Extrapolated %d population from 2019\n", yr))
  }
}

# ============================================================================
# 3. Load Census 2010 urbanization instrument
# ============================================================================
cat("\n=== Loading census instrument ===\n")
census <- fread(file.path(data_dir, "census_2010.csv"))
cat(sprintf("Census: %d municipalities, urban_share mean=%.3f sd=%.3f\n",
            nrow(census), mean(census$urban_share, na.rm=TRUE),
            sd(census$urban_share, na.rm=TRUE)))

# ============================================================================
# 4. Merge into analysis panel
# ============================================================================
cat("\n=== Constructing panel ===\n")

# Primary panel: enterprises (Table 6449) merged with local units (Table 6450)
panel <- merge(ent_wide, unit_wide, by = c("muni_code", "year"), all = TRUE)
panel <- merge(panel, pop[, .(muni_code, year, population, state_code)],
               by = c("muni_code", "year"), all.x = TRUE)
panel <- merge(panel, census[, .(muni_code, urban_share, total_pop_2010)],
               by = "muni_code", all.x = TRUE)

# Drop if missing population or urban share
panel <- panel[!is.na(population) & !is.na(urban_share) & population > 0]

# ============================================================================
# 5. Construct key variables
# ============================================================================
cat("\n=== Constructing variables ===\n")

# Treatment variables
panel[, post := as.integer(year >= 2021)]  # Pix launched Nov 2020; 2021 is first full post year
panel[, treat_intensity := urban_share]      # Continuous treatment intensity
panel[, treat_x_post := urban_share * post]  # Interaction

# Per-capita outcomes (per 10,000 population)
panel[, enterprises_pc := (n_enterprises / population) * 10000]
panel[, units_pc := (n_units / population) * 10000]
panel[, emp_pc := (emp_total / population) * 10000]
panel[, wages_pc := (wages / population) * 10000]

# Log outcomes (for elasticity interpretation)
panel[, log_enterprises := log(n_enterprises + 1)]
panel[, log_units := log(n_units + 1)]
panel[, log_emp := log(emp_total + 1)]

# Urbanization quartiles (for event study / heterogeneity)
panel[, urban_quartile := cut(urban_share,
                              breaks = quantile(urban_share, probs = 0:4/4, na.rm = TRUE),
                              include.lowest = TRUE, labels = paste0("Q", 1:4))]

# Municipality size categories
panel[, size_cat := cut(population,
                        breaks = c(0, 10000, 50000, 200000, Inf),
                        labels = c("Small (<10K)", "Medium (10-50K)", "Large (50-200K)", "Metro (>200K)"))]

# Region (from state code)
panel[, region := fcase(
  state_code %in% c(11,12,13,14,15,16,17), "North",
  state_code %in% c(21,22,23,24,25,26,27,28,29), "Northeast",
  state_code %in% c(31,32,33,35), "Southeast",
  state_code %in% c(41,42,43), "South",
  state_code %in% c(50,51,52,53), "Center-West"
)]

# ============================================================================
# 6. Summary statistics
# ============================================================================
cat("\n=== Panel summary ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Municipalities: %d\n", uniqueN(panel$muni_code)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse=", ")))
cat(sprintf("States: %d\n", uniqueN(panel$state_code)))

cat("\nKey outcomes (mean, sd):\n")
for (v in c("enterprises_pc", "units_pc", "emp_pc", "n_enterprises", "n_units")) {
  cat(sprintf("  %-20s mean=%.1f  sd=%.1f\n", v,
              mean(panel[[v]], na.rm=TRUE), sd(panel[[v]], na.rm=TRUE)))
}

cat("\nBy treatment period:\n")
panel[, .(
  n = .N,
  mean_ent_pc = mean(enterprises_pc, na.rm=TRUE),
  mean_units_pc = mean(units_pc, na.rm=TRUE),
  mean_emp_pc = mean(emp_pc, na.rm=TRUE)
), by = post][order(post)] |> print()

cat("\nBy urbanization quartile:\n")
panel[, .(
  n_munis = uniqueN(muni_code),
  mean_ent_pc = mean(enterprises_pc, na.rm=TRUE),
  mean_urban = mean(urban_share, na.rm=TRUE)
), by = urban_quartile][order(urban_quartile)] |> print()

# ============================================================================
# 7. Save
# ============================================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis panel: %d rows, %d columns\n", nrow(panel), ncol(panel)))

# Also save a BCB Pix time series for descriptive use
pix_files <- list.files(data_dir, pattern = "bcb_series_", full.names = TRUE)
if (length(pix_files) > 0) {
  pix_list <- lapply(pix_files, function(f) {
    dt <- fread(f)
    dt[, series := gsub(".*series_|\\.csv", "", basename(f))]
    dt
  })
  pix_all <- rbindlist(pix_list, fill = TRUE)
  fwrite(pix_all, file.path(data_dir, "pix_national.csv"))
  cat(sprintf("Pix national time series: %d rows\n", nrow(pix_all)))
}

cat("\n=== Cleaning complete ===\n")
