# 04_robustness.R — Robustness checks for NFA reform analysis
# apep_0813/v1

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- readRDS("data/panel_clean.rds")
cat("=== Robustness Checks ===\n\n")

results <- list()

# -------------------------------------------------------------------
# 1. Placebo cutoffs (2004, 2006)
# -------------------------------------------------------------------
cat("--- R1: Placebo cutoffs ---\n")

for (placebo_year in c(2004, 2006)) {
  pdata <- panel[year < 2008]  # Only pre-NFA data
  pdata[, placebo_post := as.integer(year >= placebo_year)]
  pdata[, placebo_interact := nfa_intensity * placebo_post]

  m_placebo <- feols(net_migration_rate ~ placebo_interact | canton_id + year,
                     data = pdata, cluster = ~canton_id)

  cat(sprintf("\nPlacebo cutoff %d (pre-NFA data only):\n", placebo_year))
  cat(sprintf("  Coefficient: %.3f (SE: %.3f, p: %.3f)\n",
              coef(m_placebo)["placebo_interact"],
              sqrt(diag(vcov(m_placebo)))["placebo_interact"],
              pvalue(m_placebo)["placebo_interact"]))

  results[[paste0("placebo_", placebo_year)]] <- m_placebo
}

# -------------------------------------------------------------------
# 2. Excluding near-zero cantons
# -------------------------------------------------------------------
cat("\n--- R2: Excluding near-zero cantons ---\n")

panel_excl_nz <- panel[nfa_group != "near_zero"]
m_excl_nz <- feols(net_migration_rate ~ intensity_post | canton_id + year,
                   data = panel_excl_nz, cluster = ~canton_id)

cat(sprintf("Excluding BL, VD (near-zero): coef = %.3f (SE: %.3f)\n",
            coef(m_excl_nz)["intensity_post"],
            sqrt(diag(vcov(m_excl_nz)))["intensity_post"]))
results[["excl_nearzero"]] <- m_excl_nz

# -------------------------------------------------------------------
# 3. Excluding Zug (extreme outlier, RI = 246.7)
# -------------------------------------------------------------------
cat("\n--- R3: Excluding Zug (RI outlier) ---\n")

m_excl_zug <- feols(net_migration_rate ~ intensity_post | canton_id + year,
                    data = panel[canton != "ZG"], cluster = ~canton_id)

cat(sprintf("Excluding Zug: coef = %.3f (SE: %.3f)\n",
            coef(m_excl_zug)["intensity_post"],
            sqrt(diag(vcov(m_excl_zug)))["intensity_post"]))
results[["excl_zug"]] <- m_excl_zug

# -------------------------------------------------------------------
# 4. Canton-specific linear trends
# -------------------------------------------------------------------
cat("\n--- R4: Canton-specific linear trends ---\n")

panel[, canton_trend := canton_id * year]
m_trends <- feols(net_migration_rate ~ intensity_post | canton_id + year +
                    canton_id[year],
                  data = panel, cluster = ~canton_id)

cat(sprintf("With canton-specific trends: coef = %.3f (SE: %.3f)\n",
            coef(m_trends)["intensity_post"],
            sqrt(diag(vcov(m_trends)))["intensity_post"]))
results[["canton_trends"]] <- m_trends

# -------------------------------------------------------------------
# 5. Leave-one-out: drop each canton
# -------------------------------------------------------------------
cat("\n--- R5: Leave-one-out sensitivity ---\n")

loo_results <- data.table()
for (c in unique(panel$canton_id)) {
  m_loo <- feols(net_migration_rate ~ intensity_post | canton_id + year,
                 data = panel[canton_id != c], cluster = ~canton_id)
  loo_results <- rbind(loo_results, data.table(
    dropped_canton = panel[canton_id == c, canton[1]],
    coef = coef(m_loo)["intensity_post"],
    se = sqrt(diag(vcov(m_loo)))["intensity_post"]
  ))
}

cat("Leave-one-out range:\n")
cat(sprintf("  Min coef: %.3f (drop %s)\n",
            min(loo_results$coef), loo_results[which.min(coef), dropped_canton]))
cat(sprintf("  Max coef: %.3f (drop %s)\n",
            max(loo_results$coef), loo_results[which.max(coef), dropped_canton]))
cat(sprintf("  Main coef: %.3f\n",
            coef(feols(net_migration_rate ~ intensity_post | canton_id + year,
                       data = panel, cluster = ~canton_id))["intensity_post"]))

results[["loo"]] <- loo_results

# -------------------------------------------------------------------
# 6. Randomization inference
# -------------------------------------------------------------------
cat("\n--- R6: Randomization inference ---\n")

set.seed(20260323)
n_perms <- 1000
main_coef <- coef(feols(net_migration_rate ~ intensity_post | canton_id + year,
                        data = panel, cluster = ~canton_id))["intensity_post"]

ri_coefs <- numeric(n_perms)
cantons <- unique(panel$canton_id)

for (i in 1:n_perms) {
  # Permute NFA intensity across cantons
  perm_map <- data.table(
    canton_id = cantons,
    perm_intensity = sample(unique(panel$nfa_intensity))
  )
  pdata <- merge(panel, perm_map, by = "canton_id")
  pdata[, perm_interact := perm_intensity * post]

  m_ri <- feols(net_migration_rate ~ perm_interact | canton_id + year,
                data = pdata, cluster = ~canton_id)
  ri_coefs[i] <- coef(m_ri)["perm_interact"]
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(main_coef))
cat(sprintf("Randomization inference (1000 permutations):\n"))
cat(sprintf("  Main coefficient: %.3f\n", main_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  RI distribution: mean=%.3f, sd=%.3f\n",
            mean(ri_coefs), sd(ri_coefs)))

results[["ri_coefs"]] <- ri_coefs
results[["ri_pvalue"]] <- ri_pvalue

# -------------------------------------------------------------------
# 7. Alternative outcome: population growth
# -------------------------------------------------------------------
cat("\n--- R7: Population growth as outcome ---\n")

m_popgr <- feols(pop_growth ~ intensity_post | canton_id + year,
                 data = panel[!is.na(pop_growth)], cluster = ~canton_id)

cat(sprintf("Population growth: coef = %.3f (SE: %.3f)\n",
            coef(m_popgr)["intensity_post"],
            sqrt(diag(vcov(m_popgr)))["intensity_post"]))
results[["pop_growth"]] <- m_popgr

# -------------------------------------------------------------------
# Save all robustness results
# -------------------------------------------------------------------
saveRDS(results, "data/robustness.rds")
cat("\n=== Robustness checks complete ===\n")
