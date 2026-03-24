# 04_robustness.R — Robustness checks
# apep_0844: State Disinvestment and Enrollment Composition

source("00_packages.R")

panel <- fread("../data/panel.csv")

# Reconstruct analysis sample
panel <- panel[nchar(state) == 2 &
               !state %in% c("AS", "GU", "MH", "FM", "MP", "PW", "PR", "VI")]

cpi <- data.table(year = 2004:2022,
  cpi = c(188.9, 195.3, 201.6, 207.3, 215.3, 214.5, 218.1,
          224.9, 229.6, 233.0, 236.7, 237.0, 240.0, 245.1, 251.1,
          255.7, 251.7, 258.8, 292.7))
cpi[, deflator := max(cpi) / cpi]
panel <- merge(panel, cpi, by = "year", all.x = TRUE)
panel[, real_tuition := tuition_instate * deflator]
panel[, real_approp_ps := approp_per_student * deflator]
panel[, log_real_tuition := log(pmax(real_tuition, 1))]

# Cut intensity
state_pre <- panel[year %in% 2007:2008 & !is.na(real_approp_ps) & real_approp_ps > 0,
                   .(pre_approp = mean(real_approp_ps, na.rm = TRUE)), by = state]
state_post <- panel[year %in% 2011:2012 & !is.na(real_approp_ps) & real_approp_ps > 0,
                    .(post_approp = mean(real_approp_ps, na.rm = TRUE)), by = state]
state_cut <- merge(state_pre, state_post, by = "state")
state_cut[, cut_pct := (post_approp - pre_approp) / pre_approp]
state_cut[, cut_intensity := -cut_pct]
panel <- merge(panel, state_cut[, .(state, cut_intensity)], by = "state", all.x = TRUE)

analysis <- panel[!is.na(real_tuition) & !is.na(real_approp_ps) &
                  real_approp_ps > 0 & real_tuition > 0 &
                  !is.na(EFTOTLT) & EFTOTLT > 100 &
                  !is.na(cut_intensity) & year >= 2004]
analysis[, post := as.integer(year >= 2009)]

# ============================================================================
# 1. Trimmed sample: drop top/bottom 5% of cut_intensity
# ============================================================================
cat("=== Robustness 1: Trimmed cut intensity ===\n")
q05 <- quantile(state_cut$cut_intensity, 0.05, na.rm = TRUE)
q95 <- quantile(state_cut$cut_intensity, 0.95, na.rm = TRUE)
trimmed <- analysis[cut_intensity >= q05 & cut_intensity <= q95]
cat("  Trimmed sample:", nrow(trimmed), "obs (", uniqueN(trimmed$state), "states)\n")

rob1_tuition <- feols(log_real_tuition ~ cut_intensity:post | UNITID + year,
                      data = trimmed, cluster = ~state)
rob1_pell <- feols(pell_share ~ cut_intensity:post | UNITID + year,
                   data = trimmed[!is.na(pell_share)], cluster = ~state)

# ============================================================================
# 2. Leave-one-state-out
# ============================================================================
cat("\n=== Robustness 2: Leave-one-state-out ===\n")
states <- unique(analysis$state)
loso_pell <- sapply(states, function(s) {
  m <- feols(pell_share ~ cut_intensity:post | UNITID + year,
             data = analysis[state != s & !is.na(pell_share)], cluster = ~state)
  coeftable(m)[1, 1]
})
cat("  Pell coef range (LOSO):", round(min(loso_pell), 4), "to",
    round(max(loso_pell), 4), "\n")
cat("  Baseline:", round(coeftable(feols(pell_share ~ cut_intensity:post | UNITID + year,
    data = analysis[!is.na(pell_share)], cluster = ~state))[1,1], 4), "\n")

# ============================================================================
# 3. Alternative post periods
# ============================================================================
cat("\n=== Robustness 3: Alternative post periods ===\n")
for (post_year in c(2010, 2011, 2012)) {
  analysis[, post_alt := as.integer(year >= post_year)]
  m <- feols(pell_share ~ cut_intensity:post_alt | UNITID + year,
             data = analysis[!is.na(pell_share)], cluster = ~state)
  ct <- coeftable(m)
  cat(sprintf("  Post >= %d: coef = %+.4f (%.4f) p = %.3f\n",
              post_year, ct[1,1], ct[1,2], ct[1,4]))
}

# ============================================================================
# 4. Binary treatment (above/below median cut)
# ============================================================================
cat("\n=== Robustness 4: Binary treatment ===\n")
med_cut <- median(state_cut$cut_intensity, na.rm = TRUE)
analysis[, high_cut := as.integer(cut_intensity > med_cut)]

rob4_tuition <- feols(log_real_tuition ~ high_cut:post | UNITID + year,
                      data = analysis, cluster = ~state)
rob4_pell <- feols(pell_share ~ high_cut:post | UNITID + year,
                   data = analysis[!is.na(pell_share)], cluster = ~state)

ct_t <- coeftable(rob4_tuition)
ct_p <- coeftable(rob4_pell)
cat(sprintf("  Tuition: coef = %+.4f (%.4f) p = %.3f\n", ct_t[1,1], ct_t[1,2], ct_t[1,4]))
cat(sprintf("  Pell:    coef = %+.4f (%.4f) p = %.3f\n", ct_p[1,1], ct_p[1,2], ct_p[1,4]))

# ============================================================================
# 5. Controls for state economic conditions
# ============================================================================
cat("\n=== Robustness 5: State unemployment controls (FRED) ===\n")
# Try to load state unemployment data
gdp_file <- "../data/fred_gdp_growth.csv"
if (file.exists(gdp_file)) {
  gdp <- fread(gdp_file)
  analysis <- merge(analysis, gdp[, .(year, gdp_growth)], by = "year", all.x = TRUE)
  rob5_pell <- feols(pell_share ~ cut_intensity:post + gdp_growth | UNITID + year,
                     data = analysis[!is.na(pell_share) & !is.na(gdp_growth)],
                     cluster = ~state)
  ct <- coeftable(rob5_pell)
  cat(sprintf("  Pell (with GDP control): coef = %+.4f (%.4f) p = %.3f\n",
              ct[1,1], ct[1,2], ct[1,4]))
} else {
  cat("  No FRED data available for controls.\n")
}

# ============================================================================
# Save robustness results
# ============================================================================
robustness <- list(
  trimmed_tuition = rob1_tuition,
  trimmed_pell = rob1_pell,
  binary_tuition = rob4_tuition,
  binary_pell = rob4_pell,
  loso_pell_range = c(min(loso_pell), max(loso_pell))
)
saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
