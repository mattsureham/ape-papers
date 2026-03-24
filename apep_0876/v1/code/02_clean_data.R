## 02_clean_data.R — Construct analysis variables
source("00_packages.R")

mig <- readRDS("../data/migration_panel.rds")
tax_changes <- readRDS("../data/tax_changes.rds")

cat("=== Cleaning and constructing analysis variables ===\n")

## ------------------------------------------------------------------
## 1. Winsorize extreme migration rates
## ------------------------------------------------------------------
mig[, net_mig_rate_w := pmax(pmin(net_mig_rate,
                                   quantile(net_mig_rate, 0.99, na.rm = TRUE)),
                              quantile(net_mig_rate, 0.01, na.rm = TRUE))]

## ------------------------------------------------------------------
## 2. Construct treatment variables for triple-diff
## ------------------------------------------------------------------

# Tax-increase states: indicator for states that raised top rates
increase_states <- tax_changes[direction == "increase", unique(statefips)]
mig[, tax_increase_state := as.integer(statefips %in% increase_states)]

# Treatment timing for CS-DiD: first treatment year for each state
# For never-treated states, g = 0 (convention)
first_treat <- tax_changes[direction == "increase", .(g_year = min(change_year)), by = statefips]
mig <- merge(mig, first_treat, by = "statefips", all.x = TRUE)
mig[is.na(g_year), g_year := 0L]  # Never-treated

## ------------------------------------------------------------------
## 3. SALT treatment intensity (continuous)
## ------------------------------------------------------------------
# Standardize SALT exposure (mean 0, SD 1)
mig[, salt_z := (salt_avg_2017 - mean(salt_avg_2017, na.rm = TRUE)) /
       sd(salt_avg_2017, na.rm = TRUE)]

# Interaction terms for SALT design
mig[, salt_post := salt_z * post_salt]
mig[, salt_post_high := salt_z * post_salt * high_income]
mig[, high_post := high_income * post_salt]
mig[, high_salt_post := high_income * high_salt * post_salt]

## ------------------------------------------------------------------
## 4. Create relative-time variable for event studies
## ------------------------------------------------------------------
mig[, rel_time := fifelse(g_year > 0, year - g_year, NA_integer_)]

## ------------------------------------------------------------------
## 5. Outflow and inflow rates
## ------------------------------------------------------------------
mig[, outflow_rate := fifelse(total_returns > 0, outflow / total_returns, NA_real_)]
mig[, inflow_rate := fifelse(total_returns > 0, inflow / total_returns, NA_real_)]

## ------------------------------------------------------------------
## 6. Bracket-specific de-meaning (within-state-bracket)
## ------------------------------------------------------------------
mig[, net_mig_rate_dm := net_mig_rate - mean(net_mig_rate, na.rm = TRUE),
    by = .(statefips, agi_bracket)]

## ------------------------------------------------------------------
## 7. Panel identifiers for fixest
## ------------------------------------------------------------------
mig[, state_bracket := paste0(statefips, "_", agi_bracket)]
mig[, year_bracket := paste0(year, "_", agi_bracket)]
mig[, state_year := paste0(statefips, "_", year)]

cat("Analysis dataset ready:", nrow(mig), "rows\n")
cat("Tax-increase states:", length(increase_states), "\n")
cat("Never-treated states:", uniqueN(mig[g_year == 0, statefips]), "\n")
cat("High-SALT states:", sum(unique(mig[, .(statefips, high_salt)])$high_salt), "\n")

saveRDS(mig, "../data/analysis_panel.rds")
cat("Saved: analysis_panel.rds\n")
