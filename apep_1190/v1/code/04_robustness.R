## 04_robustness.R — Robustness checks
## apep_1190: Grocery Store Exits and Birth Outcomes

source("00_packages.R")
data_dir <- "../data"

load(file.path(data_dir, "main_results.RData"))

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. PLACEBO: C-SECTION RATE (should not respond to food access)
# ============================================================================
cat("\n--- Placebo: C-section delivery rate ---\n")

# C-section rates should not change with grocery access if the mechanism
# is nutritional (food → birth weight). C-sections are driven by
# medical decisions, not maternal nutrition.
# Note: CHR doesn't have C-section. Use teen birth rate as alternative placebo
# (teen pregnancy is driven by sexual behavior, not food access)

placebo1 <- feols(teen_birth_rate ~ chain_shocks_cumulative | fips + year,
                   data = analysis[!is.na(teen_birth_rate)],
                   cluster = ~fips)
cat("Placebo (teen birth rate ~ chain shocks):\n")
summary(placebo1)

# Premature death is an overly broad outcome — should show effect
# if chain shocks capture general economic decline
placebo2 <- feols(premature_death_rate ~ chain_shocks_cumulative | fips + year,
                   data = analysis[!is.na(premature_death_rate)],
                   cluster = ~fips)
cat("\nBroad outcome (premature death ~ chain shocks):\n")
summary(placebo2)

# ============================================================================
# 2. ALTERNATIVE SPECIFICATIONS
# ============================================================================
cat("\n--- Alternative specifications ---\n")

# a) State-clustered SEs (more conservative)
robust_state <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
                       data = analysis,
                       cluster = ~state_fips)
cat("State-clustered SEs:\n")
summary(robust_state)

# b) Census division × year FE (controls for regional trends)
# Census divisions: 1-9 (more granular than regions, less than states)
div_map <- data.table(
  state_fips = c("09","23","25","33","44","50",  # New England
                  "34","36","42",                  # Mid-Atlantic
                  "17","18","26","39","55",        # East North Central
                  "19","20","27","29","31","38","46", # West North Central
                  "10","11","12","13","24","37","45","51","54", # South Atlantic
                  "01","21","28","47",              # East South Central
                  "05","22","40","48",              # West South Central
                  "04","08","16","30","32","35","49","56", # Mountain
                  "02","06","15","41","53"),        # Pacific
  division = c(rep(1,6), rep(2,3), rep(3,5), rep(4,7),
               rep(5,9), rep(6,4), rep(7,4), rep(8,8), rep(9,5))
)
div_map[, state_fips := as.character(state_fips)]
analysis[, state_fips := as.character(state_fips)]
analysis <- merge(analysis, div_map, by = "state_fips", all.x = TRUE)
analysis[is.na(division), division := 0]

robust_trends <- feols(lbw_pct ~ chain_shocks_cumulative | fips + division^year,
                        data = analysis,
                        cluster = ~fips)
cat("\nWith Census division × year FE:\n")
summary(robust_trends)

# c) Drop A&P states (test sensitivity to single chain event)
robust_no_ap <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
                       data = analysis[ap_exposed == FALSE],
                       cluster = ~fips)
cat("\nDropping A&P-exposed states:\n")
summary(robust_no_ap)

# d) Different IV: use only Tops + Winn-Dixie (2018 events)
analysis[, post_2018_exposed := as.integer(
  (tops_exposed | winn_dixie_exposed) & year >= 2019
)]

robust_2018 <- feols(lbw_pct ~ post_2018_exposed | fips + year,
                      data = analysis,
                      cluster = ~fips)
cat("\n2018 bankruptcies only (Tops + Winn-Dixie):\n")
summary(robust_2018)

# ============================================================================
# 3. LEAVE-ONE-OUT: DROP EACH EXPOSED STATE
# ============================================================================
cat("\n--- Leave-one-out by state ---\n")

exposed_states <- unique(analysis$state_fips[analysis$n_chains_exposed > 0])
loo_results <- data.table()

for (st in exposed_states) {
  loo <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
               data = analysis[state_fips != st],
               cluster = ~fips)
  loo_results <- rbind(loo_results, data.table(
    state_dropped = st,
    coef = coef(loo)[1],
    se = se(loo)[1],
    pval = pvalue(loo)[1]
  ))
}

cat(sprintf("LOO range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("All significant at 10%%: %s\n",
            ifelse(all(loo_results$pval < 0.10), "YES", "NO")))

# ============================================================================
# 4. HETEROGENEITY BY RACE
# ============================================================================
cat("\n--- Heterogeneity by race ---\n")

analysis[, lbw_pct_black := as.numeric(lbw_rate_black) * 100]
analysis[, lbw_pct_white := as.numeric(lbw_rate_white) * 100]
analysis[, lbw_pct_hispanic := as.numeric(lbw_rate_hispanic) * 100]

het_black <- feols(lbw_pct_black ~ chain_shocks_cumulative | fips + year,
                    data = analysis[!is.na(lbw_pct_black)],
                    cluster = ~fips)
het_white <- feols(lbw_pct_white ~ chain_shocks_cumulative | fips + year,
                    data = analysis[!is.na(lbw_pct_white)],
                    cluster = ~fips)
het_hisp <- feols(lbw_pct_hispanic ~ chain_shocks_cumulative | fips + year,
                   data = analysis[!is.na(lbw_pct_hispanic)],
                   cluster = ~fips)

cat("By race:\n")
etable(het_black, het_white, het_hisp,
       headers = c("Black", "White", "Hispanic"),
       se.below = TRUE)

# ============================================================================
# 5. WILD CLUSTER BOOTSTRAP (small number of treated clusters)
# ============================================================================
cat("\n--- Wild cluster bootstrap ---\n")

# The number of chain-exposed states is ~24, which is moderate
# Wild cluster bootstrap provides more reliable inference
tryCatch({
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)
    wcb <- boottest(rf1, param = "chain_shocks_cumulative",
                     B = 999, clustid = ~fips, type = "webb")
    cat(sprintf("Wild cluster bootstrap p-value: %.4f\n", wcb$p_val))
    cat(sprintf("Wild cluster bootstrap CI: [%.4f, %.4f]\n",
                wcb$conf_int[1], wcb$conf_int[2]))
  } else {
    cat("fwildclusterboot not installed, skipping\n")
  }
}, error = function(e) {
  cat(sprintf("Wild bootstrap error: %s\n", e$message))
})

# ============================================================================
# 6. SAVE ROBUSTNESS RESULTS
# ============================================================================
save(placebo1, placebo2, robust_state, robust_trends, robust_no_ap,
     robust_2018, loo_results, het_black, het_white, het_hisp,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== Robustness checks complete ===\n")
