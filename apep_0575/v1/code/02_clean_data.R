## 02_clean_data.R — Build analysis panel
## apep_0575: BRRD Bail-In Risk and Household Deposit Structure

source("00_packages.R")

data_dir <- "../data/"

# ===========================================================================
# 1. LOAD RAW DATA
# ===========================================================================

ecb <- fread(paste0(data_dir, "ecb_bsi_deposits.csv"))
brrd <- fread(paste0(data_dir, "brrd_transposition_dates.csv"))
eba <- fread(paste0(data_dir, "eba_dgs_ratios.csv"))
ecb_rate <- fread(paste0(data_dir, "ecb_policy_rate.csv"))

# ===========================================================================
# 2. CONSTRUCT DEPOSIT SHARES
# ===========================================================================

# Reshape: for each country × month × sector, compute deposit shares
ecb[, time_period := as.character(time_period)]

# Total deposits (L20) as denominator
totals <- ecb[deposit_type == "L20", .(country, time_period, sector,
                                        total_deposits = value)]

# Merge deposit types with totals
panel <- merge(ecb, totals,
               by = c("country", "time_period", "sector"),
               all.x = TRUE)

# Compute share of each type relative to total
panel[, share := value / total_deposits]

# Key outcome: overnight share for households
# L21/L20 = overnight/total → measures liquidity preference
# Higher overnight share = more liquid deposits (our predicted response to bail-in)

# Reshape wide: one row per country × month × sector
panel_wide <- dcast(panel,
                    country + time_period + sector + year + month + date + total_deposits ~ deposit_type,
                    value.var = c("value", "share"),
                    fun.aggregate = mean)

# Rename for clarity
setnames(panel_wide, c(
  "value_L20", "value_L21", "value_L22", "value_L23",
  "share_L20", "share_L21", "share_L22", "share_L23"
), c(
  "dep_total", "dep_overnight", "dep_agreed", "dep_redeemable",
  "share_total", "share_overnight", "share_agreed", "share_redeemable"
), skip_absent = TRUE)

cat(sprintf("Panel after reshaping: %d obs\n", nrow(panel_wide)))

# ===========================================================================
# 3. MERGE TREATMENT VARIABLES
# ===========================================================================

# BRRD transposition dates
brrd[, transposition_date := as.Date(transposition_date)]
brrd[, transposition_ym := format(transposition_date, "%Y-%m")]

panel_wide <- merge(panel_wide, brrd[, .(country, transposition_date, transposition_ym,
                                          country_name)],
                    by = "country", all.x = TRUE)

# Post-treatment indicator
panel_wide[, post_brrd := fifelse(time_period >= transposition_ym, 1L, 0L)]

# Treatment cohort (year-month of transposition)
panel_wide[, cohort := transposition_ym]

# Relative time to treatment (in months)
panel_wide[, rel_time := (year - as.integer(substr(transposition_ym, 1, 4))) * 12 +
             (month - as.integer(substr(transposition_ym, 6, 7)))]

# ===========================================================================
# 4. MERGE TREATMENT INTENSITY (EBA UNINSURED SHARE)
# ===========================================================================

panel_wide <- merge(panel_wide, eba[, .(country, uninsured_share, covered_ratio)],
                    by = "country", all.x = TRUE)

# Interaction: post × uninsured_share (for triple-diff)
panel_wide[, post_x_uninsured := post_brrd * uninsured_share]

# ===========================================================================
# 5. MERGE ECB POLICY RATE
# ===========================================================================

panel_wide <- merge(panel_wide, ecb_rate, by = "time_period", all.x = TRUE)

# ===========================================================================
# 6. CREATE ANALYSIS VARIABLES
# ===========================================================================

# Log total deposits
panel_wide[dep_total > 0, log_total_dep := log(dep_total)]

# Numeric month for time FE
panel_wide[, month_num := (year - 2012) * 12 + month]

# Country numeric ID
panel_wide[, country_id := as.integer(factor(country))]

# Sector labels
panel_wide[, sector_label := fifelse(sector == "2250", "Households", "Corporations")]

# Eurozone membership
eurozone <- c("AT","BE","CY","DE","EE","ES","FI","FR","EL","HR","IE",
              "IT","LT","LU","LV","MT","NL","PT","SI","SK")
panel_wide[, eurozone := fifelse(country %in% eurozone, 1L, 0L)]

# Pre-BRRD period indicator (for computing pre-period means)
panel_wide[, pre_brrd := fifelse(time_period < "2014-06", 1L, 0L)]

# ===========================================================================
# 7. COMPUTE PRE-PERIOD DEPOSIT COMPOSITION (baseline)
# ===========================================================================

pre_means <- panel_wide[pre_brrd == 1 & sector == "2250",
                        .(baseline_overnight_share = mean(share_overnight, na.rm = TRUE),
                          baseline_agreed_share = mean(share_agreed, na.rm = TRUE),
                          baseline_redeemable_share = mean(share_redeemable, na.rm = TRUE),
                          baseline_total_dep = mean(dep_total, na.rm = TRUE)),
                        by = country]

panel_wide <- merge(panel_wide, pre_means, by = "country", all.x = TRUE)

# ===========================================================================
# 8. SPLIT AND SAVE
# ===========================================================================

# Household panel (main analysis)
hh_panel <- panel_wide[sector == "2250"]
cat(sprintf("Household panel: %d obs, %d countries, %d months\n",
            nrow(hh_panel), uniqueN(hh_panel$country),
            uniqueN(hh_panel$time_period)))

# Corporate panel (placebo)
nfc_panel <- panel_wide[sector == "2240"]
cat(sprintf("Corporate panel: %d obs, %d countries, %d months\n",
            nrow(nfc_panel), uniqueN(nfc_panel$country),
            uniqueN(nfc_panel$time_period)))

# Full panel (both sectors for sector-level analysis)
cat(sprintf("Full panel: %d obs\n", nrow(panel_wide)))

fwrite(hh_panel, paste0(data_dir, "hh_panel.csv"))
fwrite(nfc_panel, paste0(data_dir, "nfc_panel.csv"))
fwrite(panel_wide, paste0(data_dir, "full_panel.csv"))

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Household overnight share:\n")
print(summary(hh_panel$share_overnight))
cat("\nHousehold agreed-maturity share:\n")
print(summary(hh_panel$share_agreed))
cat("\nUninsured deposit share (treatment intensity):\n")
print(summary(eba$uninsured_share))
cat("\nRelative time range:", range(hh_panel$rel_time, na.rm = TRUE), "\n")

# Save summary stats for tables
sumstats <- hh_panel[, .(
  N = .N,
  Countries = uniqueN(country),
  Months = uniqueN(time_period),
  Mean_overnight_share = mean(share_overnight, na.rm = TRUE),
  SD_overnight_share = sd(share_overnight, na.rm = TRUE),
  Mean_agreed_share = mean(share_agreed, na.rm = TRUE),
  SD_agreed_share = sd(share_agreed, na.rm = TRUE),
  Mean_redeemable_share = mean(share_redeemable, na.rm = TRUE),
  SD_redeemable_share = sd(share_redeemable, na.rm = TRUE),
  Mean_total_deposits_EUR_M = mean(dep_total, na.rm = TRUE),
  SD_total_deposits_EUR_M = sd(dep_total, na.rm = TRUE)
)]

fwrite(sumstats, paste0(data_dir, "summary_stats.csv"))
cat("\nPanel construction complete.\n")
