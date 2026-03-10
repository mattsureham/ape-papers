# 03_main_analysis.R — Main staggered DiD analysis
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "facility_panel.csv"))
bat_info <- fread(file.path(data_dir, "bat_conclusions.csv"))

cat("Panel loaded:", nrow(panel), "observations\n")
cat("Columns:", paste(names(panel), collapse = ", "), "\n\n")

# ============================================================================
# PART 1: Summary Statistics
# ============================================================================

summary_vars <- c("nox_tonnes", "sox_tonnes", "co2_tonnes", "pm_tonnes",
                   "log_nox_tonnes", "log_sox_tonnes", "log_co2_tonnes", "log_pm_tonnes")
summary_vars <- summary_vars[summary_vars %in% names(panel)]

sumstats_dt <- rbindlist(lapply(summary_vars, function(v) {
  vals <- as.numeric(panel[[v]])
  data.table(
    Variable = v,
    N = sum(!is.na(vals) & vals > 0),
    Mean = mean(vals, na.rm = TRUE),
    SD = sd(vals, na.rm = TRUE),
    Min = min(vals, na.rm = TRUE),
    P25 = quantile(vals, 0.25, na.rm = TRUE),
    Median = median(vals, na.rm = TRUE),
    P75 = quantile(vals, 0.75, na.rm = TRUE),
    Max = max(vals, na.rm = TRUE)
  )
}))
fwrite(sumstats_dt, file.path(data_dir, "summary_statistics.csv"))
cat("Summary Statistics:\n")
print(sumstats_dt)

# Treatment distribution
cat("\n=== Treatment Distribution ===\n")
treat_dist <- panel[, .(n_units = uniqueN(sector_country), n_obs = .N),
                     by = first_treat][order(first_treat)]
print(treat_dist)
fwrite(treat_dist, file.path(data_dir, "treatment_distribution.csv"))

# ============================================================================
# PART 2: Primary outcome: log NOx
# ============================================================================

primary_outcome <- "log_nox_tonnes"
cat("\nPrimary outcome:", primary_outcome, "\n")
cat("Non-zero observations:", sum(panel[[primary_outcome]] > 0, na.rm = TRUE), "\n")

# Create numeric IDs for fixest
panel[, unit_id := as.integer(as.factor(sector_country))]
panel[, year := as.integer(year)]

# Focus on period with good data coverage (2000+)
analysis_data <- panel[year >= 2000 & !is.na(get(primary_outcome))]
cat("Analysis sample (2000+):", nrow(analysis_data), "observations\n")
cat("Units:", uniqueN(analysis_data$sector_country), "\n")
cat("Years:", paste(range(analysis_data$year), collapse = "-"), "\n")

# ============================================================================
# PART 3: TWFE Baseline
# ============================================================================

cat("\n=== TWFE BASELINE ===\n")

# Model 1: Sector-country FE + year FE
twfe1 <- feols(
  log_nox_tonnes ~ post_bat | unit_id + year,
  data = analysis_data, cluster = ~bat_sector
)
cat("TWFE (sector-cluster):\n")
summary(twfe1)

# Model 2: Sector-country FE + country × year FE
twfe2 <- feols(
  log_nox_tonnes ~ post_bat | unit_id + country^year,
  data = analysis_data, cluster = ~bat_sector
)
cat("\nTWFE (country × year FE):\n")
summary(twfe2)

# Model 3: Alternative clustering at sector × country level
twfe3 <- feols(
  log_nox_tonnes ~ post_bat | unit_id + year,
  data = analysis_data, cluster = ~sector_country
)
cat("\nTWFE (sector-country cluster):\n")
summary(twfe3)

# Extract results safely
get_pval <- function(m, coef_name) {
  ct <- coeftable(m)
  ct[coef_name, "Pr(>|t|)"]
}

