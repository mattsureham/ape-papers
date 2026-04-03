## ==========================================================
## 03_main_analysis.R — Main regressions (state-level panel)
## Paper: Obsolete by Design (apep_1339)
## Key: state abbreviation (state_abbr / state) throughout
## ==========================================================

source("00_packages.R")

data_dir <- "../data"

## -----------------------------------------------------------
## 0. nClimDiv state_code → 2-letter abbreviation crosswalk
##    nClimDiv codes are alphabetical by state name (01=AL, 02=AZ, …)
##    This is NOT the same as FIPS state codes.
## -----------------------------------------------------------

nclim_state_xwalk <- data.table(
  state_code = 1:48,
  state_abbr = c(
    "AL", "AZ", "AR", "CA", "CO", "CT", "DE", "FL",
    "GA", "ID", "IL", "IN", "IA", "KS", "KY", "LA",
    "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT",
    "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND",
    "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN",
    "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
  )
)

## -----------------------------------------------------------
## 1. Load datasets
## -----------------------------------------------------------
cat("=== Loading data ===\n")

dams       <- fread(file.path(data_dir, "dams_clean.csv"))
decl_raw   <- fread(file.path(data_dir, "fema_flood_declarations.csv"))
nclim      <- fread(file.path(data_dir, "nclim_precip.csv"))
claims_raw <- fread(file.path(data_dir, "nfip_claims.csv"))

cat("Dams rows:", nrow(dams), "\n")
cat("FEMA rows:", nrow(decl_raw), "\n")
cat("nClimDiv rows:", nrow(nclim), "\n")
cat("NFIP rows:", nrow(claims_raw), "\n")

## -----------------------------------------------------------
## 2. State-level dam statistics (key = state_abbr)
## -----------------------------------------------------------
cat("\n=== Aggregating dams by state (state_abbr) ===\n")

# Coerce numerics before aggregation (avoids data.table type errors)
dams[, `:=`(
  storage_acft   = as.double(storage_acft),
  dam_height_ft  = as.double(dam_height_ft),
  year_built     = as.double(year_built),
  pre1970        = as.integer(pre1970),
  high_hazard    = as.integer(high_hazard),
  lat            = as.double(lat),
  lon            = as.double(lon)
)]

# Drop rows without a valid state abbreviation
dams <- dams[!is.na(state_abbr) & state_abbr != ""]

state_dams <- dams[, .(
  n_dams           = .N,
  n_pre1970        = as.double(sum(pre1970,             na.rm = TRUE)),
  n_post1970       = as.double(sum(1L - pre1970,        na.rm = TRUE)),
  n_high_hazard    = as.double(sum(high_hazard,         na.rm = TRUE)),
  n_pre1970_high   = as.double(sum(pre1970 * high_hazard, na.rm = TRUE)),
  total_storage    = as.double(sum(storage_acft,        na.rm = TRUE)),
  pre1970_storage  = as.double(sum(storage_acft * pre1970, na.rm = TRUE)),
  mean_year_built  = as.double(mean(year_built,         na.rm = TRUE)),
  median_year      = as.double(median(year_built,       na.rm = TRUE)),
  mean_dam_height  = as.double(mean(dam_height_ft,      na.rm = TRUE)),
  mean_lat         = as.double(mean(lat,                na.rm = TRUE)),
  mean_lon         = as.double(mean(lon,                na.rm = TRUE))
), by = state_abbr]

state_dams[, `:=`(
  pre1970_share      = n_pre1970 / n_dams,
  pre1970_high_share = n_pre1970_high / pmax(as.double(n_dams), 1),
  log_n_dams         = log1p(as.double(n_dams)),
  log_pre1970        = log1p(n_pre1970),
  log_storage        = log1p(total_storage),
  dam_age            = 2024 - mean_year_built
)]

cat("States with dam data:", nrow(state_dams), "\n")
cat("Summary of pre-1970 share:\n")
print(summary(state_dams$pre1970_share))

## -----------------------------------------------------------
## 3. State-year flood declarations (key = state abbr + year)
##    decl_raw$state is already a 2-letter abbreviation
## -----------------------------------------------------------
cat("\n=== Aggregating FEMA declarations by state-year ===\n")

decl_raw[, decl_year := as.integer(substr(declarationDate, 1, 4))]

# One record per county-disaster; collapse to state-year unique disasters
state_year_decl <- decl_raw[decl_year >= 2000 & decl_year <= 2024, .(
  n_disasters  = as.double(uniqueN(disasterNumber)),
  n_flood_decl = as.double(.N)
), by = .(state_abbr = state, year = decl_year)]

cat("State-year flood observations:", nrow(state_year_decl), "\n")

## -----------------------------------------------------------
## 4. State-year NFIP claims (key = state abbr + year)
##    claims_raw$state is a 2-letter abbreviation
## -----------------------------------------------------------
cat("\n=== Aggregating NFIP claims by state-year ===\n")

