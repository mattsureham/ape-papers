# 04_robustness.R — Alternative specifications, reduced form, robustness
# apep_1192: Defect Queue Congestion

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_investigations.csv"))

# ============================================================
# 1. Year FE instead of Year-Quarter FE (stronger first stage)
# ============================================================
cat("=== Year FE Specifications ===\n")

# First stage with year FE
fs_year <- feols(concurrent_all ~ concurrent_other_mfr + comp_pre + severity_pre +
                   n_models + mfr_inv_count | comp_cat + open_year,
                 data = df, vcov = "hetero")
cat(sprintf("First stage F (year FE): %.1f\n", fitstat(fs_year, "f")$f$stat))

# IV with year FE
iv_year <- feols(log_duration ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                   comp_cat + open_year |
                   concurrent_all ~ concurrent_other_mfr,
                 data = df, vcov = "hetero")

# Recall probability with year FE
recall_year <- feols(has_recall ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                       comp_cat + open_year |
                       concurrent_all ~ concurrent_other_mfr,
                     data = df, vcov = "hetero")

cat("IV (year FE) results:\n")
etable(iv_year, recall_year)

# ============================================================
# 2. Reduced Form: Other-mfr queue → outcomes directly
# ============================================================
cat("\n=== Reduced Form ===\n")

rf_duration <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                       n_models + mfr_inv_count | comp_cat + open_year,
                     data = df, vcov = "hetero")

rf_recall <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = "hetero")

rf_duration_yq <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                          n_models + mfr_inv_count | comp_cat + open_yq,
                        data = df, vcov = "hetero")

rf_recall_yq <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                        n_models + mfr_inv_count | comp_cat + open_yq,
                      data = df, vcov = "hetero")

cat("Reduced form results:\n")
etable(rf_duration, rf_recall, rf_duration_yq, rf_recall_yq)

# ============================================================
# 3. Heterogeneity: PE vs EA investigations
# ============================================================
cat("\n=== Heterogeneity by Investigation Type ===\n")

df_pe <- df[inv_type == "PE"]
df_ea <- df[inv_type == "EA"]

rf_pe <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                 n_models + mfr_inv_count | comp_cat + open_year,
               data = df_pe, vcov = "hetero")

rf_ea <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                 n_models + mfr_inv_count | comp_cat + open_year,
               data = df_ea, vcov = "hetero")

recall_pe <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df_pe, vcov = "hetero")

recall_ea <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df_ea, vcov = "hetero")

cat("PE investigations:\n")
etable(rf_pe, recall_pe)
cat("EA investigations:\n")
etable(rf_ea, recall_ea)

# ============================================================
# 4. Placebo: Queue should NOT affect investigations of severe defects
# ============================================================
cat("\n=== Placebo: High-severity investigations ===\n")

# High severity = top quartile of pre-period severity score
sev_q75 <- quantile(df$severity_pre, 0.75)
df_high_sev <- df[severity_pre >= sev_q75]
df_low_sev <- df[severity_pre < sev_q75]

placebo_high <- feols(log_duration ~ concurrent_other_mfr + comp_pre +
                        n_models + mfr_inv_count | comp_cat + open_year,
                      data = df_high_sev, vcov = "hetero")

placebo_low <- feols(log_duration ~ concurrent_other_mfr + comp_pre +
                       n_models + mfr_inv_count | comp_cat + open_year,
                     data = df_low_sev, vcov = "hetero")

recall_high <- feols(has_recall ~ concurrent_other_mfr + comp_pre +
                       n_models + mfr_inv_count | comp_cat + open_year,
                     data = df_high_sev, vcov = "hetero")

recall_low <- feols(has_recall ~ concurrent_other_mfr + comp_pre +
                      n_models + mfr_inv_count | comp_cat + open_year,
                    data = df_low_sev, vcov = "hetero")

cat("High severity (placebo — should be weaker):\n")
etable(placebo_high, recall_high)
cat("Low severity (main effect — should be stronger):\n")
etable(placebo_low, recall_low)

# ============================================================
# 5. Leave-one-out: Drop major manufacturers one at a time
# ============================================================
cat("\n=== Leave-One-Out Manufacturer Robustness ===\n")

major_mfrs <- c("FORD", "GENERAL MOTORS", "CHRYSLER/STELLANTIS", "TOYOTA",
                "HONDA", "NISSAN", "HYUNDAI/KIA", "TESLA")

loo_results <- data.table(
  mfr_dropped = character(),
  n = integer(),
  rf_coef = numeric(),
  rf_se = numeric(),
  recall_coef = numeric(),
  recall_se = numeric()
)

for (mfr in major_mfrs) {
  df_loo <- df[mfr_clean != mfr]
  m_rf <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                  n_models + mfr_inv_count | comp_cat + open_year,
                data = df_loo, vcov = "hetero")
  m_rec <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                   n_models + mfr_inv_count | comp_cat + open_year,
                 data = df_loo, vcov = "hetero")

  loo_results <- rbindlist(list(loo_results, data.table(
    mfr_dropped = mfr, n = nrow(df_loo),
    rf_coef = coef(m_rf)["concurrent_other_mfr"],
    rf_se = se(m_rf)["concurrent_other_mfr"],
    recall_coef = coef(m_rec)["concurrent_other_mfr"],
    recall_se = se(m_rec)["concurrent_other_mfr"]
  )))
}

cat("Leave-one-out results:\n")
print(loo_results)

# ============================================================
# 6. Alternative clustering: year-quarter, two-way
# ============================================================
cat("\n=== Alternative Clustering ===\n")

rf_cl_mfr <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_year,
                   data = df, vcov = ~mfr_clean)

rf_cl_yq <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                    n_models + mfr_inv_count | comp_cat + open_year,
                  data = df, vcov = ~open_yq)

rf_cl_twoway <- feols(log_duration ~ concurrent_other_mfr + comp_pre + severity_pre +
                        n_models + mfr_inv_count | comp_cat + open_year,
                      data = df, vcov = ~mfr_clean + open_yq)

recall_cl_mfr <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                         n_models + mfr_inv_count | comp_cat + open_year,
                       data = df, vcov = ~mfr_clean)

recall_cl_yq <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                        n_models + mfr_inv_count | comp_cat + open_year,
                      data = df, vcov = ~open_yq)

recall_cl_twoway <- feols(has_recall ~ concurrent_other_mfr + comp_pre + severity_pre +
                            n_models + mfr_inv_count | comp_cat + open_year,
                          data = df, vcov = ~mfr_clean + open_yq)

cat("Duration (alternative clustering):\n")
etable(rf_cl_mfr, rf_cl_yq, rf_cl_twoway)
cat("Recall probability (alternative clustering):\n")
etable(recall_cl_mfr, recall_cl_yq, recall_cl_twoway)

# ============================================================
# 7. Save all robustness objects
# ============================================================
save(fs_year, iv_year, recall_year,
     rf_duration, rf_recall, rf_duration_yq, rf_recall_yq,
     rf_pe, rf_ea, recall_pe, recall_ea,
     placebo_high, placebo_low, recall_high, recall_low,
     loo_results,
     rf_cl_mfr, rf_cl_yq, rf_cl_twoway,
     recall_cl_mfr, recall_cl_yq, recall_cl_twoway,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness analysis complete.\n")
