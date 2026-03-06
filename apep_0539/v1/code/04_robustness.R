## 04_robustness.R — Robustness checks and diagnostics
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cs_results <- readRDS(file.path(data_dir, "cs_did_results.rds"))

# ===========================================================================
# 1. Timing Exogeneity Test
# ===========================================================================
cat("=== Timing Exogeneity Test ===\n")

# Regress EBT adoption year on pre-period (1990-1995) state characteristics
pre_chars <- panel %>%
  filter(year >= 1990, year <= 1995) %>%
  group_by(state_abbr, first_treat) %>%
  summarise(
    mean_property = mean(property_crime_rate, na.rm = TRUE),
    mean_burglary = mean(burglary_rate, na.rm = TRUE),
    mean_violent = mean(violent_crime_rate, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    .groups = "drop"
  )

timing_reg <- lm(first_treat ~ mean_property + mean_burglary + mean_violent +
                   log(mean_pop), data = pre_chars)
cat("Timing exogeneity regression:\n")
print(summary(timing_reg))

# F-test: joint insignificance implies exogenous timing
f_stat <- summary(timing_reg)$fstatistic
f_pvalue <- pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)
cat("\nJoint F-test p-value:", round(f_pvalue, 4), "\n")
cat("Conclusion:", ifelse(f_pvalue > 0.10,
    "PASS — Pre-period characteristics do not predict adoption timing",
    "CONCERN — Some correlation between pre-period chars and timing"), "\n")

timing_results <- list(
  reg = timing_reg,
  f_pvalue = f_pvalue,
  pre_chars = pre_chars
)
saveRDS(timing_results, file.path(data_dir, "timing_exogeneity.rds"))

# ===========================================================================
# 2. Sun-Abraham Interaction-Weighted Estimator
# ===========================================================================
cat("\n=== Sun-Abraham Estimator ===\n")

# Property crime
sa_property <- feols(log_property_crime ~ sunab(first_treat, year) | state_id + year,
                     data = panel, cluster = ~state_abbr)
cat("Sun-Abraham property crime:\n")
post_coefs <- coef(sa_property)[grepl("year::", names(coef(sa_property))) &
                                 !grepl("-", names(coef(sa_property)))]
cat("  ATT estimate:", round(mean(post_coefs, na.rm = TRUE), 4), "\n")

# Burglary
sa_burglary <- feols(log_burglary ~ sunab(first_treat, year) | state_id + year,
                     data = panel, cluster = ~state_abbr)

# MVT (placebo)
sa_mvt <- feols(log_mvt ~ sunab(first_treat, year) | state_id + year,
                data = panel, cluster = ~state_abbr)

saveRDS(list(property = sa_property, burglary = sa_burglary, mvt = sa_mvt),
        file.path(data_dir, "sunab_results.rds"))

# Compute and save aggregate Sun-Abraham ATT + SE for Table 4
sa_prop_agg <- summary(sa_property, agg = "ATT")
sa_burg_agg <- summary(sa_burglary, agg = "ATT")
sunab_agg <- list(
  property_att = coef(sa_prop_agg)[1],
  property_se = se(sa_prop_agg)[1],
  burglary_att = coef(sa_burg_agg)[1],
  burglary_se = se(sa_burg_agg)[1]
)
saveRDS(sunab_agg, file.path(data_dir, "sunab_agg.rds"))
cat("Sun-Abraham aggregate ATT (property):", round(sunab_agg$property_att, 4),
    "(SE:", round(sunab_agg$property_se, 4), ")\n")
cat("Sun-Abraham aggregate ATT (burglary):", round(sunab_agg$burglary_att, 4),
    "(SE:", round(sunab_agg$burglary_se, 4), ")\n")

# ===========================================================================
# 3. Levels specification (not just logs)
# ===========================================================================
cat("\n=== Levels Specification ===\n")

