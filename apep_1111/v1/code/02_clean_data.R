# 02_clean_data.R — Construct analysis panel
# Merges: Census BPS (outcome) + FEMA Claims (treatment) + Population + LAUS

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1. Clean Building Permits Survey
# ============================================================================
cat("=== Cleaning Building Permits Survey ===\n")

bps_list <- readRDS(file.path(data_dir, "bps_raw_list.rds"))

# BPS has multi-row header; first row = categories, second = variable names
# The actual data columns based on inspection:
# Survey(year), StateFIPS, CountyFIPS, RegionCode, DivisionCode, CountyName,
# 1-unit: Bldgs, Units, Value
# 2-units: Bldgs, Units, Value
# 3-4 units: Bldgs, Units, Value
# 5+ units: Bldgs, Units, Value
# Then reported (rep) versions of the same

clean_bps <- function(df) {
  # Column names already assigned in fetch step
  df %>%
    mutate(
      across(c(state_fips, county_fips), ~trimws(as.character(.))),
      state_fips = str_pad(state_fips, 2, pad = "0"),
      county_fips = str_pad(county_fips, 3, pad = "0"),
      fips = paste0(state_fips, county_fips),
      year = as.integer(survey_year),
      county_name = trimws(as.character(county_name)),
      across(matches("_bldgs|_units|_value"), ~as.numeric(gsub(",", "", as.character(.))))
    ) %>%
    filter(!is.na(year), year >= 2000) %>%
    mutate(
      total_units = coalesce(u1_units, 0L) + coalesce(u2_units, 0L) +
                    coalesce(u34_units, 0L) + coalesce(u5p_units, 0L),
      total_bldgs = coalesce(u1_bldgs, 0L) + coalesce(u2_bldgs, 0L) +
                    coalesce(u34_bldgs, 0L) + coalesce(u5p_bldgs, 0L),
      total_value = coalesce(u1_value, 0) + coalesce(u2_value, 0) +
                    coalesce(u34_value, 0) + coalesce(u5p_value, 0),
      single_family_units = coalesce(u1_units, 0L),
      multifamily_units = coalesce(u2_units, 0L) + coalesce(u34_units, 0L) +
                          coalesce(u5p_units, 0L)
    ) %>%
    select(fips, state_fips, county_fips, county_name, year,
           total_units, total_bldgs, total_value,
           single_family_units, multifamily_units,
           u1_units, u2_units, u34_units, u5p_units)
}

# Clean each year and bind
bps_clean <- bind_rows(lapply(bps_list, clean_bps))
cat(sprintf("BPS cleaned: %d rows, %d counties, years %d-%d\n",
            nrow(bps_clean), n_distinct(bps_clean$fips),
            min(bps_clean$year), max(bps_clean$year)))

# Drop rows with zero total (likely non-reporting)
bps_clean <- bps_clean %>%
  filter(!is.na(total_units))

saveRDS(bps_clean, file.path(data_dir, "bps_clean.rds"))

# ============================================================================
# 2. Construct Treatment Intensity from Claims
# ============================================================================
cat("\n=== Constructing treatment intensity ===\n")

claims_county <- readRDS(file.path(data_dir, "claims_county.rds"))

# Load population for per-capita normalization
pop_file <- file.path(data_dir, "county_population.rds")
if (file.exists(pop_file)) {
  pop_df <- readRDS(pop_file)
  cat(sprintf("Population data: %d counties\n", nrow(pop_df)))

  # Merge claims with population
  treatment <- claims_county %>%
    left_join(pop_df %>% select(fips, population), by = "fips") %>%
    mutate(
      claims_per_1000 = ifelse(population > 0,
                               pre_rr2_claims / (population / 1000), 0),
      paid_per_capita = ifelse(population > 0,
                               pre_rr2_paid_millions * 1e6 / population, 0)
    )
} else {
  treatment <- claims_county %>%
    mutate(claims_per_1000 = NA, paid_per_capita = NA)
}

cat(sprintf("Treatment data: %d counties with claims\n", nrow(treatment)))
cat(sprintf("  Claims per 1000 range: %.1f to %.1f\n",
            min(treatment$claims_per_1000, na.rm = TRUE),
            max(treatment$claims_per_1000, na.rm = TRUE)))
cat(sprintf("  Paid per capita range: $%.0f to $%.0f\n",
            min(treatment$paid_per_capita, na.rm = TRUE),
            max(treatment$paid_per_capita, na.rm = TRUE)))

