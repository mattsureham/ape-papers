## 03_main_analysis.R — Main DiD analysis
## apep_0667: EBT rollout and drug-market disruption

source("00_packages.R")

cat("=== Loading panel data ===\n")
panel <- readRDS("../data/panel.rds")

cat("  Panel:", nrow(panel), "rows,", n_distinct(panel$state_abbr), "states,",
    min(panel$year), "-", max(panel$year), "\n")

# Drop rows with missing outcome
panel_main <- panel %>% filter(!is.na(drug_death_rate))
cat("  Non-missing drug_death_rate:", nrow(panel_main), "rows\n")

# ===================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")
# ===================================================================
# All states are eventually treated (1998-2004). Use not-yet-treated as controls.
# Drop 1998 and 1999 cohorts: already treated when data begins (1999), so no
# pre-treatment observations available. Set their first_treat to 0 so CS-DiD
# excludes them from treated groups (they become "already treated" units excluded
# from both treatment and control pools).

panel_main <- panel_main %>%
  mutate(
    first_treat_cs = if_else(first_treat <= 1999, 0L, first_treat)
  )

# Filter to states with first_treat_cs > 0 (those with pre-treatment data)
panel_cs <- panel_main %>% filter(first_treat_cs > 0)
cat("  CS-DiD sample:", nrow(panel_cs), "state-years,",
    n_distinct(panel_cs$state_id), "states\n")
cat("  Cohorts in CS sample:", paste(sort(unique(panel_cs$first_treat_cs)), collapse = ", "), "\n")

cs_out <- att_gt(
  yname       = "drug_death_rate",
  tname       = "year",
  idname      = "state_id",
  gname       = "first_treat_cs",
  data        = panel_cs,
  control_group = "notyettreated",
  anticipation  = 0,
  est_method    = "dr",    # doubly-robust (default)
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000,
  pl            = FALSE
)

cat("  Group-time ATTs computed.\n")
cat("  Number of group-time estimates:", length(cs_out$att), "\n")

# --- Aggregate: Overall ATT ---
cs_overall <- aggte(cs_out, type = "simple")
cat("\n  Overall ATT:\n")
cat("    Estimate: ", round(cs_overall$overall.att, 4), "\n")
cat("    SE:       ", round(cs_overall$overall.se, 4), "\n")
cat("    t-stat:   ", round(cs_overall$overall.att / cs_overall$overall.se, 3), "\n")

# --- Aggregate: Event study (dynamic) ---
cs_dynamic <- aggte(cs_out, type = "dynamic")
cat("\n  Event study (dynamic aggregation):\n")
es_df <- data.frame(
  egt     = cs_dynamic$egt,
  att     = cs_dynamic$att.egt,
  se      = cs_dynamic$se.egt,
  ci_low  = cs_dynamic$att.egt - 1.96 * cs_dynamic$se.egt,
  ci_high = cs_dynamic$att.egt + 1.96 * cs_dynamic$se.egt
)
print(es_df)

# --- Aggregate: By group (cohort) ---
cs_group <- aggte(cs_out, type = "group")
cat("\n  Group-level ATTs:\n")
group_df <- data.frame(
  group  = cs_group$egt,
  att    = cs_group$att.egt,
  se     = cs_group$se.egt
)
print(group_df)

# ===================================================================
cat("\n=== TWFE (comparison specification) ===\n")
# ===================================================================
twfe_main <- feols(
  drug_death_rate ~ treated | state_id + year,
  data    = panel_main,
  cluster = ~state_id
)

cat("  TWFE results:\n")
cat("    Estimate: ", round(coef(twfe_main)["treated"], 4), "\n")
cat("    SE:       ", round(se(twfe_main)["treated"], 4), "\n")
cat("    N:        ", nobs(twfe_main), "\n")
cat("    R-squared:", round(r2(twfe_main, type = "ar2"), 4), "\n")

# ===================================================================
cat("\n=== Save results ===\n")
# ===================================================================

# Event study data for figure
write_csv(es_df, "../data/event_study.csv")
cat("  Saved event_study.csv\n")

# Save all model objects for tables
results_main <- list(
  cs_out     = cs_out,
  cs_overall = cs_overall,
  cs_dynamic = cs_dynamic,
  cs_group   = cs_group,
  twfe_main  = twfe_main,
  panel_main = panel_main  # for N, summary stats in tables
)
saveRDS(results_main, "../data/results_main.rds")
cat("  Saved results_main.rds\n")

# ===================================================================
cat("\n=== Writing diagnostics.json ===\n")
# ===================================================================

# Count treated units (unique states that are treated at some point in sample)
n_treated <- n_distinct(panel_main$state_abbr[panel_main$treated == 1])

# Count pre-treatment periods across cohorts
# For each cohort g, pre-periods = number of years < g in the data
pre_periods_by_cohort <- panel_main %>%
  distinct(state_abbr, ebt_year) %>%
  mutate(n_pre = pmax(0, ebt_year - min(panel_main$year))) %>%
  pull(n_pre)

min_pre <- min(pre_periods_by_cohort)
max_pre <- max(pre_periods_by_cohort)
mean_pre <- mean(pre_periods_by_cohort)

# Cohort distribution
cohort_dist <- panel_main %>%
  distinct(state_abbr, ebt_year) %>%
  count(ebt_year)

diag <- list(
  n_obs      = nrow(panel_main),
  n_states   = n_distinct(panel_main$state_abbr),
  n_treated  = n_treated,
  n_clusters = n_distinct(panel_main$state_id),
  n_pre_min  = min_pre,
  n_pre_max  = max_pre,
  n_pre_mean = round(mean_pre, 1),
  year_range = c(min(panel_main$year), max(panel_main$year)),
  cohorts    = setNames(cohort_dist$n, cohort_dist$ebt_year),
  cs_att     = round(cs_overall$overall.att, 4),
  cs_se      = round(cs_overall$overall.se, 4),
  twfe_coef  = round(coef(twfe_main)["treated"], 4),
  twfe_se    = round(se(twfe_main)["treated"], 4),
  estimator  = "Callaway-Sant'Anna (2021)",
  control_group = "not-yet-treated",
  outcome    = "drug_death_rate (age-adjusted per 100k)"
)

jsonlite::write_json(diag, "../data/diagnostics.json", pretty = TRUE, auto_unbox = TRUE)
cat("  Saved diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
