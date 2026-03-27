# 04_robustness.R — Robustness checks
# apep_1049: EU Single-Use Plastics Directive

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

# ===========================================================================
# 1. Never-treated as control group (instead of not-yet-treated)
# ===========================================================================
message("=== Robustness: Never-treated control group ===")

cs_data <- panel[!is.na(plastic_pc) & !is.na(first_treat) & !is.na(country_id)]

# Only works if there are never-treated units
n_never <- uniqueN(cs_data$country_id[cs_data$first_treat == 0])
message(sprintf("Never-treated countries: %d", n_never))

if (n_never >= 2) {
  cs_plastic_nt <- att_gt(
    yname = "plastic_pc",
    tname = "year",
    idname = "country_id",
    gname = "first_treat",
    data = cs_data,
    control_group = "nevertreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )
  agg_nt <- aggte(cs_plastic_nt, type = "simple")
  message("ATT with never-treated controls:")
  summary(agg_nt)
  saveRDS(agg_nt, "data/rob_nevertreated.rds")
} else {
  message("Skipping: insufficient never-treated units")
}

# ===========================================================================
# 2. Outcome in levels (tonnes) instead of per-capita
# ===========================================================================
message("\n=== Robustness: Plastic in levels (tonnes) ===")

cs_data_levels <- panel[!is.na(plastic) & !is.na(first_treat) & !is.na(country_id)]

cs_plastic_levels <- att_gt(
  yname = "plastic",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_levels,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_levels <- aggte(cs_plastic_levels, type = "simple")
message("ATT (plastic, tonnes):")
summary(agg_levels)
saveRDS(agg_levels, "data/rob_levels.rds")

# ===========================================================================
# 3. Log outcome
# ===========================================================================
message("\n=== Robustness: Log plastic per capita ===")

panel[, ln_plastic_pc := log(plastic_pc + 1)]

cs_data_log <- panel[!is.na(ln_plastic_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_plastic_log <- att_gt(
  yname = "ln_plastic_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_log,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_log <- aggte(cs_plastic_log, type = "simple")
message("ATT (log plastic_pc):")
summary(agg_log)
saveRDS(agg_log, "data/rob_log.rds")

# ===========================================================================
# 4. Controlling for GDP per capita
# ===========================================================================
message("\n=== Robustness: With GDP control ===")

cs_data_gdp <- panel[!is.na(plastic_pc) & !is.na(ln_gdp_pc) &
                       !is.na(first_treat) & !is.na(country_id)]

cs_plastic_gdp <- att_gt(
  yname = "plastic_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  xformla = ~ln_gdp_pc,
  data = cs_data_gdp,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_gdp <- aggte(cs_plastic_gdp, type = "simple", na.rm = TRUE)
message("ATT with GDP control:")
summary(agg_gdp)
saveRDS(agg_gdp, "data/rob_gdp_control.rds")

# ===========================================================================
# 5. Pre-treatment trend test (formal)
# ===========================================================================
message("\n=== Pre-treatment trend test ===")

# Test: is there a linear pre-trend in plastic_pc before treatment?
pre_data <- panel[treated == 0 & first_treat > 0]
pre_data[, rel_year := year - first_treat]

if (nrow(pre_data) > 10) {
  pretrend_test <- feols(plastic_pc ~ rel_year | geo, data = pre_data, cluster = ~geo)
  message("Pre-trend coefficient (rel_year on plastic_pc):")
  print(summary(pretrend_test))
  saveRDS(pretrend_test, "data/pretrend_test.rds")
}

# ===========================================================================
# 6. Leave-one-out: drop each country and re-estimate
# ===========================================================================
message("\n=== Leave-one-out sensitivity ===")

treated_countries <- unique(panel$geo[panel$first_treat > 0])
loo_results <- list()

for (drop_geo in treated_countries) {
  cs_loo <- panel[geo != drop_geo & !is.na(plastic_pc) & !is.na(first_treat)]
  # Re-create country_id for reduced sample
  cs_loo[, country_id_loo := as.integer(factor(geo))]

  loo_fit <- tryCatch({
    att_gt(
      yname = "plastic_pc",
      tname = "year",
      idname = "country_id_loo",
      gname = "first_treat",
      data = cs_loo,
      control_group = "notyettreated",
      est_method = "dr",
      bstrap = TRUE,
      biters = 500
    )
  }, error = function(e) NULL)

  if (!is.null(loo_fit)) {
    agg_loo <- aggte(loo_fit, type = "simple", na.rm = TRUE)
    loo_results[[drop_geo]] <- data.table(
      dropped = drop_geo,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    )
  }
}

loo_dt <- rbindlist(loo_results)
message("Leave-one-out results:")
print(loo_dt)
saveRDS(loo_dt, "data/loo_results.rds")

# ===========================================================================
# 7. Sun-Abraham estimator (alternative heterogeneity-robust estimator)
# ===========================================================================
message("\n=== Sun-Abraham (fixest::sunab) ===")

# Need cohort variable for sunab
panel[, cohort := fifelse(first_treat == 0, 10000L, first_treat)]

sa_plastic <- feols(plastic_pc ~ sunab(cohort, year) | geo + year,
                    data = panel, cluster = ~geo)
message("Sun-Abraham (plastic_pc):")
print(summary(sa_plastic))
saveRDS(sa_plastic, "data/sa_plastic.rds")

sa_paper <- feols(paper_pc ~ sunab(cohort, year) | geo + year,
                  data = panel, cluster = ~geo)
message("Sun-Abraham (paper_pc):")
print(summary(sa_paper))
saveRDS(sa_paper, "data/sa_paper.rds")

message("\n=== Robustness checks complete ===")
