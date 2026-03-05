## 04_robustness.R — Robustness checks
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# 1. Load data
# ===========================================================================
cat("=== Loading data ===\n")
main <- fread(file.path(data_dir, "main_sample.csv"))
placebo <- fread(file.path(data_dir, "placebo_sample.csv"))
het <- fread(file.path(data_dir, "het_sample.csv"))
balanced <- fread(file.path(data_dir, "balanced_panel.csv"))

main[, dep := substr(codgeo, 1, 2)]
placebo[, dep := substr(codgeo, 1, 2)]

# ===========================================================================
# 2. Placebo: Always-treated communes (should show no 2023 effect)
# ===========================================================================
cat("\n=== Placebo: Always-treated communes ===\n")

placebo[, placebo_treated := as.integer(group == "always_treated")]
placebo[, placebo_post := as.integer(year_q >= 2024)]
placebo[, placebo_tp := placebo_treated * placebo_post]

plac_vol <- feols(log_n_trans ~ placebo_tp | codgeo + quarter,
                  data = placebo, cluster = ~codgeo)
cat("Placebo (volume):\n")
summary(plac_vol)

plac_price <- feols(log_prix_m2 ~ placebo_tp | codgeo + quarter,
                    data = placebo[!is.na(log_prix_m2)], cluster = ~codgeo)
cat("\nPlacebo (price/m2):\n")
summary(plac_price)

# ===========================================================================
# 3. Exclude 2020 (COVID robustness)
# ===========================================================================
cat("\n=== COVID robustness: Exclude 2020 ===\n")

no2020 <- main[year_q >= 2021]
no2020_vol <- feols(log_n_trans ~ treat_post | codgeo + quarter,
                    data = no2020, cluster = ~codgeo)
cat("Excluding 2020 (volume):\n")
summary(no2020_vol)

no2020_price <- feols(log_prix_m2 ~ treat_post | codgeo + quarter,
                      data = no2020[!is.na(log_prix_m2)], cluster = ~codgeo)
cat("\nExcluding 2020 (price/m2):\n")
summary(no2020_price)

# ===========================================================================
# 4. Heterogeneity: Zone tendue vs. touristique
# ===========================================================================
cat("\n=== Heterogeneity: Zone type ===\n")

het[, zone_tendue := as.integer(zone_type == "tendue")]
het[, treat_post_tendue := treat_post * zone_tendue]
het[, treat_post_tourist := treat_post * (1 - zone_tendue)]

het_vol <- feols(log_n_trans ~ treat_post_tendue + treat_post_tourist | codgeo + quarter,
                 data = het[group %in% c("newly_treated_2023", "never_treated")],
                 cluster = ~codgeo)
cat("Heterogeneity by zone type (volume):\n")
summary(het_vol)

het_price <- feols(log_prix_m2 ~ treat_post_tendue + treat_post_tourist | codgeo + quarter,
                   data = het[group %in% c("newly_treated_2023", "never_treated") & !is.na(log_prix_m2)],
                   cluster = ~codgeo)
cat("\nHeterogeneity by zone type (price/m2):\n")
summary(het_price)

# ===========================================================================
# 5. Alternative treatment timing: Decree date (2023Q3)
# ===========================================================================
cat("\n=== Alternative timing: Decree date (2023Q3) ===\n")

main[, post_decree := as.integer(year_q >= 2023.5)]
main[, treat_decree := treated * post_decree]

alt_vol <- feols(log_n_trans ~ treat_decree | codgeo + quarter,
                 data = main, cluster = ~codgeo)
cat("Alternative timing (volume):\n")
summary(alt_vol)

alt_price <- feols(log_prix_m2 ~ treat_decree | codgeo + quarter,
                   data = main[!is.na(log_prix_m2)], cluster = ~codgeo)
cat("\nAlternative timing (price/m2):\n")
summary(alt_price)

# ===========================================================================
# 6. Department-level clustering (conservative)
# ===========================================================================
cat("\n=== Conservative clustering: Department ===\n")

dep_vol <- feols(log_n_trans ~ treat_post | codgeo + quarter,
                 data = main, cluster = ~dep)
cat("Department clustering (volume):\n")
summary(dep_vol)

dep_price <- feols(log_prix_m2 ~ treat_post | codgeo + quarter,
                   data = main[!is.na(log_prix_m2)], cluster = ~dep)
cat("\nDepartment clustering (price/m2):\n")
summary(dep_price)

# ===========================================================================
# 7. Pre-trend F-test
# ===========================================================================
cat("\n=== Pre-trend F-test ===\n")

main[, rel_time_binned := pmax(pmin(rel_time, 6), -8)]
es_vol <- feols(log_n_trans ~ i(rel_time_binned, treated, ref = -1) | codgeo + quarter,
                data = main, cluster = ~codgeo)

# Test joint significance of pre-treatment leads
pre_coefs <- grep("rel_time_binned::-[2-8]", names(coef(es_vol)), value = TRUE)
if (length(pre_coefs) > 0) {
  pre_test <- wald(es_vol, pre_coefs)
  cat("Joint F-test on pre-treatment leads:\n")
  print(pre_test)
}

# ===========================================================================
# 8. Callaway-Sant'Anna estimator (if did package available)
# ===========================================================================
cat("\n=== Callaway-Sant'Anna ===\n")

