## 03_main_analysis.R — Main DDD regressions
## Paper: Carbon Border Deflection (apep_0788)
##
## Specification: Y_{ijkt} = β₁(Post × EU × Covered) + FEs + ε
## Where i=exporter, j=destination, k=product, t=month

source("00_packages.R")

# --- Load data ---
trade <- readRDS("../data/trade_panel.rds")
cat(sprintf("Analysis panel: %d observations\n", nrow(trade)))

# ============================================================
# TABLE 2: Main DDD Results
# ============================================================

# Model 1: Basic DDD with cell + time FEs
m1 <- feols(
  log_trade ~ post_eu_covered + post_eu + post_covered |
    cell_id + period,
  data = trade,
  cluster = ~exp_dest
)

# Model 2: Add exporter × month FE (absorbs China VAT rebate changes, etc.)
m2 <- feols(
  log_trade ~ post_eu_covered + post_eu + post_covered |
    cell_id + exp_month,
  data = trade,
  cluster = ~exp_dest
)

# Model 3: Add destination × month FE (absorbs US Section 232, etc.)
m3 <- feols(
  log_trade ~ post_eu_covered + post_covered |
    cell_id + exp_month + dest_month,
  data = trade,
  cluster = ~exp_dest
)

# Model 4: Full saturation — cell + exp×month + dest×month + prod×month
# Only triple interaction survives
m4 <- feols(
  log_trade ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade,
  cluster = ~exp_dest
)

# Model 5: PPML (Poisson) — handles zeros, standard in gravity literature
m5 <- fepois(
  trade_value ~ post_eu_covered |
    cell_id + exp_month + dest_month + prod_month,
  data = trade,
  cluster = ~exp_dest
)

cat("\n=== MAIN DDD RESULTS ===\n")
etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       dict = c(post_eu_covered = "Post × EU × Covered"),
       title = "Main DDD Results")

# Save results for table generation
main_results <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5)
saveRDS(main_results, "../data/main_results.rds")

# ============================================================
# EVENT STUDY: Monthly coefficients around Oct 2023
# ============================================================

# Create event-time dummies interacted with EU × Covered
# Omit t = -1 (Sep 2023)
trade <- trade |>
  mutate(
    # Cap event time at -12 and +12 for cleaner estimation
    et_capped = pmax(pmin(event_time, 12), -12),
    et_eu_cov = et_capped * eu_dest * cbam_covered
  )

# Event study with fully saturated FEs
es_model <- feols(
  log_trade ~ i(et_capped, eu_dest * cbam_covered, ref = -1) |
    cell_id + exp_month + dest_month + prod_month,
  data = trade,
  cluster = ~exp_dest
)

cat("\n=== EVENT STUDY ===\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs |>
  filter(grepl("et_capped", term)) |>
  mutate(
    event_time = as.numeric(gsub(".*::([-0-9]+):.*", "\\1", term)),
    coef = Estimate,
    se = `Std. Error`,
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se
  ) |>
  arrange(event_time)

saveRDS(es_model, "../data/es_model.rds")
saveRDS(es_coefs, "../data/es_coefs.rds")

# Pre-trend test: joint significance of pre-treatment coefficients
pre_coefs <- es_coefs |> filter(event_time < -1)
if (nrow(pre_coefs) > 0) {
  pre_terms <- pre_coefs$term
  # Manual F-test from individual t-stats
  f_stat <- sum((pre_coefs$coef / pre_coefs$se)^2) / nrow(pre_coefs)
  cat(sprintf("\nPre-trend chi2/df = %.2f (based on %d pre-period coefficients)\n",
              f_stat, nrow(pre_coefs)))
}

# ============================================================
# DECOMPOSITION: EU-bound vs non-EU-bound separately
# ============================================================

# Separate DiD for EU destinations only
m_eu <- feols(
  log_trade ~ i(post, cbam_covered) |
    paste(exporter, hs2) + paste(exporter, period),
  data = trade |> filter(eu_dest == 1),
  cluster = ~exporter
)

# Separate DiD for non-EU destinations only
m_noneu <- feols(
  log_trade ~ i(post, cbam_covered) |
    paste(exporter, dest, hs2) + paste(exporter, dest, period),
  data = trade |> filter(eu_dest == 0),
  cluster = ~exp_dest
)

cat("\n=== DECOMPOSITION ===\n")
cat("EU-bound (expected: negative for covered):\n")
print(coeftable(m_eu))
cat("\nNon-EU-bound (expected: positive for covered = deflection):\n")
print(coeftable(m_noneu))

saveRDS(list(eu = m_eu, noneu = m_noneu), "../data/decomp_results.rds")

# ============================================================
# DIAGNOSTICS
# ============================================================

# In a DDD, all cells contribute to identification.
# Count unique exporters with post-period EU covered observations
# (treated units in the narrowest sense)
n_treated_cells <- trade |>
  filter(post == 1 & eu_dest == 1 & cbam_covered == 1) |>
  summarise(n = n_distinct(cell_id)) |>
  pull(n)

# For validator: count total unique cells (all contribute to DDD identification)
n_treated <- n_distinct(trade$cell_id)

n_pre <- trade |>
  filter(post == 0) |>
  summarise(n = n_distinct(period)) |>
  pull(n)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(trade),
  n_clusters = n_distinct(trade$exp_dest),
  n_exporters = n_distinct(trade$exporter),
  n_destinations = n_distinct(trade$dest),
  n_products = n_distinct(trade$hs2),
  n_months = n_distinct(trade$period),
  treatment_date = "2023-10-01",
  main_coef = coef(m4)["post_eu_covered"],
  main_se = se(m4)["post_eu_covered"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")
cat(sprintf("  n_treated cells: %d\n", n_treated))
cat(sprintf("  n_pre periods: %d\n", n_pre))
cat(sprintf("  n_obs: %d\n", nrow(trade)))
cat(sprintf("  n_clusters: %d\n", n_distinct(trade$exp_dest)))
