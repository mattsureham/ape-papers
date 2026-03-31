# 03_main_analysis.R — IV estimation: Queue congestion → investigation duration → injuries
# apep_1192: Defect Queue Congestion

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_investigations.csv"))

cat(sprintf("Analysis sample: %d investigations\n", nrow(df)))

# ============================================================
# 1. Summary Statistics
# ============================================================
cat("\n=== Key Variables ===\n")

vars_summ <- df[, .(
  Duration_days = duration_days,
  Log_duration = log_duration,
  Concurrent_all = concurrent_all,
  Concurrent_other_mfr = concurrent_other_mfr,
  Has_recall = as.numeric(has_recall),
  Complaints_pre = comp_pre,
  Injuries_during = injuries_during,
  Deaths_during = deaths_during,
  Severity_pre = severity_pre,
  N_models = n_models
)]

summ_stats <- data.table(
  Variable = names(vars_summ),
  Mean = sapply(vars_summ, mean, na.rm = TRUE),
  SD = sapply(vars_summ, sd, na.rm = TRUE),
  Min = sapply(vars_summ, min, na.rm = TRUE),
  Median = sapply(vars_summ, median, na.rm = TRUE),
  Max = sapply(vars_summ, max, na.rm = TRUE),
  N = sapply(vars_summ, function(x) sum(!is.na(x)))
)
print(summ_stats)

# Save summary stats
fwrite(summ_stats, file.path(data_dir, "summary_stats.csv"))

# ============================================================
# 2. OLS: Concurrent investigations → Duration
# ============================================================
cat("\n=== OLS Regressions ===\n")

# (1) Bivariate
ols1 <- feols(log_duration ~ concurrent_all, data = df, vcov = "hetero")

# (2) + controls
ols2 <- feols(log_duration ~ concurrent_all + comp_pre + severity_pre +
                n_models + mfr_inv_count | comp_cat,
              data = df, vcov = "hetero")

# (3) + year-quarter FE
ols3 <- feols(log_duration ~ concurrent_all + comp_pre + severity_pre +
                n_models + mfr_inv_count | comp_cat + open_yq,
              data = df, vcov = "hetero")

# (4) + manufacturer FE
ols4 <- feols(log_duration ~ concurrent_all + comp_pre + severity_pre +
                n_models | comp_cat + open_yq + mfr_clean,
              data = df, vcov = "hetero")

cat("OLS Results:\n")
etable(ols1, ols2, ols3, ols4, se = "hetero")

# ============================================================
# 3. IV: Other-manufacturer queue → Duration
# ============================================================
cat("\n=== IV (2SLS) Regressions ===\n")

# First stage: concurrent_other_mfr → concurrent_all
fs1 <- feols(concurrent_all ~ concurrent_other_mfr + comp_pre + severity_pre +
               n_models + mfr_inv_count | comp_cat + open_yq,
             data = df, vcov = "hetero")
cat(sprintf("First stage F-stat: %.1f\n", fitstat(fs1, "f")$f$stat))

# IV: instrument with other-mfr queue
iv1 <- feols(log_duration ~ comp_pre + severity_pre + n_models + mfr_inv_count |
               comp_cat + open_yq |
               concurrent_all ~ concurrent_other_mfr,
             data = df, vcov = "hetero")

# IV with manufacturer FE
iv2 <- feols(log_duration ~ comp_pre + severity_pre + n_models |
               comp_cat + open_yq + mfr_clean |
               concurrent_all ~ concurrent_other_mfr,
             data = df, vcov = "hetero")

# IV clustered by manufacturer
iv3 <- feols(log_duration ~ comp_pre + severity_pre + n_models + mfr_inv_count |
               comp_cat + open_yq |
               concurrent_all ~ concurrent_other_mfr,
             data = df, vcov = ~mfr_clean)

cat("\nIV Results:\n")
etable(iv1, iv2, iv3)

# ============================================================
# 4. IV: Duration → Injuries (second stage of full model)
# ============================================================
cat("\n=== Injury Cost of Delay ===\n")

# Subset to investigations with recall (where delay matters most)
df_recall <- df[has_recall == TRUE]
cat(sprintf("Recall subsample: %d investigations\n", nrow(df_recall)))

# OLS: duration → injuries during investigation
inj_ols <- feols(injuries_during ~ log_duration + comp_pre + severity_pre +
                   n_models + mfr_inv_count | comp_cat + open_yq,
                 data = df_recall, vcov = "hetero")

# IV: instrument duration with other-mfr queue
inj_iv <- feols(injuries_during ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                  comp_cat + open_yq |
                  log_duration ~ concurrent_other_mfr,
                data = df_recall, vcov = "hetero")

# Deaths outcome
death_ols <- feols(deaths_during ~ log_duration + comp_pre + severity_pre +
                     n_models + mfr_inv_count | comp_cat + open_yq,
                   data = df_recall, vcov = "hetero")

death_iv <- feols(deaths_during ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                    comp_cat + open_yq |
                    log_duration ~ concurrent_other_mfr,
                  data = df_recall, vcov = "hetero")

cat("Injury Results:\n")
etable(inj_ols, inj_iv, death_ols, death_iv)

# ============================================================
# 5. Recall probability: Does congestion affect whether a recall happens?
# ============================================================
cat("\n=== Recall Probability ===\n")

recall_ols <- feols(has_recall ~ concurrent_all + comp_pre + severity_pre +
                      n_models + mfr_inv_count | comp_cat + open_yq,
                    data = df, vcov = "hetero")

recall_iv <- feols(has_recall ~ comp_pre + severity_pre + n_models + mfr_inv_count |
                     comp_cat + open_yq |
                     concurrent_all ~ concurrent_other_mfr,
                   data = df, vcov = "hetero")

cat("Recall Probability Results:\n")
etable(recall_ols, recall_iv)

# ============================================================
# 6. Save key results for diagnostics.json
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diag <- list(
  n_treated = uniqueN(df$mfr_clean),
  n_pre = length(unique(df$open_yq[df$open_year < 2012])),
  n_obs = nrow(df),
  n_investigations = nrow(df),
  n_pe = sum(df$inv_type == "PE"),
  n_ea = sum(df$inv_type == "EA"),
  n_recall = sum(df$has_recall),
  n_manufacturers = uniqueN(df$mfr_clean),
  first_stage_f = fitstat(fs1, "f")$f$stat,
  iv_coef = coef(iv1)["fit_concurrent_all"],
  iv_se = se(iv1)["fit_concurrent_all"],
  ols_coef = coef(ols3)["concurrent_all"],
  ols_se = se(ols3)["concurrent_all"],
  mean_duration = mean(df$duration_days),
  mean_concurrent = mean(df$concurrent_all),
  sd_concurrent = sd(df$concurrent_all)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

# Save model objects for table generation
save(ols1, ols2, ols3, ols4, iv1, iv2, iv3, fs1,
     inj_ols, inj_iv, death_ols, death_iv,
     recall_ols, recall_iv, summ_stats,
     file = file.path(data_dir, "models.RData"))

cat("\nMain analysis complete.\n")