tryCatch({
  # Create cohort variable: treatment timing
  cs_data <- main[group %in% c("newly_treated_2023", "never_treated")]
  # Treatment period: first post-treatment quarter
  tp <- cs_data[quarter == "2024Q1", unique(time_period)]
  cs_data[, G := fifelse(treated == 1, tp, 0)]  # cohort: treatment period or never-treated (0)
  cs_data[, id := as.integer(factor(codgeo))]

  cs_out <- att_gt(
    yname = "log_n_trans",
    tname = "time_period",
    idname = "id",
    gname = "G",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )

  cat("CS ATT(g,t) results:\n")
  summary(cs_out)

  # Aggregate to simple ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS aggregate ATT:\n")
  summary(cs_agg)

  # Dynamic aggregation
  cs_dyn <- aggte(cs_out, type = "dynamic")
  cat("\nCS dynamic aggregation:\n")
  summary(cs_dyn)

  # Save CS event study coefficients
  cs_es_df <- data.table(
    rel_time = cs_dyn$egt,
    estimate = cs_dyn$att.egt,
    se = cs_dyn$se.egt,
    ci_lower = cs_dyn$att.egt - 1.96 * cs_dyn$se.egt,
    ci_upper = cs_dyn$att.egt + 1.96 * cs_dyn$se.egt,
    outcome = "CS_log_transactions"
  )
  fwrite(cs_es_df, file.path(data_dir, "cs_event_study_coefs.csv"))

  saveRDS(list(cs_out = cs_out, cs_agg = cs_agg, cs_dyn = cs_dyn),
          file.path(data_dir, "cs_results.rds"))
}, error = function(e) {
  cat("CS estimation failed:", e$message, "\n")
  cat("Proceeding without CS results.\n")
})

# ===========================================================================
# 9. Randomization Inference
# ===========================================================================
cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_ri <- 500
ri_coefs <- numeric(n_ri)

# Get actual coefficient
actual_coef <- coef(feols(log_n_trans ~ treat_post | codgeo + quarter,
                          data = main, cluster = ~codgeo))["treat_post"]

# Randomize treatment assignment across communes
commune_ids <- unique(main[, .(codgeo, treated)])
n_treated <- sum(commune_ids$treated)

for (i in seq_len(n_ri)) {
  if (i %% 100 == 0) cat(sprintf("  RI iteration %d/%d\n", i, n_ri))
  perm <- copy(main)
  # Randomly assign treatment to same number of communes
  perm_communes <- copy(commune_ids)
  perm_communes[, treated_ri := 0L]
  perm_communes[sample(.N, n_treated), treated_ri := 1L]
  perm <- merge(perm, perm_communes[, .(codgeo, treated_ri)], by = "codgeo")
  perm[, treat_post_ri := treated_ri * post]

  ri_mod <- feols(log_n_trans ~ treat_post_ri | codgeo + quarter,
                  data = perm, cluster = ~codgeo)
  ri_coefs[i] <- coef(ri_mod)["treat_post_ri"]
}

ri_pval <- mean(abs(ri_coefs) >= abs(actual_coef))
cat(sprintf("RI p-value (two-sided, %d permutations): %.4f\n", n_ri, ri_pval))
cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("RI distribution: mean=%.4f, sd=%.4f\n", mean(ri_coefs), sd(ri_coefs)))

fwrite(data.table(ri_coefs = ri_coefs), file.path(data_dir, "ri_distribution.csv"))
fwrite(data.table(actual_coef = actual_coef, ri_pval = ri_pval, n_perms = n_ri),
       file.path(data_dir, "ri_summary.csv"))

# ===========================================================================
# 10. Save all robustness results
# ===========================================================================
cat("\n=== Saving robustness results ===\n")

rob_summary <- data.table(
  test = c("Placebo (volume)", "Placebo (price)",
           "No 2020 (volume)", "No 2020 (price)",
           "Zone tendue (volume)", "Zone touristique (volume)",
           "Zone tendue (price)", "Zone touristique (price)",
           "Alt timing decree (volume)", "Alt timing decree (price)",
           "Dept cluster (volume)", "Dept cluster (price)"),
  coef = c(coef(plac_vol)["placebo_tp"], coef(plac_price)["placebo_tp"],
           coef(no2020_vol)["treat_post"], coef(no2020_price)["treat_post"],
           coef(het_vol)["treat_post_tendue"], coef(het_vol)["treat_post_tourist"],
           coef(het_price)["treat_post_tendue"], coef(het_price)["treat_post_tourist"],
           coef(alt_vol)["treat_decree"], coef(alt_price)["treat_decree"],
           coef(dep_vol)["treat_post"], coef(dep_price)["treat_post"]),
  se = c(se(plac_vol)["placebo_tp"], se(plac_price)["placebo_tp"],
         se(no2020_vol)["treat_post"], se(no2020_price)["treat_post"],
         se(het_vol)["treat_post_tendue"], se(het_vol)["treat_post_tourist"],
         se(het_price)["treat_post_tendue"], se(het_price)["treat_post_tourist"],
         se(alt_vol)["treat_decree"], se(alt_price)["treat_decree"],
         se(dep_vol)["treat_post"], se(dep_price)["treat_post"])
)
rob_summary[, pval := 2 * pnorm(-abs(coef / se))]

fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))
cat("Robustness summary:\n")
print(rob_summary)

cat("\nDone.\n")
