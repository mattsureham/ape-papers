## =============================================================================
## 03_main_analysis.R — apep_0590
## Callaway-Sant'Anna DiD: Effect of Sembrando Vida on Deforestation
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "clean_panel.csv"))
cat("Loaded clean panel:", nrow(panel), "rows\n")

# =============================================================================
# A) Treatment Rollout Visualization
# =============================================================================
cat("\n=== Treatment Timing ===\n")

rollout <- panel[, .(first_treat = first_treat[1]), by = GID_2]
cat("Rollout distribution:\n")
print(table(rollout$first_treat, useNA = "ifany"))

# Save for figures
fwrite(rollout, file.path(data_dir, "rollout_distribution.csv"))

# =============================================================================
# B) Cohort Average Outcomes (Pre-Modeling Diagnostic)
# =============================================================================
cat("\n=== Cohort Average Outcomes ===\n")

cohort_means <- panel[, .(
  mean_loss = mean(tree_cover_loss_ha, na.rm = TRUE),
  mean_log_loss = mean(log_loss, na.rm = TRUE),
  mean_asinh_loss = mean(asinh_loss, na.rm = TRUE),
  mean_loss_rate = mean(loss_rate, na.rm = TRUE),
  n_munis = uniqueN(GID_2)
), by = .(year, cohort = fifelse(first_treat == 0, "Never treated",
                                  paste0("Cohort ", first_treat)))]

fwrite(cohort_means, file.path(data_dir, "cohort_means.csv"))

# =============================================================================
# C) Callaway-Sant'Anna DiD — Primary Specification
# =============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Primary outcome: asinh(tree cover loss hectares)
# asinh handles zeros and is approximately log for large values
set.seed(20240310)
cs_result <- att_gt(
  yname = "asinh_loss",
  tname = "year",
  idname = "muni_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",  # Doubly-robust (default in did package)
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  pl = FALSE
)

cat("\nGroup-time ATTs computed.\n")
cat("Number of group-time estimates:", length(cs_result$att), "\n")

# Save raw results
saveRDS(cs_result, file.path(data_dir, "cs_result_asinh.rds"))

# =============================================================================
# D) Aggregate ATT
# =============================================================================
cat("\n=== Aggregate ATT ===\n")

# Overall ATT
agg_overall <- aggte(cs_result, type = "simple")
cat("Overall ATT (asinh):", round(agg_overall$overall.att, 4),
    "SE:", round(agg_overall$overall.se, 4), "\n")

# Dynamic (event study) aggregation
agg_dynamic <- aggte(cs_result, type = "dynamic",
                     min_e = -10, max_e = 5)

cat("\nEvent study estimates:\n")
es_df <- data.frame(
  event_time = agg_dynamic$egt,
  att = agg_dynamic$att.egt,
  se = agg_dynamic$se.egt,
  ci_lower = agg_dynamic$att.egt - 1.96 * agg_dynamic$se.egt,
  ci_upper = agg_dynamic$att.egt + 1.96 * agg_dynamic$se.egt
)
print(es_df)

# Save for figures
fwrite(es_df, file.path(data_dir, "event_study_asinh.csv"))

# Group-level aggregation
agg_group <- aggte(cs_result, type = "group")
cat("\nGroup-level ATTs:\n")
group_df <- data.frame(
  cohort = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt
)
print(group_df)
fwrite(group_df, file.path(data_dir, "group_att_asinh.csv"))

# Calendar-time aggregation
agg_calendar <- aggte(cs_result, type = "calendar")
cal_df <- data.frame(
  year = agg_calendar$egt,
  att = agg_calendar$att.egt,
  se = agg_calendar$se.egt
)
fwrite(cal_df, file.path(data_dir, "calendar_att_asinh.csv"))

# =============================================================================
# E) Alternative Outcome: Level (hectares)
# =============================================================================
cat("\n=== CS-DiD with level outcome ===\n")

set.seed(20240310)
cs_level <- att_gt(
  yname = "tree_cover_loss_ha",
  tname = "year",
  idname = "muni_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  pl = FALSE
)

saveRDS(cs_level, file.path(data_dir, "cs_result_level.rds"))

agg_level <- aggte(cs_level, type = "simple")
cat("Overall ATT (hectares):", round(agg_level$overall.att, 2),
    "SE:", round(agg_level$overall.se, 2), "\n")

agg_level_dyn <- aggte(cs_level, type = "dynamic", min_e = -10, max_e = 5)
es_level_df <- data.frame(
  event_time = agg_level_dyn$egt,
  att = agg_level_dyn$att.egt,
  se = agg_level_dyn$se.egt,
  ci_lower = agg_level_dyn$att.egt - 1.96 * agg_level_dyn$se.egt,
  ci_upper = agg_level_dyn$att.egt + 1.96 * agg_level_dyn$se.egt
)
fwrite(es_level_df, file.path(data_dir, "event_study_level.csv"))

# =============================================================================
# F) Alternative Outcome: Loss rate (per 1000 ha municipality area)
# =============================================================================
cat("\n=== CS-DiD with loss rate outcome ===\n")

set.seed(20240310)
cs_rate <- att_gt(
  yname = "loss_rate",
  tname = "year",
  idname = "muni_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  pl = FALSE
)

saveRDS(cs_rate, file.path(data_dir, "cs_result_rate.rds"))

agg_rate <- aggte(cs_rate, type = "simple")
cat("Overall ATT (loss rate):", round(agg_rate$overall.att, 4),
    "SE:", round(agg_rate$overall.se, 4), "\n")

