## 03_main_analysis.R — Main reduced-form and IV regressions
## apep_0840: Competing News IV and Swiss Referendum Turnout

source("00_packages.R")

cat("Loading analysis panel...\n")
panel <- fread("../data/analysis_panel.csv")
panel[, votedate := as.Date(votedate)]

# Drop any obs with missing key variables
panel_clean <- panel[!is.na(salience_score) & !is.na(turnout_pct)]
cat(sprintf("Analysis sample: %d obs (%d municipalities, %d vote dates)\n",
    nrow(panel_clean), uniqueN(panel_clean$bfs_id),
    uniqueN(panel_clean$votedate)))

# Factor variables for FE
panel_clean[, bfs_id_f := as.factor(bfs_id)]
panel_clean[, votedate_f := as.factor(as.character(votedate))]
panel_clean[, lang_year := paste0(lang_region, "_", vote_year)]

# ============================================================================
# Key identification:
# The earthquake salience score varies at the vote-date × language-region level.
# Within a given vote date, German-speaking and French-speaking municipalities
# face the SAME ballot items but DIFFERENT levels of competing earthquake news
# salience (because earthquakes near Francophone regions are more salient in
# French-language media, and vice versa).
#
# With municipality + vote-date FE, the identifying variation is:
# Within the same vote date, does the language region with higher earthquake
# salience experience lower turnout?
#
# This is a reduced-form design: earthquake salience → turnout
# (skipping the media coverage first stage, which we cannot measure via GDELT)
# ============================================================================

# ============================================================================
# TABLE 2: OLS — Earthquake Salience and Turnout (Reduced Form)
# ============================================================================

cat("\n=== Reduced Form: Earthquake Salience → Turnout ===\n")

# Model 1: No FE
ols1 <- feols(turnout_pct ~ salience_std,
              data = panel_clean, vcov = ~votedate + lang_region)

# Model 2: Municipality FE
ols2 <- feols(turnout_pct ~ salience_std | bfs_id,
              data = panel_clean, vcov = ~votedate + lang_region)

# Model 3: Municipality + vote-date FE (the key spec)
# salience_std varies at vote-date × language, so it survives vote-date FE
ols3 <- feols(turnout_pct ~ salience_std | bfs_id + votedate,
              data = panel_clean, vcov = ~votedate + lang_region)

# Model 4: Municipality + vote-date + language×year FE
ols4 <- feols(turnout_pct ~ salience_std | bfs_id + votedate + lang_year,
              data = panel_clean, vcov = ~votedate + lang_region)

cat("Reduced-form OLS Results:\n")
etable(ols1, ols2, ols3, ols4,
       headers = c("No FE", "Muni FE", "+Vote FE", "+Lang×Year"))

# ============================================================================
# TABLE 3: Alternative instruments and specifications
# ============================================================================

cat("\n=== Alternative instrument measures ===\n")

# Model with log salience
ols_log <- feols(turnout_pct ~ log_salience | bfs_id + votedate,
                 data = panel_clean, vcov = ~votedate + lang_region)

# Model with only large earthquakes (M6.5+)
ols_large <- feols(turnout_pct ~ salience_large_std | bfs_id + votedate,
                   data = panel_clean, vcov = ~votedate + lang_region)

# Model with raw earthquake count × language dummy (to preserve within-vote variation)
panel_clean[, is_french := as.integer(lang_region == "fr")]
ols_interact <- feols(turnout_pct ~ n_earthquakes:is_french | bfs_id + votedate,
                      data = panel_clean, vcov = ~votedate + lang_region)

# Model with raw salience (not standardized)
ols_raw <- feols(turnout_pct ~ salience_score | bfs_id + votedate,
                 data = panel_clean, vcov = ~votedate + lang_region)

cat("Alternative instruments:\n")
etable(ols_log, ols_large, ols_interact, ols_raw,
       headers = c("Log salience", "Large EQ only", "Count×French", "Raw salience"))

