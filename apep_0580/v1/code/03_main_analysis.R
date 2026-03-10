## ============================================================
## 03_main_analysis.R — Primary DiD estimation
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Panel loaded:", nrow(panel), "obs,", n_distinct(panel$state_abbr), "states ===\n")

# ============================================================
# A) Treatment Rollout Diagnostics
# ============================================================

cat("\n=== A: Treatment Rollout ===\n")

# Cohort sizes
cohorts <- panel %>%
  filter(ever_reformed) %>%
  distinct(state_abbr, reform_year) %>%
  count(reform_year, name = "n_states")

cat("Reform cohorts:\n")
print(cohorts)

never_treated <- panel %>%
  filter(!ever_reformed) %>%
  distinct(state_abbr) %>%
  nrow()
cat("Never-treated states:", never_treated, "\n")

# Save cohort data for figures
fwrite(cohorts, file.path(data_dir, "cohort_sizes.csv"))

# ============================================================
# B) Average Outcomes by Reform Status
# ============================================================

cat("\n=== B: Pre-treatment means ===\n")

pre_means <- panel %>%
  filter(year < 2014) %>%
  group_by(ever_reformed) %>%
  summarize(
    mean_drug_death = mean(drug_death_rate, na.rm = TRUE),
    sd_drug_death = sd(drug_death_rate, na.rm = TRUE),
    n_states = n_distinct(state_abbr),
    .groups = "drop"
  )

cat("Pre-reform (2004-2013) drug death rates:\n")
print(pre_means)

# ============================================================
# C) Callaway & Sant'Anna (2021) Estimation
# ============================================================

cat("\n=== C: Callaway & Sant'Anna DiD ===\n")

# Prepare data for did::att_gt()
# Requires: numeric ID, time, group (first_treat), outcome
did_data <- panel %>%
  filter(!is.na(drug_death_rate)) %>%
  mutate(
    state_id = as.numeric(factor(state_abbr)),
    # CS-DiD requires first_treat = 0 for never-treated
    first_treat = ifelse(first_treat == 0, 0, first_treat)
  ) %>%
  arrange(state_id, year)

cat("  CS-DiD data:", nrow(did_data), "obs\n")
cat("  Treated groups:", paste(sort(unique(did_data$first_treat[did_data$first_treat > 0])),
                                collapse = ", "), "\n")
cat("  Never-treated:", sum(did_data$first_treat == 0 & did_data$year == 2010), "states\n")

