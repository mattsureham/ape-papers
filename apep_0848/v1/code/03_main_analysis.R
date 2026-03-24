# =============================================================================
# 03_main_analysis.R — Main DiD estimation for apep_0848
# =============================================================================

source("00_packages.R")

panel_hc <- readRDS("../data/panel_healthcare.rds")

# =============================================================================
# 1. TWFE baseline (for comparison — known to be biased with staggered adoption)
# =============================================================================
message("=== TWFE Baseline ===")

# Main outcome: log employment
twfe_emp <- feols(
  log_emp ~ treated | county_fips + period,
  data = panel_hc,
  cluster = ~state_fips
)

# Hiring rate
twfe_hire <- feols(
  hire_rate ~ treated | county_fips + period,
  data = panel_hc,
  cluster = ~state_fips
)

# Separation rate
twfe_sep <- feols(
  sep_rate ~ treated | county_fips + period,
  data = panel_hc,
  cluster = ~state_fips
)

# Log earnings
twfe_earn <- feols(
  log_earn ~ treated | county_fips + period,
  data = panel_hc,
  cluster = ~state_fips
)

# Turnover rate
twfe_turn <- feols(
  turnover_rate ~ treated | county_fips + period,
  data = panel_hc,
  cluster = ~state_fips
)

message("TWFE results:")
etable(twfe_emp, twfe_hire, twfe_sep, twfe_earn, twfe_turn)

# =============================================================================
# 2. Callaway-Sant'Anna (heterogeneity-robust)
# =============================================================================
message("\n=== Callaway-Sant'Anna ===")

# Collapse to county-industry level with numeric ID
panel_cs <- panel_hc %>%
  mutate(unit_id = as.integer(factor(paste(county_fips, industry)))) %>%
  # C&S requires: first_treat = 0 for never-treated
  mutate(first_treat_cs = ifelse(first_treat_period == 0, 0, first_treat_period))

