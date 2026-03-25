# 04_robustness.R — Robustness Checks for apep_0892
# Moldova Wine Embargo

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]

load(file.path(data_dir, "main_models.RData"))

# ═══════════════════════════════════════════════════════════════════════
# 1. Placebo Treatment Dates
# ═══════════════════════════════════════════════════════════════════════
cat("=== Placebo Treatment Dates ===\n")

# Test placebo at Sept 2012 (1 year before) — using only pre-treatment data
pre_data <- panel[ym < as.Date("2013-09-01")]
pre_data[, placebo_post := as.integer(ym >= as.Date("2012-09-01"))]

placebo_m <- feols(log_mean ~ vine_per_cap:placebo_post | raion + ym_fe,
                   data = pre_data, cluster = ~raion)

cat("Placebo (Sept 2012):\n")
summary(placebo_m)

# ═══════════════════════════════════════════════════════════════════════
# 2. Leave-One-Out (Drop Each Raion)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Leave-One-Out ===\n")

raions <- unique(panel$raion)
loo_coefs <- numeric(length(raions))
names(loo_coefs) <- raions

for (i in seq_along(raions)) {
  d <- panel[raion != raions[i]]
  fit <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
               data = d, cluster = ~raion)
  loo_coefs[i] <- coef(fit)[1]
}

cat("LOO range: [", round(min(loo_coefs, na.rm = TRUE), 4), ",",
    round(max(loo_coefs, na.rm = TRUE), 4), "]\n")
cat("Full sample:", round(coef(m2)[1], 4), "\n")
cat("Most influential (drop shifts estimate most):\n")
loo_diff <- abs(loo_coefs - coef(m2)[1])
top3 <- order(loo_diff, decreasing = TRUE)[1:3]
for (j in top3) {
  cat("  Drop", raions[j], ": coef =", round(loo_coefs[j], 4),
      "(diff:", round(loo_coefs[j] - coef(m2)[1], 4), ")\n")
}

fwrite(data.table(raion = raions, loo_coef = loo_coefs),
       file.path(data_dir, "loo_results.csv"))

# ═══════════════════════════════════════════════════════════════════════
# 3. Exclude Transnistria (Unrecognized Territory)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Exclude Transnistria ===\n")

panel_no_trans <- panel[raion != "Transnistria"]

m_no_trans <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
                    data = panel_no_trans, cluster = ~raion)
cat("Without Transnistria:\n")
summary(m_no_trans)

# ═══════════════════════════════════════════════════════════════════════
# 4. Exclude Chisinau (Capital City Dominance)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Exclude Chisinau ===\n")

panel_no_chi <- panel[raion != "Chisinau"]

m_no_chi <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
                  data = panel_no_chi, cluster = ~raion)
cat("Without Chisinau:\n")
summary(m_no_chi)

# ═══════════════════════════════════════════════════════════════════════
# 5. Alternative Outcome: Sum of Nightlights
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Alternative Outcome: Log Sum ===\n")

m_sum <- feols(log_sum ~ vine_per_cap:post | raion + ym_fe,
               data = panel, cluster = ~raion)
cat("Log sum nightlights:\n")
summary(m_sum)

# ═══════════════════════════════════════════════════════════════════════
# 6. Quadratic Time Trend by Raion (Control for Differential Trends)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Raion-Specific Linear Trends ===\n")

panel[, time_trend := as.numeric(ym - min(ym)) / 365.25]

m_trend <- feols(log_mean ~ vine_per_cap:post + raion:time_trend | raion + ym_fe,
                 data = panel, cluster = ~raion)
cat("With raion-specific linear trends:\n")
summary(m_trend)

# ═══════════════════════════════════════════════════════════════════════
# 7. Randomization Inference
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Randomization Inference ===\n")

set.seed(2024)
n_perms <- 999
actual_coef <- coef(m2)[1]

perm_coefs <- numeric(n_perms)
vineyard <- unique(panel[, .(raion, vine_per_cap)])

for (p in 1:n_perms) {
  # Randomly permute vineyard shares across raions
  perm_shares <- vineyard[, .(raion, vine_per_cap_perm = sample(vine_per_cap))]
  panel_perm <- merge(panel, perm_shares, by = "raion")
  panel_perm[, treat_perm := vine_per_cap_perm * post]

  fit <- tryCatch({
    feols(log_mean ~ vine_per_cap_perm:post | raion + ym_fe,
          data = panel_perm, cluster = ~raion)
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    perm_coefs[p] <- coef(fit)[1]
  } else {
    perm_coefs[p] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pval <- mean(abs(perm_coefs) >= abs(actual_coef))

cat("Actual coefficient:", round(actual_coef, 4), "\n")
cat("RI p-value (two-sided):", round(ri_pval, 4), "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs), 4),
    ", SD =", round(sd(perm_coefs), 4), "\n")

# ═══════════════════════════════════════════════════════════════════════
# Save All Robustness Results
# ═══════════════════════════════════════════════════════════════════════

save(placebo_m, m_no_trans, m_no_chi, m_sum, m_trend,
     loo_coefs, ri_pval, perm_coefs,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness Complete ===\n")
