## 02_clean_data.R — Build analysis panel
## apep_1315: The Forever Chemical Discount

source("00_packages.R")

data_dir <- "../data"

## ---- 1. Load raw data ----
cat("Loading raw data...\n")
ucmr5 <- readRDS(file.path(data_dir, "ucmr5_results.rds"))
ucmr5_zips <- readRDS(file.path(data_dir, "ucmr5_zipcodes.rds"))
fhfa_raw <- readRDS(file.path(data_dir, "fhfa_zip5_hpi.rds"))
prior_mcl <- readRDS(file.path(data_dir, "prior_mcl_states.rds"))

## ---- 2. Process UCMR 5: identify above-MCL systems ----
cat("Processing UCMR 5 data...\n")

# Focus on PFOA and PFOS (the two with 4 ppt MCL)
pfas_target <- c("PFOA", "PFOS")
ucmr5_pfas <- ucmr5[Contaminant %in% pfas_target]
cat("PFOA/PFOS rows:", nrow(ucmr5_pfas), "\n")

# Parse analytical result values
ucmr5_pfas[, result_numeric := as.numeric(AnalyticalResultValue)]

# For non-detects (sign = "<"), result is below MRL — set to 0
ucmr5_pfas[AnalyticalResultsSign == "<", result_numeric := 0]

# Get maximum detected concentration per system per contaminant
system_max <- ucmr5_pfas[, .(
  max_conc_ug_L = max(result_numeric, na.rm = TRUE),
  n_samples = .N,
  n_detects = sum(result_numeric > 0, na.rm = TRUE)
), by = .(PWSID, Contaminant, State)]

# Convert ug/L to ppt (ng/L): 1 ug/L = 1000 ppt (ng/L)
# Wait — EPA UCMR 5 reports in ug/L. MCL is 4 ppt = 0.004 ug/L
system_max[, max_conc_ppt := max_conc_ug_L * 1000]

cat("Concentration units in data:", unique(ucmr5_pfas$Units), "\n")

# Flag systems above federal MCL (4 ppt = 0.004 ug/L for PFOA/PFOS)
MCL_PPT <- 4.0
system_max[, above_mcl := max_conc_ppt > MCL_PPT]

# System-level: above MCL if EITHER PFOA or PFOS exceeds 4 ppt
system_treatment <- system_max[, .(
  above_mcl = any(above_mcl),
  max_pfoa_ppt = max(max_conc_ppt[Contaminant == "PFOA"], 0, na.rm = TRUE),
  max_pfos_ppt = max(max_conc_ppt[Contaminant == "PFOS"], 0, na.rm = TRUE),
  total_samples = sum(n_samples),
  total_detects = sum(n_detects)
), by = .(PWSID, State)]

cat("Total systems with PFOA/PFOS data:", nrow(system_treatment), "\n")
cat("Systems above MCL:", sum(system_treatment$above_mcl), "\n")
cat("Systems below MCL:", sum(!system_treatment$above_mcl), "\n")

# Add prior state MCL flag
system_treatment[, prior_state_mcl := State %in% prior_mcl$state]
cat("Above-MCL systems in prior-MCL states:",
    sum(system_treatment$above_mcl & system_treatment$prior_state_mcl), "\n")
cat("Above-MCL systems in no-prior-MCL states:",
    sum(system_treatment$above_mcl & !system_treatment$prior_state_mcl), "\n")

## ---- 3. Link systems to ZIP codes ----
cat("\nLinking systems to ZIP codes...\n")
names(ucmr5_zips) <- c("PWSID", "ZIPCODE")
ucmr5_zips[, zip5 := sprintf("%05d", as.integer(ZIPCODE))]

# Merge treatment to ZIP codes
zip_treatment <- merge(ucmr5_zips[, .(PWSID, zip5)],
                       system_treatment,
                       by = "PWSID", all.x = FALSE)

# ZIP-level: above MCL if ANY serving system is above MCL
zip_level <- zip_treatment[, .(
  above_mcl = any(above_mcl),
  max_pfoa_ppt = max(max_pfoa_ppt, na.rm = TRUE),
  max_pfos_ppt = max(max_pfos_ppt, na.rm = TRUE),
  n_systems = .N,
  prior_state_mcl = any(prior_state_mcl),
  state = first(State)
), by = zip5]