# Main specification: Drug overdose death rate
# Control group: never-treated states
cs_drug <- tryCatch({
  att_gt(
    yname = "drug_death_rate",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = did_data,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
}, error = function(e) {
  cat("  CS-DiD error:", e$message, "\n")
  cat("  Trying with not-yet-treated control group...\n")
  tryCatch({
    att_gt(
      yname = "drug_death_rate",
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = did_data,
      control_group = "notyettreated",
      anticipation = 0,
      base_period = "universal"
    )
  }, error = function(e2) {
    cat("  CS-DiD failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(cs_drug)) {
  cat("\n  CS-DiD group-time ATTs estimated successfully.\n")
  cat("  Number of group-time ATTs:", length(cs_drug$att), "\n")

  # Overall ATT
  agg_overall <- aggte(cs_drug, type = "simple")
  cat("\n  OVERALL ATT (simple):\n")
  cat("    ATT =", round(agg_overall$overall.att, 3), "\n")
  cat("    SE  =", round(agg_overall$overall.se, 3), "\n")
  cat("    95% CI: [", round(agg_overall$overall.att - 1.96*agg_overall$overall.se, 3),
      ",", round(agg_overall$overall.att + 1.96*agg_overall$overall.se, 3), "]\n")

  # Event study aggregation
  es_drug <- aggte(cs_drug, type = "dynamic", min_e = -5, max_e = 5)
  cat("\n  EVENT STUDY (dynamic aggregation):\n")

  es_df <- data.frame(
    event_time = es_drug$egt,
    att = es_drug$att.egt,
    se = es_drug$se.egt
  ) %>%
    mutate(
      ci_lower = att - 1.96 * se,
      ci_upper = att + 1.96 * se,
      pval = 2 * (1 - pnorm(abs(att / se))),
      stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**",
                        pval < 0.10 ~ "*", TRUE ~ "")
    )

  print(es_df)
  fwrite(es_df, file.path(data_dir, "event_study_drug.csv"))

  # Group-level aggregation (by reform cohort)
  agg_group <- aggte(cs_drug, type = "group")
  group_df <- data.frame(
    group = agg_group$egt,
    att = agg_group$att.egt,
    se = agg_group$se.egt
  ) %>%
    mutate(ci_lower = att - 1.96*se, ci_upper = att + 1.96*se)

  cat("\n  GROUP-LEVEL ATTs:\n")
  print(group_df)
  fwrite(group_df, file.path(data_dir, "group_atts_drug.csv"))

  # Calendar-time aggregation
  agg_cal <- aggte(cs_drug, type = "calendar")
  cal_df <- data.frame(
    year = agg_cal$egt,
    att = agg_cal$att.egt,
    se = agg_cal$se.egt
  ) %>%
    mutate(ci_lower = att - 1.96*se, ci_upper = att + 1.96*se)

  cat("\n  CALENDAR-TIME ATTs:\n")
  print(cal_df)
  fwrite(cal_df, file.path(data_dir, "calendar_atts_drug.csv"))
}

# ============================================================
# D) TWFE Comparison (for reference only)
# ============================================================

cat("\n=== D: TWFE Comparison ===\n")

# Standard TWFE (for comparison — NOT the primary specification)
twfe_drug <- feols(
  drug_death_rate ~ treated | state_abbr + year,
  data = panel,
  cluster = ~state_abbr
)

cat("  TWFE drug death rate:\n")
cat("    Coef =", round(coef(twfe_drug)["treatedTRUE"], 3), "\n")
cat("    SE   =", round(sqrt(vcov(twfe_drug)["treatedTRUE","treatedTRUE"]), 3), "\n")

# Sun-Abraham estimator
sa_drug <- tryCatch({
  feols(
    drug_death_rate ~ sunab(first_treat, year) | state_abbr + year,
    data = panel %>% filter(first_treat != 0 | !ever_reformed),
    cluster = ~state_abbr
  )
}, error = function(e) {
  cat("  Sun-Abraham failed:", e$message, "\n")
  NULL
})

if (!is.null(sa_drug)) {
  cat("\n  Sun-Abraham event study:\n")
  sa_coefs <- coef(sa_drug)
  cat("  Coefficients:", length(sa_coefs), "\n")

  # Extract event-study coefficients
  sa_df <- data.frame(
    term = names(sa_coefs),
    estimate = unname(sa_coefs),
    se = sqrt(diag(vcov(sa_drug)))
  )
  fwrite(sa_df, file.path(data_dir, "sun_abraham_drug.csv"))
}

# ============================================================
# E) Homicide Analysis (if data available)
# ============================================================

cat("\n=== E: Homicide Analysis ===\n")

if ("homicide_rate" %in% names(panel) && sum(!is.na(panel$homicide_rate)) > 100) {
  cat("  Homicide data available. Running CS-DiD...\n")

  hom_data <- did_data %>% filter(!is.na(homicide_rate))

  cs_hom <- tryCatch({
    att_gt(
      yname = "homicide_rate",
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = hom_data,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    )
  }, error = function(e) {
    cat("  Homicide CS-DiD error:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_hom)) {
    agg_hom <- aggte(cs_hom, type = "simple")
    cat("  Homicide ATT =", round(agg_hom$overall.att, 3),
        "(SE =", round(agg_hom$overall.se, 3), ")\n")

    es_hom <- aggte(cs_hom, type = "dynamic", min_e = -5, max_e = 5)
    es_hom_df <- data.frame(
      event_time = es_hom$egt,
      att = es_hom$att.egt,
      se = es_hom$se.egt
    ) %>%
      mutate(ci_lower = att - 1.96*se, ci_upper = att + 1.96*se)

    fwrite(es_hom_df, file.path(data_dir, "event_study_homicide.csv"))
  }
} else {
  cat("  No homicide data available for analysis.\n")
}

# ============================================================
# F) Dose-Response by Reform Intensity
# ============================================================

cat("\n=== F: Dose-Response ===\n")

# Separate CS-DiD for strong reforms (abolition + conviction) vs weak (transparency)
strong_data <- did_data %>%
  filter(first_treat == 0 | reform_type >= 2)

weak_data <- did_data %>%
  filter(first_treat == 0 | reform_type == 1)

cs_strong <- tryCatch({
  att_gt(yname = "drug_death_rate", tname = "year", idname = "state_id",
         gname = "first_treat", data = strong_data,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

cs_weak <- tryCatch({
  att_gt(yname = "drug_death_rate", tname = "year", idname = "state_id",
         gname = "first_treat", data = weak_data,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

if (!is.null(cs_strong)) {
  agg_strong <- aggte(cs_strong, type = "simple")
  cat("  Strong reform ATT =", round(agg_strong$overall.att, 3),
      "(SE =", round(agg_strong$overall.se, 3), ")\n")
}

if (!is.null(cs_weak)) {
  agg_weak <- aggte(cs_weak, type = "simple")
  cat("  Weak reform ATT =", round(agg_weak$overall.att, 3),
      "(SE =", round(agg_weak$overall.se, 3), ")\n")
}

# ============================================================
# G) Heterogeneity by Forfeiture Dependence
# ============================================================

cat("\n=== G: Heterogeneity by Forfeiture Dependence ===\n")

# Split sample by pre-reform forfeiture intensity
high_forf_data <- did_data %>%
  filter(first_treat == 0 | high_forfeiture)

low_forf_data <- did_data %>%
  filter(first_treat == 0 | !high_forfeiture)

cs_high <- tryCatch({
  att_gt(yname = "drug_death_rate", tname = "year", idname = "state_id",
         gname = "first_treat", data = high_forf_data,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

cs_low <- tryCatch({
  att_gt(yname = "drug_death_rate", tname = "year", idname = "state_id",
         gname = "first_treat", data = low_forf_data,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

if (!is.null(cs_high)) {
  agg_high <- aggte(cs_high, type = "simple")
  cat("  High forfeiture ATT =", round(agg_high$overall.att, 3),
      "(SE =", round(agg_high$overall.se, 3), ")\n")
}

if (!is.null(cs_low)) {
  agg_low <- aggte(cs_low, type = "simple")
  cat("  Low forfeiture ATT =", round(agg_low$overall.att, 3),
      "(SE =", round(agg_low$overall.se, 3), ")\n")
}

# ============================================================
# Save All Results
# ============================================================

cat("\n=== Saving results ===\n")

results <- list(
  cs_drug = if (exists("cs_drug") && !is.null(cs_drug)) {
    list(
      overall_att = agg_overall$overall.att,
      overall_se = agg_overall$overall.se,
      n_groups = length(unique(cs_drug$group))
    )
  },
  twfe = list(
    coef = coef(twfe_drug)["treatedTRUE"],
    se = sqrt(vcov(twfe_drug)["treatedTRUE","treatedTRUE"])
  )
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("  Results saved to main_results.rds\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