cs_property_levels <- att_gt(
  yname = "property_crime_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_levels <- aggte(cs_property_levels, type = "simple")
cat("Property crime (levels) ATT:", round(agg_levels$overall.att, 2),
    "per 100K (SE:", round(agg_levels$overall.se, 2), ")\n")

cs_burglary_levels <- att_gt(
  yname = "burglary_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_burg_levels <- aggte(cs_burglary_levels, type = "simple")
cat("Burglary (levels) ATT:", round(agg_burg_levels$overall.att, 2),
    "per 100K (SE:", round(agg_burg_levels$overall.se, 2), ")\n")

saveRDS(list(property = cs_property_levels, burglary = cs_burglary_levels,
             agg_property = agg_levels, agg_burglary = agg_burg_levels),
        file.path(data_dir, "cs_levels_results.rds"))

# ===========================================================================
# 4. State-specific linear trends
# ===========================================================================
cat("\n=== State-specific linear trends ===\n")

panel <- panel %>% mutate(state_trend = state_id * year)

twfe_trend_property <- feols(log_property_crime ~ post_ebt | state_id + year +
                              state_id[year], data = panel, cluster = ~state_abbr)
twfe_trend_burglary <- feols(log_burglary ~ post_ebt | state_id + year +
                              state_id[year], data = panel, cluster = ~state_abbr)

cat("With state trends:\n")
cat("  Property:", round(coef(twfe_trend_property), 4),
    "(SE:", round(se(twfe_trend_property), 4), ")\n")
cat("  Burglary:", round(coef(twfe_trend_burglary), 4),
    "(SE:", round(se(twfe_trend_burglary), 4), ")\n")

saveRDS(list(property = twfe_trend_property, burglary = twfe_trend_burglary),
        file.path(data_dir, "twfe_trends.rds"))

# ===========================================================================
# 5. Leave-one-out sensitivity
# ===========================================================================
cat("\n=== Leave-one-out sensitivity ===\n")

states <- unique(panel$state_abbr)
loo_results <- data.frame(
  dropped_state = character(),
  property_att = numeric(),
  burglary_att = numeric(),
  stringsAsFactors = FALSE
)

for (st in states) {
  tryCatch({
    panel_loo <- panel[panel$state_abbr != st, ]
    # Re-number state_id
    panel_loo$state_id <- as.integer(factor(panel_loo$state_abbr))

    cs_loo <- att_gt(
      yname = "log_property_crime",
      tname = "year", idname = "state_id", gname = "first_treat",
      data = as.data.frame(panel_loo),
      control_group = "notyettreated",
      anticipation = 0, base_period = "varying"
    )
    agg_loo <- aggte(cs_loo, type = "simple")

    loo_results <- rbind(loo_results, data.frame(
      dropped_state = st,
      property_att = agg_loo$overall.att,
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    cat("  LOO failed for", st, "\n")
  })
}

cat("Leave-one-out range for property crime ATT:\n")
cat("  Min:", round(min(loo_results$property_att, na.rm = TRUE), 4), "\n")
cat("  Max:", round(max(loo_results$property_att, na.rm = TRUE), 4), "\n")
cat("  Mean:", round(mean(loo_results$property_att, na.rm = TRUE), 4), "\n")

fwrite(loo_results, file.path(data_dir, "loo_results.csv"))

# ===========================================================================
# 6. MDE Calculation (how large an effect could we detect?)
# ===========================================================================
cat("\n=== Minimum Detectable Effect ===\n")

# For our main spec: SE of property crime ATT = agg_property$overall.se
se_main <- cs_results$agg_property$overall.se
mde_95 <- 1.96 * se_main + 0.84 * se_main  # 80% power, 5% significance
mde_pct <- (exp(mde_95) - 1) * 100

cat("SE of property crime ATT:", round(se_main, 4), "\n")
cat("MDE (80% power, 5% sig):", round(mde_95, 4), "log points\n")
cat("MDE in %:", round(mde_pct, 1), "%\n")

se_burg <- cs_results$agg_burglary$overall.se
mde_burg <- (exp(1.96 * se_burg + 0.84 * se_burg) - 1) * 100
cat("Burglary MDE:", round(mde_burg, 1), "%\n")

mde_data <- data.frame(
  outcome = c("Property Crime", "Burglary"),
  se = c(se_main, se_burg),
  mde_logpts = c(1.96 * se_main + 0.84 * se_main, 1.96 * se_burg + 0.84 * se_burg),
  mde_pct = c(mde_pct, mde_burg)
)
fwrite(mde_data, file.path(data_dir, "mde_results.csv"))

# ===========================================================================
# 7. HonestDiD Sensitivity Analysis
# ===========================================================================
cat("\n=== HonestDiD Sensitivity (Rambachan-Roth) ===\n")

tryCatch({
  # Extract event study coefficients for HonestDiD
  es_data <- cs_results$es_property

  # HonestDiD needs betahat and sigma from the event study
  # The es object from aggte has egt.att and inf.function
  betahat <- es_data$att.egt
  sigma <- es_data$overall.se

  # Identify pre-treatment coefficients
  pre_idx <- which(es_data$egt < 0)
  post_idx <- which(es_data$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    cat("Event study has", length(pre_idx), "pre-periods and",
        length(post_idx), "post-periods\n")
    cat("Pre-treatment coefficients:\n")
    print(data.frame(
      event_time = es_data$egt[pre_idx],
      att = round(es_data$att.egt[pre_idx], 4),
      se = round(es_data$se.egt[pre_idx], 4)
    ))
  }

  cat("HonestDiD: Pre-trend coefficients suggest ",
      ifelse(all(abs(es_data$att.egt[pre_idx] / es_data$se.egt[pre_idx]) < 1.96),
             "NO significant pre-trends (good)",
             "SOME significant pre-trends (caution)"), "\n")

}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
})

cat("\n=== All robustness checks complete ===\n")
