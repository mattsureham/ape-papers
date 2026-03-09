## 03_main_analysis.R — Main DDD regressions for sanctions enforcement
## apep_0553: Do Export Controls Have Teeth?

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

## ============================================================
## Load data
## ============================================================

panel <- fread(file.path(DATA_DIR, "panel_hs6.csv"))
country_panel <- fread(file.path(DATA_DIR, "panel_country.csv"))

cat("Panel loaded:", nrow(panel), "rows\n")

## ============================================================
## Construct analysis sample
## If control countries available: transit + control (DDD)
## If transit only: within-transit DD (CHPL vs non-CHPL)
## ============================================================

has_control <- any(panel$role == "control")
if (has_control) {
  analysis <- panel[role %in% c("transit", "control")]
  cat("Analysis sample (transit + control):", nrow(analysis), "rows\n")
} else {
  analysis <- panel[role == "transit"]
  cat("Analysis sample (transit only, DD design):", nrow(analysis), "rows\n")
  cat("NOTE: No control countries available. Using within-transit DD.\n")
}

# Ensure numeric treatment indicators (avoid factor collinearity)
analysis[, is_chpl_num := as.integer(is_chpl)]
analysis[, is_transit_num := as.integer(is_transit)]

# Pre-compute interaction terms to avoid fixest collinearity detection issues
analysis[, chpl_post := is_chpl_num * post_sanctions]
analysis[, chpl_post_chpl := is_chpl_num * post_chpl]
analysis[, transit_post := is_transit_num * post_sanctions]
analysis[, transit_chpl_post := is_transit_num * is_chpl_num * post_sanctions]
analysis[, transit_chpl_postchpl := is_transit_num * is_chpl_num * post_chpl]

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================

# Pre-sanctions summary by role and CHPL status
sumstats <- analysis[, .(
  mean_trade = mean(fob_value),
  sd_trade = sd(fob_value),
  median_trade = median(fob_value),
  pct_positive = mean(trade_positive) * 100,
  n_obs = .N
), by = .(role, is_chpl, period)]

fwrite(sumstats, file.path(DATA_DIR, "summary_statistics.csv"))
cat("\nSummary statistics saved.\n")

## ============================================================
## MAIN SPECIFICATION: Difference-in-Differences
## ============================================================
## With transit countries only:
##   log(trade + 1) = alpha + beta1 * (CHPL × Post2022)
##     + beta2 * (CHPL × PostCHPL)   <- KEY PARAMETER
##     + country×product FE + product×year FE + country×year FE + epsilon
## With transit + control countries (DDD):
##   Adds Transit × Post2022 and Transit × CHPL interactions.

cat("\n=== MAIN REGRESSIONS ===\n\n")

