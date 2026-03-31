# ─────────────────────────────────────────────
# 04_robustness.R — Robustness checks
# ─────────────────────────────────────────────

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")

load(file.path(DATA_DIR, "main_results.RData"))

cat("Loaded main results.\n")
cat("Panel:", nrow(panel), "obs,", uniqueN(panel$muni_id), "municipalities\n")

# ─────────────────────────────────────────────
# 1. Never-treated control group (instead of not-yet-treated)
# ─────────────────────────────────────────────
cat("\n=== Robustness 1: Never-treated control group ===\n")
cs_never <- att_gt(
  yname = "hosp_rate_w",
  tname = "year",
  idname = "muni_id",
  gname = "treatment_year",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation = 1,
  est_method = "dr",
  base_period = "universal",
  clustervars = "muni_id",
  print_details = FALSE
)
agg_never <- aggte(cs_never, type = "simple")
cat(sprintf("ATT (never-treated controls): %.3f (SE: %.3f)\n",
            agg_never$overall.att, agg_never$overall.se))

# ─────────────────────────────────────────────
# 2. Corsan/RS subsample (2022 wave, post-COVID) — TWFE only
# ─────────────────────────────────────────────
cat("\n=== Robustness 2: Corsan/RS subsample (post-COVID) ===\n")
# Include only RS municipalities (treated) and SC municipalities (controls)
# CS not feasible because Corsan treatment=2023 is last year and anticipation=1
rs_panel <- panel[state_code %in% c("43", "42")]
rs_panel[, muni_id_rs := as.integer(factor(muni_code))]

twfe_corsan <- feols(hosp_rate_w ~ treated | muni_id_rs + year,
                     data = rs_panel, cluster = ~muni_id_rs)
cat("TWFE (Corsan/South subsample):\n")
print(summary(twfe_corsan))
# Store for tables
agg_corsan <- list(
  overall.att = coef(twfe_corsan)["treated"],
  overall.se = se(twfe_corsan)["treated"]
)

# ─────────────────────────────────────────────
# 3. Placebo outcome: non-waterborne hospitalizations
# ─────────────────────────────────────────────
cat("\n=== Robustness 3: Placebo outcome ===\n")
# Use total cost as an alternative outcome
twfe_cost <- feols(cost_per_cap ~ treated | muni_id + year,
                   data = panel, cluster = ~muni_id)
cat("TWFE on cost per capita:\n")
print(summary(twfe_cost))

# ─────────────────────────────────────────────
# 4. Different winsorization levels
# ─────────────────────────────────────────────
cat("\n=== Robustness 4: No winsorization ===\n")
twfe_raw <- feols(hosp_rate ~ treated | muni_id + year,
                  data = panel, cluster = ~muni_id)
cat("TWFE on unwinsorized hospitalization rate:\n")
print(summary(twfe_raw))

# ─────────────────────────────────────────────
# 5. Log outcome
# ─────────────────────────────────────────────
cat("\n=== Robustness 5: Log outcome ===\n")
panel[, log_hosp_rate := log(hosp_rate + 1)]
twfe_log <- feols(log_hosp_rate ~ treated | muni_id + year,
                  data = panel, cluster = ~muni_id)
cat("TWFE on log(hosp_rate + 1):\n")
print(summary(twfe_log))

# ─────────────────────────────────────────────
# 6. Excluding small municipalities (< 5000 pop)
# ─────────────────────────────────────────────
cat("\n=== Robustness 6: Excluding small municipalities ===\n")
large_panel <- panel[population >= 5000]
large_panel[, muni_id_large := as.integer(factor(muni_code))]
twfe_large <- feols(hosp_rate_w ~ treated | muni_id_large + year,
                    data = large_panel, cluster = ~muni_id_large)
cat(sprintf("TWFE excluding pop < 5000 (N = %d):\n", nrow(large_panel)))
print(summary(twfe_large))

# ─────────────────────────────────────────────
# 7. Pre-trend test (HonestDiD sensitivity)
# ─────────────────────────────────────────────
cat("\n=== Pre-trend Sensitivity (HonestDiD) ===\n")
tryCatch({
  agg_es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 3)

  # Extract pre-treatment coefficients and vcov
  pre_idx <- which(agg_es$egt < 0)
  post_idx <- which(agg_es$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    beta <- agg_es$att.egt
    sigma <- agg_es$V

    # Relative magnitudes approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD (relative magnitudes):\n")
    print(honest_rm)
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat(sprintf("HonestDiD error: %s\n", e$message))
})

# ─────────────────────────────────────────────
# Save robustness results
# ─────────────────────────────────────────────
save(agg_never, agg_corsan, twfe_corsan, twfe_cost, twfe_raw, twfe_log, twfe_large,
     file = file.path(DATA_DIR, "robustness_results.RData"))
cat("\nRobustness results saved.\n")