agg_rate_dyn <- aggte(cs_rate, type = "dynamic", min_e = -10, max_e = 5)
es_rate_df <- data.frame(
  event_time = agg_rate_dyn$egt,
  att = agg_rate_dyn$att.egt,
  se = agg_rate_dyn$se.egt,
  ci_lower = agg_rate_dyn$att.egt - 1.96 * agg_rate_dyn$se.egt,
  ci_upper = agg_rate_dyn$att.egt + 1.96 * agg_rate_dyn$se.egt
)
fwrite(es_rate_df, file.path(data_dir, "event_study_rate.csv"))

# =============================================================================
# G) TWFE Comparison (for exposition — showing the problem)
# =============================================================================
cat("\n=== TWFE Comparison ===\n")

twfe <- feols(asinh_loss ~ treated | muni_id + year, data = panel,
              cluster = ~NAME_1)
cat("TWFE estimate:", round(coef(twfe)["treated"], 4),
    "SE:", round(se(twfe)["treated"], 4), "\n")

# Save TWFE for tables
twfe_out <- data.frame(
  estimator = "TWFE",
  estimate = coef(twfe)["treated"],
  se = se(twfe)["treated"],
  pvalue = fixest::pvalue(twfe)["treated"]
)
fwrite(twfe_out, file.path(data_dir, "twfe_comparison.csv"))

# =============================================================================
# H) Heterogeneity by Ecosystem Type
# =============================================================================
cat("\n=== Heterogeneity by Ecosystem ===\n")

eco_results <- list()
for (eco in unique(panel$ecosystem)) {
  sub <- panel[ecosystem == eco]
  if (uniqueN(sub[first_treat > 0, GID_2]) < 20) {
    cat("  Skipping", eco, "(too few treated units)\n")
    next
  }

  set.seed(20240310)
  cs_eco <- tryCatch({
    att_gt(
      yname = "asinh_loss",
      tname = "year",
      idname = "muni_id",
      gname = "first_treat",
      data = as.data.frame(sub),
      control_group = "nevertreated",
      est_method = "dr",
      bstrap = TRUE, biters = 500
    )
  }, error = function(e) {
    cat("  Error for", eco, ":", e$message, "\n")
    NULL
  })

  if (!is.null(cs_eco)) {
    agg_eco <- aggte(cs_eco, type = "simple")
    eco_results[[eco]] <- data.frame(
      ecosystem = eco,
      att = agg_eco$overall.att,
      se = agg_eco$overall.se,
      n_treated = uniqueN(sub[first_treat > 0, GID_2]),
      n_control = uniqueN(sub[first_treat == 0, GID_2])
    )
    cat("  ", eco, ": ATT =", round(agg_eco$overall.att, 4),
        "SE =", round(agg_eco$overall.se, 4), "\n")
  }
}

eco_df <- do.call(rbind, eco_results)
fwrite(eco_df, file.path(data_dir, "heterogeneity_ecosystem.csv"))

# =============================================================================
# I) Heterogeneity by Baseline Forest Cover
# =============================================================================
cat("\n=== Heterogeneity by Baseline Forest Cover ===\n")

# Split at median baseline forest share
median_forest <- median(panel[first_treat > 0, forest_share_2000[1]], na.rm = TRUE)
panel[, high_forest := forest_share_2000 >= median_forest]

forest_results <- list()
for (hf in c(TRUE, FALSE)) {
  label <- ifelse(hf, "High forest", "Low forest")
  sub <- panel[high_forest == hf]

  set.seed(20240310)
  cs_hf <- tryCatch({
    att_gt(
      yname = "asinh_loss",
      tname = "year",
      idname = "muni_id",
      gname = "first_treat",
      data = as.data.frame(sub),
      control_group = "nevertreated",
      est_method = "dr",
      bstrap = TRUE, biters = 500
    )
  }, error = function(e) {
    cat("  Error for", label, ":", e$message, "\n")
    NULL
  })

  if (!is.null(cs_hf)) {
    agg_hf <- aggte(cs_hf, type = "simple")
    forest_results[[label]] <- data.frame(
      subsample = label,
      att = agg_hf$overall.att,
      se = agg_hf$overall.se,
      n_treated = uniqueN(sub[first_treat > 0, GID_2]),
      n_control = uniqueN(sub[first_treat == 0, GID_2])
    )
    cat("  ", label, ": ATT =", round(agg_hf$overall.att, 4),
        "SE =", round(agg_hf$overall.se, 4), "\n")
  }
}

forest_df <- do.call(rbind, forest_results)
fwrite(forest_df, file.path(data_dir, "heterogeneity_forest_cover.csv"))

# =============================================================================
# Save All Main Results Summary
# =============================================================================

main_results <- data.frame(
  specification = c("CS-DiD asinh(loss)", "CS-DiD level (ha)",
                    "CS-DiD loss rate", "TWFE asinh(loss)"),
  estimate = c(agg_overall$overall.att, agg_level$overall.att,
               agg_rate$overall.att, coef(twfe)["treated"]),
  se = c(agg_overall$overall.se, agg_level$overall.se,
         agg_rate$overall.se, se(twfe)["treated"])
)
main_results$ci_lower <- main_results$estimate - 1.96 * main_results$se
main_results$ci_upper <- main_results$estimate + 1.96 * main_results$se
main_results$pvalue <- 2 * pnorm(-abs(main_results$estimate / main_results$se))

fwrite(main_results, file.path(data_dir, "main_results_summary.csv"))

cat("\nAll main analysis complete.\n")
cat("Results saved to data/ directory.\n")
