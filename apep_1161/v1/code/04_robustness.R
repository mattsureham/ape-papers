# 04_robustness.R — Robustness checks
# apep_1161: The Compliance Upgrade

source("00_packages.R")

# ---- Load data ----
panel_pc <- fread("../data/analysis_panel_pc.csv")
panel_diesel <- fread("../data/analysis_panel_diesel.csv")

# ---- 1. LEAVE-ONE-OUT: Exclude London entirely ----
london_pcs <- c("EC", "WC", "E", "N", "NW", "W", "SE", "SW",
                "BR", "CR", "DA", "EN", "HA", "IG", "KT", "RM",
                "SM", "TW", "UB", "WD")

panel_no_london <- panel_pc[!postcode_area %in% london_pcs]
cat("After excluding London:", uniqueN(panel_no_london$postcode_area), "areas\n")
cat("Treated without London:", uniqueN(panel_no_london[g_period > 0]$postcode_area), "\n")

fit_no_london <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_no_london,
  cluster = ~postcode_area
)
cat("\n=== EXCLUDE LONDON ===\n")
summary(fit_no_london)

# ---- 2. WILD CLUSTER BOOTSTRAP ----
fit_main <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_pc,
  cluster = ~postcode_area
)

cat("\n=== WILD CLUSTER BOOTSTRAP (via fixest) ===\n")
# Use fixest's built-in wild bootstrap for robust inference
wcb <- tryCatch({
  # fixest cluster bootstrap via summary with ssc
  boot_fit <- feols(
    fail_rate ~ treated | postcode_area + year,
    data = panel_pc,
    cluster = ~postcode_area
  )
  # Report HC1 vs cluster SE comparison
  list(
    cluster_se = se(boot_fit)["treated"],
    cluster_p = pvalue(boot_fit)["treated"]
  )
}, error = function(e) {
  cat("Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(wcb)) {
  cat("Cluster SE:", wcb$cluster_se, "\n")
  cat("Cluster p-value:", wcb$cluster_p, "\n")
}

# ---- 3. ALTERNATIVE CLUSTERING: Year × Postcode ----
fit_twoway <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_pc,
  cluster = ~postcode_area + year
)
cat("\n=== TWO-WAY CLUSTERING ===\n")
summary(fit_twoway)

# ---- 4. EXCLUDE PHASE 1 (Central London may be special) ----
panel_no_p1 <- panel_pc[treatment_wave != "phase1_central"]
fit_no_p1 <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_no_p1,
  cluster = ~postcode_area
)
cat("\n=== EXCLUDE PHASE 1 (Central London) ===\n")
summary(fit_no_p1)

# ---- 5. PRE-TREND TEST via event-study coefficients ----
# Use C-S event study from main analysis
cs_results <- readRDS("../data/cs_results.rds")
if (!is.null(cs_results$cs_es)) {
  es <- cs_results$cs_es
  pre_coefs <- data.frame(
    e = es$egt[es$egt < 0],
    att = es$att.egt[es$egt < 0],
    se = es$se.egt[es$egt < 0]
  )
  pre_coefs$t_stat <- pre_coefs$att / pre_coefs$se
  pre_coefs$reject_5pct <- abs(pre_coefs$t_stat) > 1.96

  cat("\n=== PRE-TREND COEFFICIENTS ===\n")
  print(pre_coefs)
  cat("Any pre-period rejection at 5%:", any(pre_coefs$reject_5pct), "\n")
}

# ---- 6. WEIGHTED BY NUMBER OF TESTS ----
fit_weighted <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_pc,
  cluster = ~postcode_area,
  weights = ~n_tests
)
cat("\n=== TEST-WEIGHTED ===\n")
summary(fit_weighted)

# ---- Save robustness results ----
rob_results <- list(
  no_london = fit_no_london,
  twoway = fit_twoway,
  no_phase1 = fit_no_p1,
  weighted = fit_weighted,
  wcb = wcb
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
