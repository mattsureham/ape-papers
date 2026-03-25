## 03_main_analysis.R — Main DiD regressions for EO 13771 paper
source("00_packages.R")

panel <- fread("../data/panel.csv")
matched <- fread("../data/matched_durations.csv")
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$agency_id), "agencies\n")

## ---- Summary statistics ----
pre <- panel[year < 2017]
during <- panel[year >= 2017 & year < 2021]
post <- panel[year >= 2021]

summary_stats <- rbind(
  data.table(period = "Pre-EO (2010-2016)",
             mean_nprm = mean(pre$n_nprm),
             sd_nprm = sd(pre$n_nprm),
             mean_rule = mean(pre$n_rule),
             sd_rule = sd(pre$n_rule),
             n_obs = nrow(pre)),
  data.table(period = "EO Active (2017-2020)",
             mean_nprm = mean(during$n_nprm),
             sd_nprm = sd(during$n_nprm),
             mean_rule = mean(during$n_rule),
             sd_rule = sd(during$n_rule),
             n_obs = nrow(during)),
  data.table(period = "Post-Rescission (2021-2024)",
             mean_nprm = mean(post$n_nprm),
             sd_nprm = sd(post$n_nprm),
             mean_rule = mean(post$n_rule),
             sd_rule = sd(post$n_rule),
             n_obs = nrow(post))
)
cat("\nSummary by period:\n")
print(summary_stats, digits = 3)

## ---- Main DiD specifications ----
# Outcome 1: NPRM volume (log)
m1 <- feols(log_nprm ~ post_eo_x_intensity + post_rescission_x_intensity |
              agency_id + yearmonth, data = panel, cluster = ~agency_id)

# Outcome 2: Final Rule volume (log)
m2 <- feols(log_rule ~ post_eo_x_intensity + post_rescission_x_intensity |
              agency_id + yearmonth, data = panel, cluster = ~agency_id)

# Outcome 3: Total rulemaking (log)
m3 <- feols(log_total ~ post_eo_x_intensity + post_rescission_x_intensity |
              agency_id + yearmonth, data = panel, cluster = ~agency_id)

# Outcome 4: NPRM-level duration (at the docket level, not aggregated)
# Restrict to NPRMs filed before 2021 (need post-period for final rules)
matched_pre21 <- matched[nprm_year <= 2020]
m4 <- feols(duration_days ~ post_eo_x_intensity + post_rescission_x_intensity |
              agency_id + nprm_year, data = matched_pre21, cluster = ~agency_id)

# Outcome 5: Rule-to-NPRM ratio (composition shift)
m5 <- feols(rule_nprm_ratio ~ post_eo_x_intensity + post_rescission_x_intensity |
              agency_id + yearmonth, data = panel, cluster = ~agency_id)

cat("\n=== Main Results ===\n")
cat("\n--- NPRM Volume (log) ---\n"); print(summary(m1))
cat("\n--- Final Rule Volume (log) ---\n"); print(summary(m2))
cat("\n--- Total Rulemaking (log) ---\n"); print(summary(m3))
cat("\n--- Duration (docket-level) ---\n"); print(summary(m4))
cat("\n--- Rule/NPRM Ratio ---\n"); print(summary(m5))

## ---- Ratchet test: β1 + β2 ----
ratchet_test <- function(m, label) {
  ct <- coeftable(m)
  nms <- rownames(ct)
  if (!all(c("post_eo_x_intensity", "post_rescission_x_intensity") %in% nms)) {
    cat(sprintf("  %s: collinear — cannot compute ratchet\n", label))
    return(list(sum = NA, se = NA, pval = NA))
  }
  b1 <- ct["post_eo_x_intensity", "Estimate"]
  b2 <- ct["post_rescission_x_intensity", "Estimate"]
  vcv <- vcov(m)
  sum_est <- b1 + b2
  var_sum <- vcv["post_eo_x_intensity", "post_eo_x_intensity"] +
             vcv["post_rescission_x_intensity", "post_rescission_x_intensity"] +
             2 * vcv["post_eo_x_intensity", "post_rescission_x_intensity"]
  se_sum <- sqrt(var_sum)
  tstat <- sum_est / se_sum
  # Use t-distribution with n_clusters - 1 df
  n_clust <- length(unique(m$fixef_id$agency_id))
  pval <- 2 * pt(abs(tstat), df = n_clust - 1, lower.tail = FALSE)
  cat(sprintf("  %s: β1=%.4f, β2=%.4f, β1+β2=%.4f (SE=%.4f), p=%.4f\n",
              label, b1, b2, sum_est, se_sum, pval))
  list(sum = sum_est, se = se_sum, pval = pval)
}

cat("\n=== Ratchet Tests ===\n")
r1 <- ratchet_test(m1, "NPRM")
r2 <- ratchet_test(m2, "Rule")
r3 <- ratchet_test(m3, "Total")
r5 <- ratchet_test(m5, "Ratio")

## ---- Save results ----
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  summary_stats = summary_stats,
  panel = panel, matched = matched_pre21
)
saveRDS(results, "../data/main_results.rds")

## ---- Write diagnostics.json ----
n_above_median <- uniqueN(panel[share_econ_sig > median(panel$share_econ_sig, na.rm = TRUE)]$agency_id)
diag <- list(
  n_treated = n_above_median,
  n_pre = uniqueN(panel[year < 2017]$yearmonth),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\ndiagnostics.json:", toJSON(diag, auto_unbox = TRUE), "\n")