fwrite(data.table(
  model = c("TWFE_sector_cluster", "TWFE_country_x_year", "TWFE_unit_cluster"),
  outcome = primary_outcome,
  coefficient = c(coef(twfe1)["post_bat"], coef(twfe2)["post_bat"], coef(twfe3)["post_bat"]),
  se = c(se(twfe1)["post_bat"], se(twfe2)["post_bat"], se(twfe3)["post_bat"]),
  pvalue = c(get_pval(twfe1, "post_bat"), get_pval(twfe2, "post_bat"), get_pval(twfe3, "post_bat")),
  n_obs = c(nobs(twfe1), nobs(twfe2), nobs(twfe3))
), file.path(data_dir, "twfe_results.csv"))

# ============================================================================
# PART 4: Sun-Abraham Event Study
# ============================================================================

cat("\n=== SUN-ABRAHAM EVENT STUDY ===\n")

# sunab() needs cohort = first treatment year; 10000 for never-treated
sa_data <- copy(analysis_data)
sa_data[, cohort := fifelse(first_treat == 0, 10000L, first_treat)]

sa_result <- tryCatch({
  feols(
    log_nox_tonnes ~ sunab(cohort, year) | unit_id + year,
    data = sa_data, cluster = ~bat_sector
  )
}, error = function(e) {
  cat("sunab() failed:", e$message, "\n")
  # Fallback: manual event study with i() notation
  sa_data[, rel_time := year - first_treat]
  sa_data[first_treat == 0, rel_time := -1000L]
  sa_data[, rel_time_bin := fcase(
    rel_time <= -6, -6L,
    rel_time >= 8, 8L,
    default = rel_time
  )]

  feols(
    log_nox_tonnes ~ i(rel_time_bin, ref = -1) | unit_id + year,
    data = sa_data[rel_time > -1000],
    cluster = ~bat_sector
  )
})

cat("Sun-Abraham result:\n")
print(summary(sa_result))

# Extract event study coefficients
sa_coefs <- as.data.table(coeftable(sa_result), keep.rownames = TRUE)
setnames(sa_coefs, c("term", "estimate", "se", "tstat", "pvalue"))
sa_coefs[, event_time := as.integer(str_extract(term, "-?\\d+"))]
sa_coefs <- sa_coefs[!is.na(event_time)]
sa_coefs[, ci_lower := estimate - 1.96 * se]
sa_coefs[, ci_upper := estimate + 1.96 * se]

fwrite(sa_coefs, file.path(data_dir, "sun_abraham_event_study.csv"))

# Aggregate ATT (post-treatment periods)
sa_att <- sa_coefs[event_time >= 0, .(
  att = mean(estimate, na.rm = TRUE),
  att_se = sqrt(mean(se^2, na.rm = TRUE)),
  n_post_periods = .N
)]
cat("\nAggregate ATT:\n")
print(sa_att)
fwrite(sa_att, file.path(data_dir, "sun_abraham_att.csv"))

# ============================================================================
# PART 5: Callaway-Sant'Anna
# ============================================================================

cat("\n=== CALLAWAY-SANT'ANNA ===\n")

cs_data <- copy(analysis_data)
cs_data[, unit_num := as.integer(as.factor(sector_country))]