saveRDS(treatment, file.path(data_dir, "treatment_intensity.rds"))

# ============================================================================
# 3. Clean LAUS (if available)
# ============================================================================
laus_file <- file.path(data_dir, "laus_raw.rds")
if (file.exists(laus_file)) {
  cat("\n=== Cleaning LAUS data ===\n")
  laus_raw <- readRDS(laus_file)

  # LAUS series_id format: LAUCN[FIPS]0000000[measure]
  # measure: 3 = unemployment rate, 4 = unemployment, 5 = employment, 6 = labor force
  laus_clean <- laus_raw %>%
    mutate(
      series_id = trimws(series_id),
      fips = substr(series_id, 6, 10),
      measure = substr(series_id, 19, 19),
      year = as.integer(year),
      period = trimws(period),
      value = as.numeric(trimws(value))
    ) %>%
    filter(
      measure == "3",  # Unemployment rate
      period == "M13", # Annual average
      year >= 2010
    ) %>%
    select(fips, year, unemp_rate = value)

  saveRDS(laus_clean, file.path(data_dir, "laus_clean.rds"))
  cat(sprintf("LAUS cleaned: %d county-year obs\n", nrow(laus_clean)))
}

# ============================================================================
# 4. Merge into Analysis Panel
# ============================================================================
cat("\n=== Building analysis panel ===\n")

# Start with BPS (outcome)
panel <- bps_clean %>%
  select(fips, state_fips, county_name, year,
         total_units, single_family_units, multifamily_units, total_value)

# Merge treatment intensity (cross-sectional)
panel <- panel %>%
  left_join(
    treatment %>% select(fips, total_claims, pre_rr2_claims,
                         claims_per_1000, paid_per_capita),
    by = "fips"
  )

# Merge unemployment
if (file.exists(file.path(data_dir, "laus_clean.rds"))) {
  laus_clean <- readRDS(file.path(data_dir, "laus_clean.rds"))
  panel <- panel %>%
    left_join(laus_clean, by = c("fips", "year"))
}

# Merge population
if (file.exists(pop_file)) {
  pop_df <- readRDS(pop_file)
  panel <- panel %>%
    left_join(pop_df %>% select(fips, population), by = "fips")
}

# Create analysis variables
panel <- panel %>%
  mutate(
    # Treatment timing
    post = as.integer(year >= 2022),  # RR2.0 fully in effect from April 2022
    # Log permits (adding 1 to handle zeros)
    log_total_units = log(total_units + 1),
    log_sf_units = log(single_family_units + 1),
    log_mf_units = log(multifamily_units + 1),
    # Permits per capita
    permits_per_1000 = ifelse(!is.na(population) & population > 0,
                              total_units / (population / 1000), NA),
    # Treatment intensity quintiles
    treatment_q = ntile(claims_per_1000, 5),
    # High-exposure indicator (top quintile)
    high_exposure = as.integer(treatment_q == 5)
  )

# Remove counties with no treatment data
panel <- panel %>%
  filter(!is.na(claims_per_1000))

cat(sprintf("Analysis panel: %d obs, %d counties, years %d-%d\n",
            nrow(panel), n_distinct(panel$fips),
            min(panel$year), max(panel$year)))
cat(sprintf("  Post-RR2.0 obs: %d\n", sum(panel$post == 1)))
cat(sprintf("  Pre-RR2.0 obs: %d\n", sum(panel$post == 0)))

# Summary stats
cat(sprintf("\n  Permits/year: mean=%.0f, median=%.0f, sd=%.0f\n",
            mean(panel$total_units, na.rm = TRUE),
            median(panel$total_units, na.rm = TRUE),
            sd(panel$total_units, na.rm = TRUE)))
cat(sprintf("  Claims per 1000: mean=%.1f, p25=%.1f, p75=%.1f\n",
            mean(panel$claims_per_1000, na.rm = TRUE),
            quantile(panel$claims_per_1000, 0.25, na.rm = TRUE),
            quantile(panel$claims_per_1000, 0.75, na.rm = TRUE)))

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

# Write diagnostics.json for validation
n_pre <- length(unique(panel$year[panel$post == 0]))
n_treated <- n_distinct(panel$fips[panel$treatment_q >= 4])  # Top 2 quintiles
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = n_distinct(panel$fips),
  years = paste(range(panel$year), collapse = "-"),
  treatment_var = "claims_per_1000 (pre-RR2.0 NFIP claims per 1000 population)"
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Panel construction complete.\n")