if (has_control) {
  # DDD specification
  m1 <- feols(log_trade ~ transit_post |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m2 <- feols(log_trade ~ transit_post + transit_chpl_post |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m3 <- feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m5 <- feols(trade_positive ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
  m6 <- feols(asinh_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                cp + pt + ct, data = analysis, cluster = ~reporter_code)
} else {
  # DD specification (within transit countries)
  # CHPL vs non-CHPL products, before vs after
  # NOTE: pt (product × year) FE would absorb chpl_post since it varies at product-year level.
  # Use cp + ct as baseline; add hs2 × year for broad sector trends.
  analysis[, hs2_year := paste0(hs2, "_", year)]

  m1 <- feols(log_trade ~ chpl_post |
                cp + ct, data = analysis, cluster = ~hs6)
  m2 <- feols(log_trade ~ chpl_post |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m3 <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m5 <- feols(trade_positive ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
  m6 <- feols(asinh_trade ~ chpl_post + chpl_post_chpl |
                cp + ct + hs2_year, data = analysis, cluster = ~hs6)
}

# Model 4: Poisson PPML
m4 <- tryCatch({
  if (has_control) {
    fepois(fob_value ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
             cp + pt + ct, data = analysis, cluster = ~reporter_code)
  } else {
    fepois(fob_value ~ chpl_post + chpl_post_chpl |
             cp + pt + ct, data = analysis, cluster = ~hs6)
  }
}, error = function(e) {
  message("PPML failed: ", e$message)
  NULL
})

## Print results
cat("=== Model 3 (Main DDD) ===\n")
print(summary(m3))

## ============================================================
## Save regression results for tables
## ============================================================

models <- list(m1, m2, m3, m4, m5, m6)
model_names <- c("DD", "DDD_base", "DDD_enforcement", "PPML", "Extensive", "Asinh")

# Extract coefficients for CSV output
extract_coefs <- function(m, name) {
  if (is.null(m)) return(data.table())
  ct <- as.data.table(coeftable(m), keep.rownames = "term")
  ct[, model := name]
  ct[, n_obs := m$nobs]
  ct
}

coef_table <- rbindlist(lapply(seq_along(models), function(i) {
  extract_coefs(models[[i]], model_names[i])
}), fill = TRUE)

fwrite(coef_table, file.path(DATA_DIR, "main_regression_coefs.csv"))

## ============================================================
## TABLE 2: By-Tier Analysis
## ============================================================

cat("\n=== TIER-SPECIFIC REGRESSIONS ===\n\n")

# Restrict to CHPL products only, compare across tiers
chpl_only <- analysis[is_chpl == TRUE]

if (has_control) {
  m_tier12 <- feols(log_trade ~ is_transit_num:post_sanctions +
                      is_transit_num:post_chpl |
                      cp + pt + ct,
                    data = chpl_only[tier_group == "Tier1_2"],
                    cluster = ~reporter_code)
  m_tier3 <- feols(log_trade ~ is_transit_num:post_sanctions +
                     is_transit_num:post_chpl |
                     cp + pt + ct,
                   data = chpl_only[tier_group == "Tier3"],
                   cluster = ~reporter_code)
  m_tier4 <- feols(log_trade ~ is_transit_num:post_sanctions +
                     is_transit_num:post_chpl |
                     cp + pt + ct,
                   data = chpl_only[tier_group == "Tier4"],
                   cluster = ~reporter_code)
} else {
  # Within-transit CHPL-only: post_sanctions/post_chpl with cp FE only
  # (ct would absorb these year-level regressors)
  m_tier12 <- feols(log_trade ~ post_sanctions + post_chpl |
                      cp,
                    data = chpl_only[tier_group == "Tier1_2"],
                    cluster = ~hs6)
  m_tier3 <- feols(log_trade ~ post_sanctions + post_chpl |
                     cp,
                   data = chpl_only[tier_group == "Tier3"],
                   cluster = ~hs6)
  m_tier4 <- feols(log_trade ~ post_sanctions + post_chpl |
                     cp,
                   data = chpl_only[tier_group == "Tier4"],
                   cluster = ~hs6)
}

cat("Tier 1-2 (critical weapons components):\n")
print(summary(m_tier12))
cat("\nTier 3 (electronics/bearings):\n")
print(summary(m_tier3))
cat("\nTier 4 (manufacturing equipment):\n")
print(summary(m_tier4))

tier_coefs <- rbindlist(list(
  extract_coefs(m_tier12, "Tier1_2"),
  extract_coefs(m_tier3, "Tier3"),
  extract_coefs(m_tier4, "Tier4")
), fill = TRUE)

fwrite(tier_coefs, file.path(DATA_DIR, "tier_regression_coefs.csv"))

## ============================================================
## Sanctions Leakage Rate
## ============================================================

cat("\n=== SANCTIONS LEAKAGE CALCULATION ===\n\n")

has_western <- any(panel$role == "western")

if (has_western) {
  # Western supply collapse
  western <- panel[role == "western"]
  western_pre <- western[year <= 2021, .(pre_western = sum(fob_value)), by = .(hs6, is_chpl)]
  western_post <- western[year == 2024, .(post_western = sum(fob_value)), by = .(hs6, is_chpl)]

  # Transit rerouting
  transit <- panel[role == "transit"]
  transit_pre <- transit[year <= 2021, .(
    pre_transit = sum(fob_value) / length(unique(transit[year <= 2021]$year))
  ), by = .(hs6, is_chpl)]
  transit_post <- transit[year == 2023, .(post_transit = sum(fob_value)), by = .(hs6, is_chpl)]

  leakage <- merge(western_pre, western_post, by = c("hs6", "is_chpl"), all = TRUE)
  leakage <- merge(leakage, transit_pre, by = c("hs6", "is_chpl"), all = TRUE)
  leakage <- merge(leakage, transit_post, by = c("hs6", "is_chpl"), all = TRUE)
  leakage[is.na(leakage)] <- 0

  leakage_summary <- leakage[, .(
    western_supply_pre = sum(pre_western) / length(unique(western[year <= 2021]$year)),
    western_supply_post = sum(post_western),
    transit_rerouting_pre = sum(pre_transit),
    transit_rerouting_post = sum(post_transit)
  ), by = is_chpl]

  leakage_summary[, western_collapse := western_supply_pre - western_supply_post]
  leakage_summary[, transit_increase := transit_rerouting_post - transit_rerouting_pre]
  leakage_summary[, leakage_rate := fifelse(western_collapse > 0,
                                             transit_increase / western_collapse, NA_real_)]

  cat("Sanctions leakage by CHPL status:\n")
  print(leakage_summary)
  fwrite(leakage_summary, file.path(DATA_DIR, "leakage_rates.csv"))
} else {
  # Transit-only: compute rerouting magnitude without western benchmark
  transit <- panel[role == "transit"]
  transit_pre <- transit[year <= 2021, .(
    pre_transit = sum(fob_value) / length(unique(transit[year <= 2021]$year))
  ), by = .(hs6, is_chpl)]
  transit_peak <- transit[year == 2023, .(peak_transit = sum(fob_value)), by = .(hs6, is_chpl)]
  transit_post <- transit[year == 2024, .(post_transit = sum(fob_value)), by = .(hs6, is_chpl)]

  leakage <- merge(transit_pre, transit_peak, by = c("hs6", "is_chpl"), all = TRUE)
  leakage <- merge(leakage, transit_post, by = c("hs6", "is_chpl"), all = TRUE)
  leakage[is.na(leakage)] <- 0

  leakage_summary <- leakage[, .(
    western_supply_pre = 0,
    western_supply_post = 0,
    transit_rerouting_pre = sum(pre_transit),
    transit_rerouting_post = sum(peak_transit),
    transit_post_chpl = sum(post_transit)
  ), by = is_chpl]

  leakage_summary[, western_collapse := 0]
  leakage_summary[, transit_increase := transit_rerouting_post - transit_rerouting_pre]
  leakage_summary[, enforcement_drop := transit_rerouting_post - transit_post_chpl]
  leakage_summary[, leakage_rate := NA_real_]

  cat("Transit rerouting (no western benchmark):\n")
  print(leakage_summary)
  fwrite(leakage_summary, file.path(DATA_DIR, "leakage_rates.csv"))
}

## ============================================================
## Save all results
## ============================================================

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Results saved to:", DATA_DIR, "\n")
cat("Files: main_regression_coefs.csv, tier_regression_coefs.csv, leakage_rates.csv\n")
