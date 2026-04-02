# 04_robustness.R — Robustness checks for MPA fish DiD
# (1) Wild cluster bootstrap, (2) Leave-one-out, (3) Channel Islands,
# (4) Species-level DDD, (5) HonestDiD sensitivity

setwd(here::here())
source("code/00_packages.R")

panel <- readRDS("data/panel_main.rds")
panel_spp <- readRDS("data/panel_spp_main.rds")
panel_full <- readRDS("data/panel_full.rds")

# Add treatment variable
panel[, treated := as.integer(mpa_status == "MPA_mainland") * as.integer(YEAR >= 2008)]

# ========================================================================
# (1) Permutation Inference — critical with few treated clusters
# ========================================================================
cat("\n=== Permutation Inference (Site-Level) ===\n")

# Main specification: log targeted density
m_targeted <- feols(log_targeted ~ treated | SITE + YEAR, data = panel)
m_all <- feols(log_density ~ treated | SITE + YEAR, data = panel)

# Site-level permutation: randomly assign 2 of 9 sites as "treated"
set.seed(42)
n_perm_boot <- 5000
mainland_sites <- unique(panel$SITE)
n_treated_sites <- 2

true_coef_targeted <- coef(m_targeted)["treated"]
true_coef_all <- coef(m_all)["treated"]

perm_targeted <- numeric(n_perm_boot)
perm_all <- numeric(n_perm_boot)

for (i in 1:n_perm_boot) {
  perm_sites <- sample(mainland_sites, n_treated_sites)
  panel[, perm_treat := as.integer(SITE %in% perm_sites) * as.integer(YEAR >= 2008)]
  m_pt <- feols(log_targeted ~ perm_treat | SITE + YEAR, data = panel)
  m_pa <- feols(log_density ~ perm_treat | SITE + YEAR, data = panel)
  perm_targeted[i] <- coef(m_pt)["perm_treat"]
  perm_all[i] <- coef(m_pa)["perm_treat"]
}

perm_p_targeted <- mean(abs(perm_targeted) >= abs(true_coef_targeted))
perm_p_all <- mean(abs(perm_all) >= abs(true_coef_all))

cat("Permutation p-value (targeted):", perm_p_targeted, "\n")
cat("Permutation p-value (all fish):", perm_p_all, "\n")

saveRDS(list(perm_p_targeted = perm_p_targeted, perm_p_all = perm_p_all,
             perm_targeted = perm_targeted, perm_all = perm_all,
             true_coef_targeted = true_coef_targeted,
             true_coef_all = true_coef_all),
        "data/bootstrap_results.rds")

# ========================================================================
# (2) Leave-One-Out by Site
# ========================================================================
cat("\n=== Leave-One-Out ===\n")

sites <- unique(panel$SITE)
loo_results <- data.table()

for (s in sites) {
  p_loo <- panel[SITE != s]
  m_loo <- feols(log_targeted ~ treated | SITE + YEAR, data = p_loo,
                 cluster = ~SITE)
  loo_results <- rbind(loo_results, data.table(
    dropped_site = s,
    coef = coef(m_loo)["treated"],
    se = se(m_loo)["treated"],
    p = pvalue(m_loo)["treated"]
  ))
}

print(loo_results)
cat("LOO coefficient range:", range(loo_results$coef), "\n")
saveRDS(loo_results, "data/loo_results.rds")

# ========================================================================
# (3) Channel Islands — Always-treated dose-response
# ========================================================================
cat("\n=== Channel Islands (Dose-Response) ===\n")

# Include Channel Islands: compare islands (treated 2003) vs mainland MPA (2007)
# vs mainland control (never). Treatment years differ.
panel_full[, treated_mainland := as.integer(mpa_status == "MPA_mainland") *
             as.integer(YEAR >= 2008)]
panel_full[, treated_island := as.integer(mpa_status == "MPA_island") *
             as.integer(YEAR >= 2004)]  # Federal reserves 2003

m_full <- feols(log_targeted ~ treated_mainland + treated_island | SITE + YEAR,
                data = panel_full, cluster = ~SITE)
summary(m_full)
saveRDS(m_full, "data/model_full_islands.rds")

# ========================================================================
# (4) Species-Level DDD (within-site mechanism test)
# ========================================================================
cat("\n=== Species-Level DDD ===\n")

# DDD: MPA × Post × Targeted
# Within the same site, targeted species should benefit more from MPA protection
panel_spp[, treated_spp := as.integer(mpa_status == "MPA_mainland") *
            as.integer(YEAR >= 2008)]

# Species panel: site × year × species
m_ddd <- feols(log_density ~ treated_spp * targeted |
                 SITE^SP_CODE + YEAR^SP_CODE + SITE^YEAR,
               data = panel_spp, cluster = ~SITE)

cat("DDD coefficient (MPA × Post × Targeted):\n")
summary(m_ddd)
saveRDS(m_ddd, "data/model_ddd.rds")

# ========================================================================
# (5) HonestDiD — Sensitivity to parallel trends violations
# ========================================================================
cat("\n=== HonestDiD Sensitivity ===\n")

# Event study for HonestDiD
panel[, rel_year := YEAR - 2007]
panel[, rel_year_binned := pmax(-6, pmin(17, rel_year))]

es_for_honest <- feols(log_targeted ~ i(rel_year_binned, mpa, ref = 0) | SITE + YEAR,
                       data = panel, cluster = ~SITE)

# Extract pre and post coefficients
honest_result <- tryCatch({
  betahat <- coef(es_for_honest)
  sigma <- vcov(es_for_honest)

  # Identify pre and post period indices
  coef_names <- names(betahat)
  pre_idx <- grep("::-[0-9]", coef_names)
  post_idx <- grep("::[0-9]", coef_names)
  post_idx <- setdiff(post_idx, pre_idx)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    delta_rm <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat, sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes sensitivity computed.\n")
    delta_rm
  } else {
    cat("Not enough pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  NULL
})

saveRDS(honest_result, "data/honest_did_results.rds")

# ========================================================================
# (6) Summary of Randomization Inference (already computed in section 1)
# ========================================================================
# RI results are the same as the permutation results in section 1
# Save a separate object for backward compatibility with tables script
saveRDS(list(true_coef = true_coef_targeted,
             perm_coefs = perm_targeted,
             ri_p = perm_p_targeted),
        "data/ri_results.rds")

cat("\nAll robustness checks complete.\n")
