# 03_main_analysis.R — Main regressions with DDD design
# apep_0856: Tipped MW Stability Paradox

source("code/00_packages.R")

# ============================================================
# 1. Load data
# ============================================================
county <- fread("data/county_panel.csv")
placebo <- fread("data/placebo_panel.csv")
state_panel <- fread("data/state_year_race.csv")

cat(sprintf("County panel (restaurants): %d rows\n", nrow(county)))
cat(sprintf("Placebo panel (insurance): %d rows\n", nrow(placebo)))

# ============================================================
# 2. Stack restaurant + insurance for DDD
# ============================================================
county[, restaurant := 1L]
placebo[, restaurant := 0L]

# Harmonize columns
common_cols <- c("fips_county", "statefip", "year", "quarter", "yq",
                 "race", "race_label", "black", "Emp", "earn_avg", "sep_rate",
                 "ofw", "tipped_mw", "log_tipped_mw", "tipped_ratio", "restaurant")

stack <- rbind(
  county[, ..common_cols],
  placebo[, ..common_cols]
)

# Create identifiers
stack[, county_race_ind := paste0(fips_county, "_", race, "_", restaurant)]
stack[, year_race_ind := paste0(year, "_", race, "_", restaurant)]
stack[, county_ind := paste0(fips_county, "_", restaurant)]
stack[, year_race := paste0(year, "_", race)]

# Use tipped_ratio (tipped MW / regular MW) as treatment — isolates tip credit
# In OFW states, ratio = 1.0; in tip-credit states at federal floor, ratio ≈ 0.29
stack[, tip_credit := 1 - tipped_ratio]  # Higher = more reliant on tips

cat(sprintf("Stacked panel: %d rows\n", nrow(stack)))

# ============================================================
# 3. Table 1 descriptive statistics (already computed, just verify)
# ============================================================
cat("\n=== Descriptive: Earnings Gap by Regime ===\n")
desc <- stack[restaurant == 1, .(
  earn = weighted.mean(earn_avg, Emp, na.rm = TRUE),
  sep = weighted.mean(sep_rate, Emp, na.rm = TRUE)
), by = .(ofw, race_label)]
print(dcast(desc, ofw ~ race_label, value.var = c("earn", "sep")))

# ============================================================
# 4. Main Model: DDD using tipped_ratio
# ============================================================

# Model 1: Simple state + year + race FE
# Earnings DDD
m1_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant +
                   tipped_ratio:black + tipped_ratio:restaurant +
                   black:restaurant |
                   statefip + year + race,
                 data = stack,
                 weights = ~Emp,
                 cluster = ~statefip)

cat("\n=== Model 1: Earnings DDD (State + Year + Race FE) ===\n")
print(summary(m1_earn))

# Separation DDD
m1_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant +
                  tipped_ratio:black + tipped_ratio:restaurant +
                  black:restaurant |
                  statefip + year + race,
                data = stack,
                weights = ~Emp,
                cluster = ~statefip)

cat("\n=== Model 2: Separation DDD (State + Year + Race FE) ===\n")
print(summary(m1_sep))

# ============================================================
# 5. Saturated Model: County×Race×Industry + Year×Race×Industry FE
# ============================================================

m2_earn <- feols(earn_avg ~ tipped_ratio:black:restaurant |
                   county_race_ind + year_race_ind,
                 data = stack,
                 weights = ~Emp,
                 cluster = ~statefip)

cat("\n=== Model 3: Earnings DDD (Saturated FE) ===\n")
print(summary(m2_earn))

m2_sep <- feols(sep_rate ~ tipped_ratio:black:restaurant |
                  county_race_ind + year_race_ind,
                data = stack,
                weights = ~Emp,
                cluster = ~statefip)

cat("\n=== Model 4: Separation DDD (Saturated FE) ===\n")
print(summary(m2_sep))

# ============================================================
# 6. Restaurant-only models (for comparison)
# ============================================================

county[, county_race := paste0(fips_county, "_", race)]
county[, year_race := paste0(year, "_", race)]

m3_earn <- feols(earn_avg ~ tipped_ratio:black |
                   county_race + year_race,
                 data = county,
                 weights = ~Emp,
                 cluster = ~statefip)

m3_sep <- feols(sep_rate ~ tipped_ratio:black |
                  county_race + year_race,
                data = county,
                weights = ~Emp,
                cluster = ~statefip)

cat("\n=== Model 5: Restaurant-only Earnings (Saturated FE) ===\n")
print(summary(m3_earn))
cat("\n=== Model 6: Restaurant-only Separation (Saturated FE) ===\n")
print(summary(m3_sep))

# ============================================================
# 7. Event study: New York tipped MW increase
# ============================================================

# NY raised tipped MW from $5.00 to $7.50 in 2016, then to $10.00 in 2019
# Focus on restaurant-only, NY vs stable tip-credit states
stable_states <- c(42L, 48L, 18L, 20L, 28L, 37L, 40L, 47L)  # PA, TX, IN, KS, MS, NC, OK, TN
ny_rest <- county[statefip %in% c(36L, stable_states)]
ny_rest[, treated := as.integer(statefip == 36L)]
ny_rest[, event_time := year - 2016L]
ny_rest[event_time < -5, event_time := -5]
ny_rest[event_time > 6, event_time := 6]

# Earnings event study — interaction with Black
es_earn <- feols(earn_avg ~ i(event_time, treated, ref = -1):black +
                   i(event_time, treated, ref = -1) |
                   fips_county + year + race,
                 data = ny_rest,
                 weights = ~Emp,
                 cluster = ~statefip)

cat("\n=== Event Study: NY Earnings (Black interaction) ===\n")
print(summary(es_earn))

# Separation event study
es_sep <- feols(sep_rate ~ i(event_time, treated, ref = -1):black +
                  i(event_time, treated, ref = -1) |
                  fips_county + year + race,
                data = ny_rest,
                weights = ~Emp,
                cluster = ~statefip)

cat("\n=== Event Study: NY Separation (Black interaction) ===\n")
print(summary(es_sep))

# ============================================================
# 8. Save results
# ============================================================

results <- list(
  m1_earn = m1_earn, m1_sep = m1_sep,
  m2_earn = m2_earn, m2_sep = m2_sep,
  m3_earn = m3_earn, m3_sep = m3_sep,
  es_earn = es_earn, es_sep = es_sep
)

saveRDS(results, "data/main_results.rds")

# Diagnostics
# Continuous treatment: all states with tipped_ratio variation contribute
# Count states with any tipped MW change (not just OFW)
mw_panel <- fread("data/mw_panel.csv")
states_with_change <- mw_panel[, .(mw_range = max(tipped_mw) - min(tipped_mw)), by = statefip][mw_range > 0.5]
n_treated <- nrow(states_with_change)  # States with meaningful tipped MW variation
n_pre <- length(unique(county[year < 2016]$year))
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(stack),
  n_counties = uniqueN(stack$fips_county),
  n_states = uniqueN(stack$statefip),
  years = paste(range(stack$year), collapse = "-"),
  n_restaurant = nrow(county),
  n_placebo = nrow(placebo)
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults and diagnostics saved.\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
