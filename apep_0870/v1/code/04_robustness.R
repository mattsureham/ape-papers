# 04_robustness.R — Robustness checks
# apep_0870: Upload Filter Tax

source("code/00_packages.R")

df <- fread("data/panel_csdid.csv")
load("data/cs_results.RData")

# ============================================================================
# 1. PRE-TRENDS TEST (from CS-DiD event study)
# ============================================================================

message("=== Pre-trends from CS-DiD Event Study ===")
es <- cs_event
pre_atts <- es$att.egt[es$egt < 0]
pre_ses  <- es$se.egt[es$egt < 0]
pre_periods <- es$egt[es$egt < 0]

message("Pre-treatment event study estimates:")
for (i in seq_along(pre_periods)) {
  message(sprintf("  t=%d: ATT=%.4f (SE=%.4f)", pre_periods[i], pre_atts[i], pre_ses[i]))
}

# Joint test: are all pre-treatment ATTs jointly zero?
# Using Wald test approximation
if (length(pre_atts) > 0) {
  wald_stat <- sum((pre_atts / pre_ses)^2)
  wald_df <- length(pre_atts)
  wald_p <- 1 - pchisq(wald_stat, df = wald_df)
  message(sprintf("\nJoint pre-trend Wald test: chi2(%d) = %.2f, p = %.4f",
                  wald_df, wald_stat, wald_p))
}

# ============================================================================
# 2. HONESTDID — Rambachan-Roth Sensitivity
# ============================================================================

message("\n=== HonestDiD Sensitivity Analysis ===")

tryCatch({
  honest_results <- HonestDiD::createSensitivityResults(
    betahat = es$att.egt,
    sigma = diag(es$se.egt^2),  # Variance matrix (diagonal approx)
    numPrePeriods = sum(es$egt < 0),
    numPostPeriods = sum(es$egt >= 0),
    Mvec = seq(0, 0.05, by = 0.01)
  )
  message("HonestDiD bounds computed:")
  print(honest_results)
  save(honest_results, file = "data/honest_did_results.RData")
}, error = function(e) {
  message("HonestDiD failed (non-fatal): ", e$message)
  message("Proceeding with other robustness checks.")
})

# ============================================================================
# 2b. TWFE WITH REGION-SPECIFIC LINEAR TRENDS
# ============================================================================

message("\n=== TWFE with Region-Specific Linear Trends ===")

df[, trend := year - 2015]
twfe_trends <- feols(
  log_emp_j ~ treated | geo + year + geo[trend],
  data = df,
  cluster = ~country
)
message("TWFE with region trends:")
print(summary(twfe_trends))
save(twfe_trends, file = "data/twfe_trends_results.RData")

# ============================================================================
# 3. LEAVE-ONE-COUNTRY-OUT
# ============================================================================

message("\n=== Leave-One-Country-Out ===")

countries <- unique(df[group > 0, country])
loo_results <- list()

for (ctry in countries) {
  df_loo <- df[country != ctry]
  # Re-ID for did package
  df_loo[, id_loo := as.integer(factor(geo))]

  tryCatch({
    cs_loo <- att_gt(
      yname = "log_emp_j", tname = "year", idname = "id_loo", gname = "group",
      data = as.data.frame(df_loo),
      control_group = "notyettreated",
      anticipation = 0, base_period = "universal",
      bstrap = TRUE, biters = 500
    )
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results[[ctry]] <- data.table(
      dropped = ctry, att = agg_loo$overall.att, se = agg_loo$overall.se
    )
    message(sprintf("  Drop %s: ATT = %.4f (SE = %.4f)", ctry, agg_loo$overall.att, agg_loo$overall.se))
  }, error = function(e) {
    message(sprintf("  Drop %s: FAILED (%s)", ctry, e$message))
  })
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, "data/leave_one_out.csv")
message("LOO results saved: ", nrow(loo_dt), " countries")

# ============================================================================
# 4. ALTERNATIVE TREATMENT: NEVER-TREATED AS CONTROL
# ============================================================================

message("\n=== CS-DiD with never-treated control group ===")

tryCatch({
  cs_never <- att_gt(
    yname = "log_emp_j", tname = "year", idname = "id", gname = "group",
    data = as.data.frame(df),
    control_group = "nevertreated",
    anticipation = 0, base_period = "universal",
    bstrap = TRUE, biters = 1000
  )
  cs_never_agg <- aggte(cs_never, type = "simple")
  message("ATT (never-treated control): ", round(cs_never_agg$overall.att, 4),
          " (SE: ", round(cs_never_agg$overall.se, 4), ")")
  save(cs_never, cs_never_agg, file = "data/cs_never_results.RData")
}, error = function(e) {
  message("Never-treated CS-DiD failed: ", e$message)
})

# ============================================================================
# 5. WILD CLUSTER BOOTSTRAP
# ============================================================================

message("\n=== Wild Cluster Bootstrap (TWFE) ===")

twfe_main <- feols(
  log_emp_j ~ treated | geo + year,
  data = df,
  cluster = ~country
)

# Wild cluster bootstrap p-value
tryCatch({
  wcb <- feols(
    log_emp_j ~ treated | geo + year,
    data = df,
    cluster = ~country,
    ssc = ssc(adj = TRUE, cluster.adj = TRUE)
  )
  # Use fwildclusterboot if available
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)
    boot_result <- boottest(
      wcb, param = "treated",
      B = 9999, clustid = "country", type = "webb"
    )
    message("Wild cluster bootstrap p-value: ", round(boot_result$p_val, 4))
    save(boot_result, file = "data/wcb_results.RData")
  } else {
    message("fwildclusterboot not installed — skipping WCB")
  }
}, error = function(e) {
  message("WCB failed (non-fatal): ", e$message)
})

# ============================================================================
# 6. PLACEBO: NACE K (Financial Services) — should show no effect
# ============================================================================

message("\n=== Placebo: NACE K (Financial Services) ===")

cs_placebo <- att_gt(
  yname = "log_emp_k", tname = "year", idname = "id", gname = "group",
  data = as.data.frame(df[!is.na(log_emp_k)]),
  control_group = "notyettreated",
  anticipation = 0, base_period = "universal",
  bstrap = TRUE, biters = 1000
)

cs_placebo_agg <- aggte(cs_placebo, type = "simple")
message("Placebo ATT (NACE K): ", round(cs_placebo_agg$overall.att, 4),
        " (SE: ", round(cs_placebo_agg$overall.se, 4), ")")

save(cs_placebo, cs_placebo_agg, file = "data/cs_placebo_results.RData")

message("\n=== All robustness checks complete ===")