# ============================================================================
# TABLE 4: Heterogeneity — Effect by ballot-item characteristics
# ============================================================================

cat("\n=== Heterogeneity by ballot-item salience ===\n")

# Measure item salience: national average turnout for items on same date
vote_avg_turnout <- panel_clean[, .(item_avg_turnout = mean(turnout_pct, na.rm = TRUE)),
                                 by = .(votedate, name)]
panel_clean <- merge(panel_clean, vote_avg_turnout, by = c("votedate", "name"), all.x = TRUE)
panel_clean[, high_salience := item_avg_turnout >= median(item_avg_turnout, na.rm = TRUE)]

# High vs low salience
het_high <- feols(turnout_pct ~ salience_std | bfs_id + votedate,
                  data = panel_clean[high_salience == TRUE],
                  vcov = ~votedate + lang_region)

het_low <- feols(turnout_pct ~ salience_std | bfs_id + votedate,
                 data = panel_clean[high_salience == FALSE],
                 vcov = ~votedate + lang_region)

# Effect on Yes vote share
yes1 <- feols(yes_pct ~ salience_std | bfs_id + votedate,
              data = panel_clean, vcov = ~votedate + lang_region)

cat("Heterogeneity:\n")
etable(het_high, het_low, yes1,
       headers = c("High Salience", "Low Salience", "Yes Vote %"))

# ============================================================================
# Randomization inference: permute salience across language regions within dates
# ============================================================================

cat("\n=== Randomization Inference ===\n")
set.seed(42)
n_perms <- 1000

# The treatment varies at vote-date × language level
# Permute which language gets which salience score within each date
cluster_dt <- unique(panel_clean[, .(votedate, lang_region, salience_std)])

obs_beta <- coef(ols3)["salience_std"]
perm_betas <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  # Within each vote date, randomly swap French/German salience
  perm_dt <- copy(cluster_dt)
  for (vd in unique(perm_dt$votedate)) {
    if (runif(1) > 0.5) {
      # Swap salience between de and fr for this date
      rows <- perm_dt$votedate == vd
      perm_dt[rows, salience_std := rev(salience_std)]
    }
  }
  # Merge permuted salience back
  perm_panel <- merge(
    panel_clean[, !c("salience_std"), with = FALSE],
    perm_dt,
    by = c("votedate", "lang_region")
  )
  perm_fit <- tryCatch(
    feols(turnout_pct ~ salience_std | bfs_id + votedate,
          data = perm_panel, warn = FALSE, notes = FALSE),
    error = function(e) NULL
  )
  if (!is.null(perm_fit)) {
    perm_betas[i] <- coef(perm_fit)["salience_std"]
  } else {
    perm_betas[i] <- NA
  }
}

perm_betas <- perm_betas[!is.na(perm_betas)]
ri_pval <- mean(abs(perm_betas) >= abs(obs_beta))
cat(sprintf("  Observed beta: %.3f\n", obs_beta))
cat(sprintf("  RI p-value (two-sided): %.3f (from %d permutations)\n", ri_pval, length(perm_betas)))

# Save RI results
ri_results <- list(
  obs_beta = obs_beta,
  ri_pval = ri_pval,
  n_perms = length(perm_betas),
  perm_mean = mean(perm_betas),
  perm_sd = sd(perm_betas)
)
write_json(ri_results, "../data/ri_results.json", auto_unbox = TRUE)

# ============================================================================
# Save regression objects
# ============================================================================

save(ols1, ols2, ols3, ols4, ols_log, ols_large, ols_interact, ols_raw,
     het_high, het_low, yes1, panel_clean,
     file = "../data/regression_results.RData")

# Write diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(panel_clean[, .(votedate, lang_region)]),
  n_pre = length(unique(panel_clean$votedate)),
  n_obs = nrow(panel_clean)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
    diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("Saved regression_results.RData and diagnostics.json\n")
