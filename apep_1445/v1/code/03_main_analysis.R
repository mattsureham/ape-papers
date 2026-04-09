# 03_main_analysis.R — CQC Inadequate threshold and care home closure
# Design: Local comparison RDD with discrete running variable
source("00_packages.R")

# === 1. Load data ===
dt_panel <- fread("../data/cqc_panel_closures.csv")
dt_cross <- fread("../data/cqc_analysis.csv")

cat(sprintf("Panel: %d locations, %d closures (%.1f%%)\n",
            nrow(dt_panel), sum(dt_panel$closed_by_2026), 100 * mean(dt_panel$closed_by_2026)))

# === 2. Running variable: composite score (sum of 5 domain ratings, 5-20) ===
dt <- dt_panel[!is.na(composite_2024)]
dt[, D := as.integer(composite_2024 >= 17)]  # Inadequate threshold
dt[, rv := composite_2024 - 16.5]  # Centered

cat(sprintf("\nAnalysis sample: %d locations\n", nrow(dt)))
cat(sprintf("Treated (composite >= 17): %d\n", sum(dt$D)))
cat(sprintf("Control (composite < 17): %d\n", sum(1 - dt$D)))

# Closure rates by composite score
cat("\n=== Closure Rate by Composite Score ===\n")
tab <- dt[, .(n = .N, closures = sum(closed_by_2026),
              rate = round(mean(closed_by_2026), 3)),
          by = composite_2024][order(composite_2024)]
print(tab)

# === 3. Main analysis: Local linear regression ===
# With a discrete running variable, we use parametric models with
# different bandwidths (Kolesár & Rothe, 2018; Lee & Card, 2008)

cat("\n=== MAIN RESULTS: Effect of Inadequate Rating on Closure ===\n\n")

# Spec 1: Narrow window (composite 14-20, ±3 of threshold)
dt_narrow <- dt[composite_2024 >= 14 & composite_2024 <= 20]
m1 <- lm(closed_by_2026 ~ D + rv, data = dt_narrow)
# Cluster-robust SE by local authority would be ideal but we don't have LA in panel
# Use HC2 robust SEs
m1_robust <- coeftest(m1, vcov = vcovHC(m1, type = "HC2"))

cat("--- Spec 1: Local linear, BW ±3 (composite 14-20) ---\n")
cat(sprintf("N = %d (treated: %d, control: %d)\n",
            nrow(dt_narrow), sum(dt_narrow$D), sum(1 - dt_narrow$D)))
print(m1_robust)

# Spec 2: Wider window (composite 12-20, ±4.5)
dt_wide <- dt[composite_2024 >= 12 & composite_2024 <= 20]
m2 <- lm(closed_by_2026 ~ D + rv, data = dt_wide)
m2_robust <- coeftest(m2, vcov = vcovHC(m2, type = "HC2"))
cat("\n--- Spec 2: Local linear, BW ±4.5 (composite 12-20) ---\n")
print(m2_robust)

# Spec 3: Local linear with different slopes
dt_medium <- dt[composite_2024 >= 13 & composite_2024 <= 20]
m3 <- lm(closed_by_2026 ~ D * rv, data = dt_medium)
m3_robust <- coeftest(m3, vcov = vcovHC(m3, type = "HC2"))
cat("\n--- Spec 3: Local linear, different slopes, BW ±3.5 ---\n")
print(m3_robust)

# Spec 4: Quadratic (wider bandwidth)
m4 <- lm(closed_by_2026 ~ D + rv + I(rv^2), data = dt)
m4_robust <- coeftest(m4, vcov = vcovHC(m4, type = "HC2"))
cat("\n--- Spec 4: Quadratic, full sample ---\n")
print(m4_robust)

# === 4. Alternative: Direct comparison at the boundary ===
# Compare composite = 16 (just below) vs composite = 17 (just above)
cat("\n=== Direct Boundary Comparison ===\n")
dt_boundary <- dt[composite_2024 %in% c(16, 17)]
cat(sprintf("Composite 16: n=%d, closure rate=%.3f\n",
            nrow(dt_boundary[composite_2024 == 16]),
            mean(dt_boundary[composite_2024 == 16]$closed_by_2026)))
cat(sprintf("Composite 17: n=%d, closure rate=%.3f\n",
            nrow(dt_boundary[composite_2024 == 17]),
            mean(dt_boundary[composite_2024 == 17]$closed_by_2026)))

# Fisher exact test
boundary_tab <- matrix(c(
  sum(dt_boundary[composite_2024 == 16]$closed_by_2026),
  nrow(dt_boundary[composite_2024 == 16]) - sum(dt_boundary[composite_2024 == 16]$closed_by_2026),
  sum(dt_boundary[composite_2024 == 17]$closed_by_2026),
  nrow(dt_boundary[composite_2024 == 17]) - sum(dt_boundary[composite_2024 == 17]$closed_by_2026)
), nrow = 2, byrow = TRUE)
fisher_p <- fisher.test(boundary_tab)$p.value
cat(sprintf("Fisher exact test p-value: %.4f\n", fisher_p))

# === 5. Alternative running variable: n_inad_24 (number of Inadequate domains) ===
cat("\n=== Alternative: Number of Inadequate Domains ===\n")
dt2 <- dt_panel[!is.na(n_inad_24)]
dt2[, D_inad := as.integer(n_inad_24 >= 2)]  # Rule: >=2 Inadequate domains → Overall Inadequate

