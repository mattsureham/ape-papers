## 02_clean_data.R — Construct analysis panel
## apep_0981: Good Samaritan Laws and Opioid Treatment Entry

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. LOAD RAW DATA
# ============================================================================
sdud <- fread(file.path(data_dir, "sdud_panel.csv"))
gsl <- fread(file.path(data_dir, "gsl_adoption_dates.csv"))

cat("=== Raw data ===\n")
cat(sprintf("  SDUD: %d obs, %d states, %d-%d\n",
            nrow(sdud), length(unique(sdud$state)),
            min(sdud$year), max(sdud$year)))

# ============================================================================
# 2. CLEAN SDUD — COLLAPSE TO STATE-YEAR LEVEL
# ============================================================================
# We work at state-year level for the DiD (quarterly is fine but annual
# matches the GSL adoption year coding and simplifies the CS estimator)

# Remove XX (unknown) and PR (Puerto Rico - no GSL data)
sdud <- sdud[!state %in% c("XX", "PR")]

# Aggregate to state-year-drug_type
sdud_annual <- sdud[, .(
  n_prescriptions = sum(n_prescriptions, na.rm = TRUE),
  total_units = sum(total_units, na.rm = TRUE)
), by = .(state, year, drug_type)]

cat(sprintf("  Annual panel: %d state-year-drug obs\n", nrow(sdud_annual)))

# ============================================================================
# 3. CONSTRUCT POPULATION DENOMINATORS
# ============================================================================
# Census API was unreliable. Use Medicaid enrollment as alternative denominator,
# or construct from total Rx volume. For state-year analysis, we can also
# use the absolute counts (logged) since we include state + year FEs.

# Try loading Census data if available
pop_file <- file.path(data_dir, "state_population.csv")
has_pop <- file.exists(pop_file)

if (has_pop) {
  pop <- fread(pop_file)
  if ("state_abbr" %in% names(pop) && nrow(pop) > 100) {
    pop_annual <- pop[, .(population = mean(population, na.rm = TRUE)),
                       by = .(state = state_abbr, year)]
    cat(sprintf("  Population data: %d state-years\n", nrow(pop_annual)))
  } else {
    has_pop <- FALSE
  }
}