cs_result <- tryCatch({
  att_gt(
    yname = primary_outcome,
    tname = "year",
    idname = "unit_num",
    gname = "first_treat",
    data = cs_data,
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("CS notyettreated failed:", e$message, "\n")
  tryCatch({
    att_gt(
      yname = primary_outcome,
      tname = "year",
      idname = "unit_num",
      gname = "first_treat",
      data = cs_data,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    )
  }, error = function(e2) {
    cat("CS nevertreated also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(cs_result)) {
  cs_dynamic <- aggte(cs_result, type = "dynamic")
  cs_overall <- aggte(cs_result, type = "simple")

  cat("CS Overall ATT:", cs_overall$overall.att,
      "(SE:", cs_overall$overall.se, ")\n")

  cs_es <- data.table(
    event_time = cs_dynamic$egt,
    estimate = cs_dynamic$att.egt,
    se = cs_dynamic$se.egt,
    ci_lower = cs_dynamic$att.egt - 1.96 * cs_dynamic$se.egt,
    ci_upper = cs_dynamic$att.egt + 1.96 * cs_dynamic$se.egt
  )
  fwrite(cs_es, file.path(data_dir, "cs_event_study.csv"))

  fwrite(data.table(
    model = "CS-DiD",
    att = cs_overall$overall.att,
    se = cs_overall$overall.se,
    ci_lower = cs_overall$overall.att - 1.96 * cs_overall$overall.se,
    ci_upper = cs_overall$overall.att + 1.96 * cs_overall$overall.se
  ), file.path(data_dir, "cs_att.csv"))
}

# ============================================================================
# PART 6: Multiple outcomes
# ============================================================================

cat("\n=== MULTIPLE OUTCOMES ===\n")

outcome_cols <- c("log_nox_tonnes", "log_sox_tonnes", "log_co2_tonnes", "log_pm_tonnes")
outcome_cols <- outcome_cols[outcome_cols %in% names(analysis_data)]

multi_results <- list()
for (outcome in outcome_cols) {
  model <- tryCatch({
    feols(
      as.formula(paste0(outcome, " ~ post_bat | unit_id + year")),
      data = analysis_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model)) {
    pv <- get_pval(model, "post_bat")
    multi_results[[outcome]] <- data.table(
      outcome = outcome,
      coefficient = coef(model)["post_bat"],
      se = se(model)["post_bat"],
      pvalue = pv,
      n_obs = nobs(model)
    )
    cat(sprintf("  %s: coef=%.4f (SE=%.4f, p=%.3f)\n",
                outcome, coef(model)["post_bat"],
                se(model)["post_bat"], pv))
  }
}

if (length(multi_results) > 0) {
  multi_dt <- rbindlist(multi_results)
  fwrite(multi_dt, file.path(data_dir, "multi_outcome_results.csv"))
}

# ============================================================================
# PART 7: Economic outcomes (Eurostat SBS)
# ============================================================================

cat("\n=== ECONOMIC OUTCOMES (Eurostat SBS) ===\n")

sbs_file <- file.path(data_dir, "eurostat_sbs.csv")
if (file.exists(sbs_file)) {
  sbs_raw <- fread(sbs_file)
  cat("SBS loaded:", nrow(sbs_raw), "observations\n")
  cat("SBS columns:", paste(names(sbs_raw), collapse = ", "), "\n")

  # Map SBS NACE to BAT sectors
  sbs_nace_map <- data.table(
    nace_r2 = c("C24", "C241", "C2410", "C23", "C231", "C235", "C2351",
                "C17", "C171", "C19", "C192", "C1920", "C20", "C201",
                "D", "D35", "D351", "E", "E38", "C10", "C11"),
    bat_sector = c(
      rep("Iron and Steel Production", 3),
      rep("Production of Cement, Lime and Magnesium Oxide", 4),
      rep("Production of Pulp, Paper and Board", 2),
      rep("Refining of Mineral Oil and Gas", 3),
      rep("Production of Chlor-alkali", 2),
      rep("Large Combustion Plants", 3),
      rep("Waste Treatment", 2),
      rep("Food, Drink and Milk Industries", 2)
    )
  )

  sbs_merged <- merge(sbs_raw, sbs_nace_map, by = "nace_r2", all.x = FALSE)
  if (nrow(sbs_merged) > 0) {
    sbs_merged <- merge(sbs_merged,
                         bat_info[, .(bat_sector, compliance_year)],
                         by = "bat_sector", all.x = TRUE)

    time_col <- intersect(c("TIME_PERIOD", "time"), names(sbs_merged))[1]
    if (!is.na(time_col)) {
      sbs_merged[, sbs_year := as.integer(get(time_col))]
      sbs_merged[, post_bat_sbs := as.integer(!is.na(compliance_year) & sbs_year >= compliance_year)]
      fwrite(sbs_merged, file.path(data_dir, "sbs_panel.csv"))
      cat("SBS panel:", nrow(sbs_merged), "observations\n")
    }
  }
}

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