cat("  NFIP state sample:", head(unique(claims_raw$state), 8), "\n")

claims_raw[, `:=`(
  claim_year   = as.integer(yearOfLoss),
  paid_bldg    = as.double(amountPaidOnBuildingClaim),
  paid_cont    = as.double(amountPaidOnContentsClaim)
)]

state_year_claims <- claims_raw[
  claim_year >= 2000 & claim_year <= 2024 &
    !is.na(state) & state != "",
  .(
    n_claims   = as.double(.N),
    total_paid = as.double(sum(paid_bldg, na.rm = TRUE) +
                             sum(paid_cont, na.rm = TRUE))
  ),
  by = .(state_abbr = state, year = claim_year)
]

cat("State-year claim observations:", nrow(state_year_claims), "\n")

## -----------------------------------------------------------
## 5. Precipitation trends by state
##    nClimDiv state_code (1-48, alphabetical) → state_abbr via crosswalk
## -----------------------------------------------------------
cat("\n=== Computing precipitation trends ===\n")

# Average across climate divisions within each nClimDiv state_code
nclim_state <- nclim[, .(
  annual_precip = as.double(mean(annual_precip, na.rm = TRUE)),
  max_monthly   = as.double(mean(max_monthly,   na.rm = TRUE))
), by = .(state_code, year)]

# Design era: when pre-1970 dams were engineered
design_era <- nclim_state[year >= 1950 & year <= 1969, .(
  precip_design    = as.double(mean(annual_precip, na.rm = TRUE)),
  max_month_design = as.double(mean(max_monthly,   na.rm = TRUE))
), by = state_code]

# Modern era: current climate reality dams face
modern_era <- nclim_state[year >= 2000 & year <= 2019, .(
  precip_modern    = as.double(mean(annual_precip, na.rm = TRUE)),
  max_month_modern = as.double(mean(max_monthly,   na.rm = TRUE))
), by = state_code]

precip_trend <- merge(design_era, modern_era, by = "state_code")
precip_trend[, `:=`(
  precip_change    = as.double(precip_modern    - precip_design),
  precip_ratio     = as.double(precip_modern    / precip_design),
  max_month_change = as.double(max_month_modern - max_month_design),
  max_month_ratio  = as.double(max_month_modern / max_month_design)
)]

# Attach state abbreviation via crosswalk
precip_trend <- merge(precip_trend, nclim_state_xwalk, by = "state_code", all.x = TRUE)

# Collapse to state level (crosswalk is 1:1, but guard against duplicates)
precip_state <- precip_trend[!is.na(state_abbr), .(
  precip_design    = as.double(mean(precip_design,    na.rm = TRUE)),
  precip_modern    = as.double(mean(precip_modern,    na.rm = TRUE)),
  precip_ratio     = as.double(mean(precip_ratio,     na.rm = TRUE)),
  precip_change    = as.double(mean(precip_change,    na.rm = TRUE)),
  max_month_ratio  = as.double(mean(max_month_ratio,  na.rm = TRUE)),
  max_month_change = as.double(mean(max_month_change, na.rm = TRUE))
), by = state_abbr]

cat("States with precipitation trend:", nrow(precip_state), "\n")
cat("Mean precip ratio:", round(mean(precip_state$precip_ratio, na.rm = TRUE), 3), "\n")
cat("Range:", round(range(precip_state$precip_ratio, na.rm = TRUE), 3), "\n")

## -----------------------------------------------------------
## 6. Build balanced state-year panel (key = state_abbr × year)
## -----------------------------------------------------------
cat("\n=== Building state-year panel ===\n")

# Ensure one row per state in dam table (safety dedup)
state_dams <- unique(state_dams, by = "state_abbr")

states <- sort(unique(state_dams$state_abbr))
years  <- 2000:2024

panel <- CJ(state_abbr = states, year = years)

# Merge dam characteristics (time-invariant)
panel <- merge(panel, state_dams,  by = "state_abbr", all.x = TRUE)

# Merge precipitation trend (time-invariant)
panel <- merge(panel, precip_state, by = "state_abbr", all.x = TRUE)

# Merge FEMA declarations (time-varying)
panel <- merge(panel, state_year_decl,
               by = c("state_abbr", "year"), all.x = TRUE)

# Merge NFIP claims (time-varying)
panel <- merge(panel, state_year_claims,
               by = c("state_abbr", "year"), all.x = TRUE)

# Fill missing outcomes with 0 (no declaration / no claims in that year)
panel[is.na(n_flood_decl), n_flood_decl := 0L]
panel[is.na(n_disasters),  n_disasters  := 0L]
panel[is.na(n_claims),     n_claims     := 0L]
panel[is.na(total_paid),   total_paid   := 0]

