# 02_clean_data.R — Construct treatment variables and clean panel
source("00_packages.R")

dt <- fread("../data/wages_raw.csv")
cat(sprintf("Loaded %d observations\n", nrow(dt)))

# --- Compute pre-reform (2018) sector mean gross wage ---
dt_2018 <- dt[year == 2018, .(mean_wage_2018 = mean(gross_wage, na.rm = TRUE)), by = sector]

# Treatment exposure = mean wage / MKD 90,000 threshold
dt_2018[, exposure := mean_wage_2018 / 90000]

cat("\n=== Sector Exposure (2018 mean wage / 90,000 threshold) ===\n")
print(dt_2018[order(-exposure)])

# Merge exposure back
dt <- merge(dt, dt_2018[, .(sector, mean_wage_2018, exposure)], by = "sector")

# --- Treatment period indicators ---
dt[, reform_2019 := as.integer(year == 2019)]
dt[, post_2020 := as.integer(year >= 2020)]

# Interaction terms
dt[, reform_x_exposure := reform_2019 * exposure]
dt[, post_x_exposure := post_2020 * exposure]

# --- Log wages ---
dt[, ln_gross := log(gross_wage)]
dt[, ln_net := log(net_wage)]

# --- Gross-net gap (mechanism) ---
dt[, gross_net_gap := gross_wage - net_wage]
dt[, ln_gap := log(gross_net_gap)]

# --- Event time (months relative to Jan 2019) ---
dt[, event_time := (year - 2019) * 12 + (month - 1)]

# --- Exposure groups for descriptive analysis ---
dt[, exposure_group := fifelse(exposure >= 0.5, "High", "Low")]

# --- Year-month numeric for FE ---
dt[, ym := year * 100 + month]

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Sectors: %d\n", uniqueN(dt$sector)))
cat(sprintf("Months: %d\n", uniqueN(dt$ym)))
cat(sprintf("Observations: %d\n", nrow(dt)))
cat(sprintf("Date range: %s to %s\n", min(dt$date), max(dt$date)))

cat("\nExposure distribution:\n")
cat(sprintf("  Mean: %.3f\n", mean(dt_2018$exposure)))
cat(sprintf("  Min:  %.3f (%s)\n", min(dt_2018$exposure), dt_2018[which.min(exposure), sector]))
cat(sprintf("  Max:  %.3f (%s)\n", max(dt_2018$exposure), dt_2018[which.max(exposure), sector]))

cat("\nHigh-exposure sectors (exposure >= 0.5):\n")
print(dt_2018[exposure >= 0.5][order(-exposure)])

cat("\nLow-exposure sectors (exposure < 0.5):\n")
print(dt_2018[exposure < 0.5][order(-exposure)])

# --- Restrict to 2012-2024 for estimation (balanced panel, ample pre-treatment) ---
dt_est <- dt[year >= 2012 & year <= 2024]
cat(sprintf("\nEstimation sample (2012-2024): %d obs\n", nrow(dt_est)))

# Save
fwrite(dt, "../data/wages_clean.csv")
fwrite(dt_est, "../data/wages_estimation.csv")
cat("\nSaved cleaned data.\n")