if (!has_pop) {
  cat("  No reliable population data. Using log counts (with state+year FEs).\n")
  cat("  Constructing approximate population from BEA/Census published totals.\n")

  # Use published Census state population estimates (hard-coded for key years)
  # Source: Census Bureau Annual Population Estimates
  # We only need approximate denominators for per-capita normalization
  state_pops_2015 <- data.table(
    state = c("AL","AK","AZ","AR","CA","CO","CT","DC","DE","FL",
              "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
              "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
              "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
              "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
    pop_2015 = c(4858979, 738432, 6828065, 2978204, 39144818, 5456574,
                  3590886, 672228, 945934, 20271272, 10214860, 1431603,
                  1654930, 12859995, 6619680, 3123899, 2911641, 4425092,
                  4670724, 1329328, 6006401, 6794422, 9922576, 5489594,
                  2992333, 6083672, 1032949, 1896190, 2890845, 1330608,
                  8958013, 2085109, 19795791, 10042802, 756927, 11613423,
                  3911338, 4028977, 12802503, 1056298, 4896146, 858469,
                  6600299, 27469114, 2995919, 626042, 8382993, 7170351,
                  1844128, 5771337, 586107)
  )

  # Approximate other years using 1% annual growth rate
  pop_annual <- rbindlist(lapply(2006:2022, function(yr) {
    dt <- copy(state_pops_2015)
    dt[, population := pop_2015 * (1 + 0.005)^(yr - 2015)]
    dt[, year := yr]
    dt[, pop_2015 := NULL]
    dt
  }))

  has_pop <- TRUE
  cat(sprintf("  Approximate population: %d state-years\n", nrow(pop_annual)))
}

# ============================================================================
# 4. MERGE GSL + SDUD + POPULATION
# ============================================================================
# Pivot drug types to wide format
bup_panel <- sdud_annual[drug_type == "buprenorphine",
                          .(state, year, bup_rx = n_prescriptions, bup_units = total_units)]
opi_panel <- sdud_annual[drug_type == "opioid_placebo",
                          .(state, year, opioid_rx = n_prescriptions, opioid_units = total_units)]

panel <- merge(bup_panel, opi_panel, by = c("state", "year"), all = TRUE)
panel <- merge(panel, gsl, by = "state", all.x = TRUE)

if (has_pop) {
  panel <- merge(panel, pop_annual, by = c("state", "year"), all.x = TRUE)
}

# Fill NAs with 0 for prescription counts
panel[is.na(bup_rx), bup_rx := 0]
panel[is.na(opioid_rx), opioid_rx := 0]
panel[is.na(bup_units), bup_units := 0]
panel[is.na(opioid_units), opioid_units := 0]

# ============================================================================
# 5. CONSTRUCT ANALYSIS VARIABLES
# ============================================================================

# Treatment indicator
panel[, treated := as.integer(gsl_year > 0 & year >= gsl_year)]

# First treatment year for CS estimator (0 = never treated)
panel[, first_treat := gsl_year]

# Log outcomes (add 1 to handle zeros)
panel[, log_bup_rx := log(bup_rx + 1)]
panel[, log_opioid_rx := log(opioid_rx + 1)]

# Per-capita rates (per 100K population)
if (has_pop) {
  panel[, bup_rate := (bup_rx / population) * 100000]
  panel[, opioid_rate := (opioid_rx / population) * 100000]
  panel[, log_bup_rate := log(bup_rate + 1)]
  panel[, log_opioid_rate := log(opioid_rate + 1)]
}

# Numeric state ID for CS estimator
panel[, state_id := as.integer(as.factor(state))]

# Event time
panel[first_treat > 0, event_time := year - first_treat]
panel[first_treat == 0, event_time := NA_integer_]

# ============================================================================
# 6. SAMPLE RESTRICTIONS + VALIDATION
# ============================================================================

# Drop states with all-zero buprenorphine (data quality issue)
state_bup_total <- panel[, .(total_bup = sum(bup_rx)), by = state]
zero_states <- state_bup_total[total_bup == 0, state]
if (length(zero_states) > 0) {
  cat(sprintf("  Dropping %d states with zero buprenorphine: %s\n",
              length(zero_states), paste(zero_states, collapse=", ")))
  panel <- panel[!state %in% zero_states]
}

# Verify panel balance
cat(sprintf("\n=== ANALYSIS PANEL ===\n"))
cat(sprintf("  States: %d\n", length(unique(panel$state))))
cat(sprintf("  Years: %d-%d (%d years)\n", min(panel$year), max(panel$year),
            length(unique(panel$year))))
cat(sprintf("  Total obs: %d\n", nrow(panel)))
cat(sprintf("  Treated states: %d\n", length(unique(panel[first_treat > 0, state]))))
cat(sprintf("  Never-treated states: %d\n", length(unique(panel[first_treat == 0, state]))))

# Cohort distribution
cat("\n  GSL adoption cohorts:\n")
cohort_tab <- panel[, .(n_states = uniqueN(state)), by = first_treat]
setorder(cohort_tab, first_treat)
for (i in 1:nrow(cohort_tab)) {
  cat(sprintf("    %d: %d states\n", cohort_tab$first_treat[i], cohort_tab$n_states[i]))
}

# Summary statistics
cat("\n  Summary statistics:\n")
cat(sprintf("    Mean bup Rx/state-year: %.0f\n", mean(panel$bup_rx)))
cat(sprintf("    SD bup Rx: %.0f\n", sd(panel$bup_rx)))
cat(sprintf("    Mean opioid Rx/state-year: %.0f\n", mean(panel$opioid_rx)))
cat(sprintf("    SD opioid Rx: %.0f\n", sd(panel$opioid_rx)))
if (has_pop) {
  cat(sprintf("    Mean bup rate/100K: %.1f\n", mean(panel$bup_rate, na.rm=TRUE)))
  cat(sprintf("    SD bup rate/100K: %.1f\n", sd(panel$bup_rate, na.rm=TRUE)))
}

# Save
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\n  Panel saved to %s\n", file.path(data_dir, "analysis_panel.csv")))
