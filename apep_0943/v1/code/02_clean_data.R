# 02_clean_data.R — Variable construction for apep_0943
source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== Data Cleaning and Variable Construction ===\n\n")
cat(sprintf("Panel: %d obs (%d cantons × %d years)\n",
            nrow(panel), uniqueN(panel$canton), uniqueN(panel$year)))

# --------------------------------------------------------------------------
# 1. Treatment variables
# --------------------------------------------------------------------------

# Standardize CO2 vote share (mean 0, SD 1) for easier interpretation
panel[, co2_std := (co2_frac - mean(co2_frac)) / sd(co2_frac)]

# Binary high/low CO2 support (above/below median)
panel[, co2_high := as.integer(co2_frac > median(co2_frac))]

# Interaction terms
panel[, treat_post := co2_frac * post_co2]
panel[, treat_std_post := co2_std * post_co2]
panel[, treat_high_post := co2_high * post_co2]

# Placebo treatment (immigration vote)
panel[, immig_post := immig_frac * post_co2]

# --------------------------------------------------------------------------
# 2. Outcome variables
# --------------------------------------------------------------------------

# Log new buildings per capita (×1000)
panel[, log_bld_pc := log(new_bld_pc + 0.01)]

# Growth rate of new buildings (year-over-year)
setorder(panel, canton, year)
panel[, bld_growth := (new_buildings - shift(new_buildings)) / shift(new_buildings),
      by = canton]

# Cumulative policy adoption (count of cantons with policy by year)
# This is a canton-level binary that turns on when the canton adopts
panel[, has_policy_cum := as.integer(!is.na(policy_date) & year >= year(policy_date))]

# --------------------------------------------------------------------------
# 3. Pre-treatment characteristics
# --------------------------------------------------------------------------

# Pre-period mean new buildings per capita (2013-2020)
panel[, pre_mean_bld_pc := mean(new_bld_pc[year <= 2020], na.rm = TRUE), by = canton]

# Pre-period trend in new buildings
panel[year <= 2020, pre_trend := coef(lm(new_bld_pc ~ year))[2], by = canton]
panel[, pre_trend := pre_trend[!is.na(pre_trend)][1], by = canton]

# --------------------------------------------------------------------------
# 4. Event-time variables for event study
# --------------------------------------------------------------------------

# Event time: 2021 is the shock year (vote was June 13, 2021)
# First full post-treatment year is 2022
panel[, event_time := year - 2022]

# Event-time dummies interacted with treatment intensity
for (t in -8:1) {
  col_name <- paste0("et_", ifelse(t < 0, paste0("m", abs(t)), t))
  panel[, (col_name) := as.integer(event_time == t) * co2_frac]
}

# --------------------------------------------------------------------------
# 5. Summary statistics
# --------------------------------------------------------------------------
cat("\n--- Summary Statistics ---\n")

cat("\nKey variables (full panel):\n")
vars <- c("new_buildings", "new_bld_pc", "population", "co2_yes",
          "has_policy_cum", "post_co2")
for (v in vars) {
  if (v %in% names(panel)) {
    cat(sprintf("  %-20s  mean=%.3f  sd=%.3f  min=%.3f  max=%.3f  N=%d\n",
                v, mean(panel[[v]], na.rm=T), sd(panel[[v]], na.rm=T),
                min(panel[[v]], na.rm=T), max(panel[[v]], na.rm=T),
                sum(!is.na(panel[[v]]))))
  }
}

cat("\nPre vs Post comparison (new buildings per capita ×1000):\n")
cat(sprintf("  Pre (2013-2021):  High CO2 = %.3f, Low CO2 = %.3f\n",
            mean(panel[co2_high == 1 & year <= 2021]$new_bld_pc, na.rm=T),
            mean(panel[co2_high == 0 & year <= 2021]$new_bld_pc, na.rm=T)))
cat(sprintf("  Post (2022-2023): High CO2 = %.3f, Low CO2 = %.3f\n",
            mean(panel[co2_high == 1 & year >= 2022]$new_bld_pc, na.rm=T),
            mean(panel[co2_high == 0 & year >= 2022]$new_bld_pc, na.rm=T)))

# --------------------------------------------------------------------------
# 6. Save
# --------------------------------------------------------------------------
saveRDS(panel, "../data/panel_clean.rds")
cat("\nCleaned panel saved to data/panel_clean.rds\n")
cat(sprintf("Final dimensions: %d rows × %d columns\n", nrow(panel), ncol(panel)))