cat("Unique ZIPs with UCMR 5 data:", nrow(zip_level), "\n")
cat("ZIPs above MCL:", sum(zip_level$above_mcl), "\n")
cat("ZIPs below MCL:", sum(!zip_level$above_mcl), "\n")

## ---- 4. Process FHFA HPI ----
cat("\nProcessing FHFA HPI data...\n")

# The FHFA file has header rows we need to skip
# Check first few rows
fhfa_dt <- as.data.table(fhfa_raw)
names(fhfa_dt) <- c("zip5", "year", "hpi", "hpi_1990_base", "hpi_2000_base", "V6")

# Remove header/metadata rows
fhfa_dt <- fhfa_dt[!is.na(suppressWarnings(as.numeric(year)))]
fhfa_dt[, `:=`(
  zip5 = sprintf("%05d", as.integer(zip5)),
  year = as.integer(year),
  hpi = as.numeric(hpi),
  hpi_1990_base = as.numeric(hpi_1990_base),
  hpi_2000_base = as.numeric(hpi_2000_base)
)]

# Remove rows with missing HPI
fhfa_dt <- fhfa_dt[!is.na(hpi) & !is.na(year)]
fhfa_dt[, V6 := NULL]

cat("FHFA clean rows:", nrow(fhfa_dt), "\n")
cat("Year range:", range(fhfa_dt$year), "\n")
cat("Unique ZIPs:", uniqueN(fhfa_dt$zip5), "\n")

## ---- 5. Build analysis panel ----
cat("\nBuilding analysis panel...\n")

# Restrict FHFA to relevant years (2014-2024 for 10 pre-periods + post)
panel_years <- 2014:2024
fhfa_panel <- fhfa_dt[year %in% panel_years]

# Merge FHFA with treatment assignment
panel <- merge(fhfa_panel, zip_level, by = "zip5", all = FALSE)

cat("Panel observations (ZIP-years):", nrow(panel), "\n")
cat("Unique ZIPs in panel:", uniqueN(panel$zip5), "\n")
cat("Treated ZIPs in panel:", uniqueN(panel$zip5[panel$above_mcl]), "\n")
cat("Control ZIPs in panel:", uniqueN(panel$zip5[!panel$above_mcl]), "\n")

# Create DiD variables
panel[, `:=`(
  post = as.integer(year >= 2024),
  treat = as.integer(above_mcl),
  treat_post = as.integer(above_mcl & year >= 2024),
  no_prior_mcl = as.integer(!prior_state_mcl),
  # DDD interaction
  treat_post_noprior = as.integer(above_mcl & year >= 2024 & !prior_state_mcl),
  # Log HPI for percentage interpretation
  log_hpi = log(hpi)
)]

# Annual HPI growth rate
panel <- panel[order(zip5, year)]
panel[, hpi_growth := hpi / shift(hpi, 1) - 1, by = zip5]

# State-level fixed effects
panel[, state_fe := as.factor(state)]

cat("\n=== PANEL SUMMARY ===\n")
cat("Observations:", nrow(panel), "\n")
cat("ZIP codes:", uniqueN(panel$zip5), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Treated (above MCL):", uniqueN(panel$zip5[panel$treat == 1]), "\n")
cat("Control (below MCL):", uniqueN(panel$zip5[panel$treat == 0]), "\n")
cat("Prior-MCL states in panel:", sum(panel$prior_state_mcl & panel$year == 2024), "ZIPs\n")
cat("No-prior-MCL states in panel:", sum(!panel$prior_state_mcl & panel$year == 2024), "ZIPs\n")

# Pre-treatment means
cat("\nPre-treatment HPI means (2014-2023):\n")
pre <- panel[year < 2024]
cat("  Treated:", round(mean(pre$hpi[pre$treat == 1], na.rm = TRUE), 2), "\n")
cat("  Control:", round(mean(pre$hpi[pre$treat == 0], na.rm = TRUE), 2), "\n")
cat("  Treated growth:", round(mean(pre$hpi_growth[pre$treat == 1], na.rm = TRUE), 4), "\n")
cat("  Control growth:", round(mean(pre$hpi_growth[pre$treat == 0], na.rm = TRUE), 4), "\n")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(zip_level, file.path(data_dir, "zip_treatment.rds"))
saveRDS(system_treatment, file.path(data_dir, "system_treatment.rds"))

cat("\nPanel saved. Ready for analysis.\n")