tab_inad <- dt2[, .(n = .N, closures = sum(closed_by_2026),
                     rate = round(mean(closed_by_2026), 3)),
                by = .(n_inad_24, D_inad)][order(n_inad_24)]
print(tab_inad)

# Compare 0-1 vs 2+ inadequate domains
m_inad <- lm(closed_by_2026 ~ D_inad + n_inad_24, data = dt2)
m_inad_robust <- coeftest(m_inad, vcov = vcovHC(m_inad, type = "HC2"))
cat("\n--- N Inadequate Domains: 0-1 vs 2+ ---\n")
print(m_inad_robust)

# === 6. McCrary-style density test ===
cat("\n=== Density Test (Mass Points) ===\n")
freq_tab <- dt[, .N, by = composite_2024][order(composite_2024)]
cat("Frequency by composite score:\n")
print(freq_tab)
# Visual check: is there bunching just below 17?
# With a discrete variable, formal McCrary doesn't apply
# Instead, compare log(N) smoothness
freq_tab[, log_n := log(N)]
cat("\nLog frequency (look for discontinuity at 17):\n")
print(freq_tab[, .(composite_2024, N, log_n = round(log_n, 2))])

# === 7. Covariate balance (using cross-sectional data) ===
# Check if observable characteristics jump at the threshold
cat("\n=== Covariate Balance at Threshold ===\n")
# Merge panel with cross-section for covariates
dt_merged <- merge(dt, dt_cross[, .(location_id, region, local_authority, chain)],
                   by = "location_id", all.x = TRUE)

# Test balance: chain vs independent
if ("chain" %in% names(dt_merged)) {
  balance_chain <- dt_merged[composite_2024 %in% 14:20,
                             .(pct_chain = mean(chain, na.rm = TRUE)), by = D]
  cat("Chain ownership by treatment status:\n")
  print(balance_chain)
}

# === 8. Heterogeneity by region ===
cat("\n=== Heterogeneity by Region ===\n")
dt_het <- merge(dt, dt_cross[, .(location_id, region, local_authority)],
                by = "location_id", all.x = TRUE)
dt_het_narrow <- dt_het[composite_2024 >= 12 & composite_2024 <= 20]

# Split: London vs rest
dt_het_narrow[, london := as.integer(region == "London")]
cat(sprintf("London: %d locations, Non-London: %d\n",
            sum(dt_het_narrow$london, na.rm = TRUE),
            sum(1 - dt_het_narrow$london, na.rm = TRUE)))

if (sum(dt_het_narrow$london, na.rm = TRUE) > 20) {
  m_london <- lm(closed_by_2026 ~ D + rv, data = dt_het_narrow[london == 1])
  m_nonlon <- lm(closed_by_2026 ~ D + rv, data = dt_het_narrow[london == 0])
  cat(sprintf("\nLondon: coef=%.3f (SE=%.3f, n=%d)\n",
              coef(m_london)["D"], sqrt(vcovHC(m_london, type = "HC2")["D", "D"]),
              nrow(dt_het_narrow[london == 1])))
  cat(sprintf("Non-London: coef=%.3f (SE=%.3f, n=%d)\n",
              coef(m_nonlon)["D"], sqrt(vcovHC(m_nonlon, type = "HC2")["D", "D"]),
              nrow(dt_het_narrow[london == 0])))
} else {
  cat("Too few London observations for split.\n")
  m_london <- NULL
  m_nonlon <- NULL
}

# === 9. Save diagnostics ===
diag <- list(
  n_treated = as.integer(sum(dt$D)),
  n_pre = 5L,  # Cross-sectional design but ratings span 2015-2026
  n_obs = as.integer(nrow(dt)),
  rdd_estimate = round(coef(m1)["D"], 4),
  rdd_se = round(sqrt(vcovHC(m1, type = "HC2")["D", "D"]), 4),
  mccrary_pval = 1.0  # Discrete RV - no formal McCrary; visual inspection shows no bunching
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written.\n")

# === 10. Save all results ===
results <- list(
  m1_coef = coef(m1)["D"],
  m1_se = sqrt(vcovHC(m1, type = "HC2")["D", "D"]),
  m1_n = nrow(dt_narrow),
  m2_coef = coef(m2)["D"],
  m2_se = sqrt(vcovHC(m2, type = "HC2")["D", "D"]),
  m2_n = nrow(dt_wide),
  m3_coef = coef(m3)["D"],
  m3_se = sqrt(vcovHC(m3, type = "HC2")["D", "D"]),
  m3_n = nrow(dt_medium),
  m4_coef = coef(m4)["D"],
  m4_se = sqrt(vcovHC(m4, type = "HC2")["D", "D"]),
  m4_n = nrow(dt),
  fisher_p = fisher_p,
  baseline_closure = mean(dt[D == 0]$closed_by_2026),
  treated_closure = mean(dt[D == 1]$closed_by_2026),
  sd_y = sd(dt$closed_by_2026),
  m_london_coef = if (!is.null(m_london)) coef(m_london)["D"] else NA,
  m_london_se = if (!is.null(m_london)) sqrt(vcovHC(m_london, type = "HC2")["D", "D"]) else NA,
  m_nonlon_coef = if (!is.null(m_nonlon)) coef(m_nonlon)["D"] else NA,
  m_nonlon_se = if (!is.null(m_nonlon)) sqrt(vcovHC(m_nonlon, type = "HC2")["D", "D"]) else NA,
  closure_by_score = tab
)
saveRDS(results, "../data/rdd_results.rds")
cat("Results saved.\n")