# Binary outcome variables
panel[, `:=`(
  flood_declared = as.integer(n_flood_decl > 0),
  any_claims     = as.integer(n_claims     > 0)
)]

# Design gap: pre-1970 share × precipitation ratio (interaction term)
# Higher = more dams designed under wetter/drier conditions that now differ
panel[, design_gap := pre1970_share * fifelse(is.na(precip_ratio), 1, precip_ratio)]

# Numeric state identifier for fixed effects
panel[, state_id := as.integer(factor(state_abbr))]

cat("Panel rows:", nrow(panel), "\n")
cat("States:", uniqueN(panel$state_abbr), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Mean flood declarations per state-year:", round(mean(panel$n_flood_decl), 2), "\n")
cat("Share with any flood declaration:", round(mean(panel$flood_declared), 3), "\n")
cat("Share with NFIP claims:", round(mean(panel$any_claims), 3), "\n")

## -----------------------------------------------------------
## 7. Main regressions (6 specifications)
##    All clustered at state level; year fixed effects throughout
## -----------------------------------------------------------
cat("\n========== MAIN REGRESSIONS ==========\n")

cat("\n--- M1: Pre-1970 share → flood declaration probability (LPM) ---\n")
m1 <- feols(flood_declared ~ pre1970_share + log_n_dams | year,
            data = panel, cluster = ~state_abbr)
summary(m1)

cat("\n--- M2: Log pre-1970 count → flood declaration count (OLS) ---\n")
m2 <- feols(n_flood_decl ~ log_pre1970 + log_n_dams | year,
            data = panel, cluster = ~state_abbr)
summary(m2)

cat("\n--- M3: High-hazard pre-1970 share → flood declaration (LPM) ---\n")
m3 <- feols(flood_declared ~ pre1970_high_share + log_n_dams | year,
            data = panel, cluster = ~state_abbr)
summary(m3)

cat("\n--- M4: Design gap (pre1970_share × precip_ratio) → flood declared ---\n")
m4 <- feols(flood_declared ~ design_gap + pre1970_share + precip_ratio + log_n_dams | year,
            data = panel[!is.na(precip_ratio)], cluster = ~state_abbr)
summary(m4)

cat("\n--- M5: Poisson — flood declaration count ---\n")
m5 <- fepois(n_flood_decl ~ pre1970_share + log_n_dams | year,
             data = panel, cluster = ~state_abbr)
summary(m5)

cat("\n--- M6: Pre-1970 share → NFIP claims (extensive margin, LPM) ---\n")
m6 <- feols(any_claims ~ pre1970_share + log_n_dams | year,
            data = panel, cluster = ~state_abbr)
summary(m6)

## -----------------------------------------------------------
## 8. Age gradient decomposition (coefficients by construction decade)
## -----------------------------------------------------------
cat("\n=== Age gradient decomposition ===\n")

# Build decade shares at the state level from dam microdata
decade_list <- lapply(seq(1920, 1990, 10), function(dec) {
  col_nm <- paste0("share_", dec, "s")
  ds <- dams[!is.na(state_abbr) & state_abbr != "",
             .(share = as.double(mean(
               year_built >= dec & year_built < (dec + 10), na.rm = TRUE
             ))),
             by = state_abbr]
  setnames(ds, "share", col_nm)
  ds
})

decade_shares <- Reduce(function(a, b) merge(a, b, by = "state_abbr", all = TRUE),
                        decade_list)

# Merge into panel (time-invariant, one row per state)
panel <- merge(panel, decade_shares, by = "state_abbr", all.x = TRUE)

decade_vars <- paste0("share_", seq(1920, 1990, 10), "s")

m_gradient <- feols(
  as.formula(paste(
    "flood_declared ~",
    paste(decade_vars, collapse = " + "),
    "+ log_n_dams | year"
  )),
  data = panel, cluster = ~state_abbr
)

cat("\nAge gradient (coefficients — older decades expected larger if hypothesis holds):\n")
summary(m_gradient)

## -----------------------------------------------------------
## 9. Save results
## -----------------------------------------------------------
cat("\n=== Saving results ===\n")

results <- list(
  m1_share       = m1,
  m2_count       = m2,
  m3_high_hazard = m3,
  m4_design_gap  = m4,
  m5_poisson     = m5,
  m6_claims      = m6,
  m_gradient     = m_gradient
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

fwrite(panel, file.path(data_dir, "state_year_panel.csv"))

diagnostics <- list(
  n_treated = as.integer(sum(state_dams$n_pre1970 > 0, na.rm = TRUE)),
  n_pre     = 25L,   # years 2000-2024
  n_obs     = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("Results saved.\n")
cat("Diagnostics: n_treated =", diagnostics$n_treated,
    "| n_pre =", diagnostics$n_pre,
    "| n_obs =", diagnostics$n_obs, "\n")
cat("Done.\n")