# Log employment
cs_emp <- att_gt(
  yname = "log_emp",
  tname = "period",
  idname = "unit_id",
  gname = "first_treat_cs",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

# Aggregate: overall ATT
agg_emp <- aggte(cs_emp, type = "simple")
message("C&S ATT (log employment): ", round(agg_emp$overall.att, 4),
        " (SE: ", round(agg_emp$overall.se, 4), ")")

# Event study
es_emp <- aggte(cs_emp, type = "dynamic", min_e = -8, max_e = 16)

# Hiring rate
cs_hire <- att_gt(
  yname = "hire_rate",
  tname = "period",
  idname = "unit_id",
  gname = "first_treat_cs",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_hire <- aggte(cs_hire, type = "simple")
message("C&S ATT (hire rate): ", round(agg_hire$overall.att, 4),
        " (SE: ", round(agg_hire$overall.se, 4), ")")

es_hire <- aggte(cs_hire, type = "dynamic", min_e = -8, max_e = 16)

# Separation rate
cs_sep <- att_gt(
  yname = "sep_rate",
  tname = "period",
  idname = "unit_id",
  gname = "first_treat_cs",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_sep <- aggte(cs_sep, type = "simple")
message("C&S ATT (separation rate): ", round(agg_sep$overall.att, 4),
        " (SE: ", round(agg_sep$overall.se, 4), ")")

es_sep <- aggte(cs_sep, type = "dynamic", min_e = -8, max_e = 16)

# Log earnings
cs_earn <- att_gt(
  yname = "log_earn",
  tname = "period",
  idname = "unit_id",
  gname = "first_treat_cs",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_earn <- aggte(cs_earn, type = "simple")
message("C&S ATT (log earnings): ", round(agg_earn$overall.att, 4),
        " (SE: ", round(agg_earn$overall.se, 4), ")")

es_earn <- aggte(cs_earn, type = "dynamic", min_e = -8, max_e = 16)

# Turnover rate
cs_turn <- att_gt(
  yname = "turnover_rate",
  tname = "period",
  idname = "unit_id",
  gname = "first_treat_cs",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_turn <- aggte(cs_turn, type = "simple")
message("C&S ATT (turnover rate): ", round(agg_turn$overall.att, 4),
        " (SE: ", round(agg_turn$overall.se, 4), ")")

es_turn <- aggte(cs_turn, type = "dynamic", min_e = -8, max_e = 16)

# =============================================================================
# 3. Subsector heterogeneity (TWFE by industry)
# =============================================================================
message("\n=== Subsector Heterogeneity ===")

twfe_by_ind <- list()
for (ind in c("621", "622", "623")) {
  sub <- panel_hc %>% filter(industry == ind)
  twfe_by_ind[[ind]] <- list(
    emp = feols(log_emp ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    hire = feols(hire_rate ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    sep = feols(sep_rate ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    earn = feols(log_earn ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    turn = feols(turnover_rate ~ treated | county_fips + period, data = sub, cluster = ~state_fips)
  )
  message(sprintf("Industry %s: emp=%.4f (%.4f), hire=%.4f (%.4f), sep=%.4f (%.4f)",
                  ind,
                  coef(twfe_by_ind[[ind]]$emp)["treated"], se(twfe_by_ind[[ind]]$emp)["treated"],
                  coef(twfe_by_ind[[ind]]$hire)["treated"], se(twfe_by_ind[[ind]]$hire)["treated"],
                  coef(twfe_by_ind[[ind]]$sep)["treated"], se(twfe_by_ind[[ind]]$sep)["treated"]))
}

# =============================================================================
# 4. Save results
# =============================================================================

results <- list(
  twfe = list(emp = twfe_emp, hire = twfe_hire, sep = twfe_sep,
              earn = twfe_earn, turn = twfe_turn),
  cs = list(emp = cs_emp, hire = cs_hire, sep = cs_sep,
            earn = cs_earn, turn = cs_turn),
  cs_agg = list(emp = agg_emp, hire = agg_hire, sep = agg_sep,
                earn = agg_earn, turn = agg_turn),
  cs_es = list(emp = es_emp, hire = es_hire, sep = es_sep,
               earn = es_earn, turn = es_turn),
  twfe_by_ind = twfe_by_ind,
  panel_cs = panel_cs
)

saveRDS(results, "../data/main_results.rds")

# =============================================================================
# 5. Write diagnostics.json
# =============================================================================
n_treated_counties <- panel_hc %>%
  filter(group != "never") %>%
  pull(county_fips) %>%
  n_distinct()

n_pre <- panel_hc %>%
  filter(yearqtr < 2018) %>%
  pull(period) %>%
  n_distinct()

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = nrow(panel_hc),
  n_counties = n_distinct(panel_hc$county_fips),
  n_states_treated = n_distinct(panel_hc$state_fips[panel_hc$group != "never"]),
  n_states_control = n_distinct(panel_hc$state_fips[panel_hc$group == "never"]),
  cs_att_log_emp = round(agg_emp$overall.att, 6),
  cs_se_log_emp = round(agg_emp$overall.se, 6),
  cs_att_hire_rate = round(agg_hire$overall.att, 6),
  cs_se_hire_rate = round(agg_hire$overall.se, 6),
  cs_att_sep_rate = round(agg_sep$overall.att, 6),
  cs_se_sep_rate = round(agg_sep$overall.se, 6),
  cs_att_log_earn = round(agg_earn$overall.att, 6),
  cs_se_log_earn = round(agg_earn$overall.se, 6),
  cs_att_turnover = round(agg_turn$overall.att, 6),
  cs_se_turnover = round(agg_turn$overall.se, 6)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

message("\nMain analysis complete. Results saved.")
message(sprintf("  Treated counties: %d", n_treated_counties))
message(sprintf("  Control counties: %d", n_distinct(panel_hc$county_fips[panel_hc$group == "never"])))
message(sprintf("  Pre-treatment periods: %d", n_pre))
