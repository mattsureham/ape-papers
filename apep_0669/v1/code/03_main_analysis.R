## 03_main_analysis.R — Diff-in-disc estimation
## APEP Paper apep_0669: Capitalization of Reproductive Rights

source("00_packages.R")

cat("=== Main Analysis ===\n")

stl_panel <- readRDS("../data/stl_panel.rds")

# ----------------------------------------------------------------
# 1. Summary statistics
# ----------------------------------------------------------------
cat("--- Summary Statistics ---\n")

summ_stats <- stl_panel %>%
  filter(pre_dobbs == 1 | post_dobbs == 1) %>%
  group_by(ban_state) %>%
  summarise(
    n_zips = n_distinct(zip),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
    sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
    median_zhvi = median(zhvi, na.rm = TRUE),
    mean_dist_km = mean(dist_km, na.rm = TRUE),
    .groups = "drop"
  )

print(summ_stats)

# Full sample SD for SDE computation
sd_log_zhvi_full <- sd(stl_panel$log_zhvi, na.rm = TRUE)
sd_zhvi_full <- sd(stl_panel$zhvi, na.rm = TRUE)
cat("  Full sample SD(log ZHVI):", round(sd_log_zhvi_full, 4), "\n")
cat("  Full sample SD(ZHVI):", round(sd_zhvi_full, 0), "\n")

# ----------------------------------------------------------------
# 2. Main Diff-in-Disc: Panel specification
# ----------------------------------------------------------------
cat("\n--- Panel Diff-in-Disc ---\n")

# Exclude June 2022 (transition month)
analysis_df <- stl_panel %>%
  filter(pre_dobbs == 1 | post_dobbs == 1)

cat("  Analysis observations:", nrow(analysis_df), "\n")
cat("  Treated (MO) ZIPs:", n_distinct(analysis_df$zip[analysis_df$ban_state == 1]), "\n")
cat("  Control (IL) ZIPs:", n_distinct(analysis_df$zip[analysis_df$ban_state == 0]), "\n")

# Model 1: Basic DiD (no distance controls)
m1 <- feols(log_zhvi ~ treat_post | zip + ym, data = analysis_df,
            cluster = ~zip)

cat("\nModel 1: Basic DiD\n")
print(summary(m1))

# Model 2: DiD with linear distance × post
m2 <- feols(log_zhvi ~ treat_post + signed_dist:post_dobbs |
              zip + ym, data = analysis_df,
            cluster = ~zip)

cat("\nModel 2: DiD + linear distance × post\n")
print(summary(m2))

# Model 3: DiD with quadratic distance × post
m3 <- feols(log_zhvi ~ treat_post +
              signed_dist:post_dobbs + I(signed_dist^2):post_dobbs |
              zip + ym, data = analysis_df,
            cluster = ~zip)

cat("\nModel 3: DiD + quadratic distance × post\n")
print(summary(m3))

# Model 4: Bandwidth restriction (within 30km of border)
m4 <- feols(log_zhvi ~ treat_post + signed_dist:post_dobbs |
              zip + ym,
            data = analysis_df %>% filter(dist_km <= 30),
            cluster = ~zip)

cat("\nModel 4: 30km bandwidth + linear distance × post\n")
print(summary(m4))

# Model 5: Bandwidth restriction (within 15km of border)
m5 <- feols(log_zhvi ~ treat_post + signed_dist:post_dobbs |
              zip + ym,
            data = analysis_df %>% filter(dist_km <= 15),
            cluster = ~zip)

cat("\nModel 5: 15km bandwidth + linear distance × post\n")
print(summary(m5))

# ----------------------------------------------------------------
# 3. Event Study
# ----------------------------------------------------------------
cat("\n--- Event Study ---\n")

# Create event-time dummies interacted with ban_state
# Omit event_month == -1 (May 2022, one month before Dobbs)
analysis_df <- analysis_df %>%
  mutate(event_month_factor = relevel(factor(event_month), ref = "-1"))

es_model <- feols(log_zhvi ~ i(event_month, ban_state, ref = -1) |
                    zip + ym,
                  data = analysis_df,
                  cluster = ~zip)

cat("\nEvent study model estimated\n")
print(summary(es_model))

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)

# Save event study results
saveRDS(es_model, "../data/es_model.rds")

# ----------------------------------------------------------------
# 4. Cross-sectional RDD (pre vs post)
# ----------------------------------------------------------------
cat("\n--- Cross-sectional RDD ---\n")

# Average ZHVI by ZIP in pre and post periods
zip_means <- analysis_df %>%
  group_by(zip, ban_state, signed_dist, dist_km) %>%
  summarise(
    zhvi_pre = mean(zhvi[pre_dobbs == 1], na.rm = TRUE),
    zhvi_post = mean(zhvi[post_dobbs == 1], na.rm = TRUE),
    log_zhvi_pre = mean(log_zhvi[pre_dobbs == 1], na.rm = TRUE),
    log_zhvi_post = mean(log_zhvi[post_dobbs == 1], na.rm = TRUE),
    n_pre = sum(pre_dobbs),
    n_post = sum(post_dobbs),
    .groups = "drop"
  ) %>%
  mutate(
    d_log_zhvi = log_zhvi_post - log_zhvi_pre,
    d_zhvi = zhvi_post - zhvi_pre,
    pct_change = (zhvi_post - zhvi_pre) / zhvi_pre * 100
  )

cat("  ZIPs with both pre/post:", nrow(zip_means), "\n")

# RDD on the change in log ZHVI
if (nrow(zip_means) >= 20) {
  rdd_result <- tryCatch({
    rdrobust(y = zip_means$d_log_zhvi,
             x = zip_means$signed_dist,
             c = 0,
             kernel = "triangular",
             bwselect = "mserd")
  }, error = function(e) {
    cat("  rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rdd_result)) {
    cat("\nRDD on change in log ZHVI:\n")
    print(summary(rdd_result))
    saveRDS(rdd_result, "../data/rdd_result.rds")
  }
}

# ----------------------------------------------------------------
# 5. Save main results
# ----------------------------------------------------------------
main_results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_model = es_model,
  summ_stats = summ_stats,
  sd_log_zhvi = sd_log_zhvi_full,
  sd_zhvi = sd_zhvi_full,
  n_treated = n_distinct(analysis_df$zip[analysis_df$ban_state == 1]),
  n_control = n_distinct(analysis_df$zip[analysis_df$ban_state == 0]),
  n_obs = nrow(analysis_df),
  n_pre = sum(analysis_df$pre_dobbs),
  n_post = sum(analysis_df$post_dobbs)
)

saveRDS(main_results, "../data/main_results.rds")

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = n_distinct(analysis_df$zip[analysis_df$ban_state == 1]),
  n_pre = length(unique(analysis_df$ym[analysis_df$pre_dobbs == 1])),
  n_obs = nrow(analysis_df)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("  N treated ZIPs:", diagnostics$n_treated, "\n")
cat("  N pre periods:", diagnostics$n_pre, "\n")
cat("  N observations:", diagnostics$n_obs, "\n")
