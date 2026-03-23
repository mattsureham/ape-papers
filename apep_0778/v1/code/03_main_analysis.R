## =============================================================================
## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
## apep_0778
## =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("../data/analysis_panel.rds")

## ---- Step 1: CS-DiD on SNAP participation rate ----
cat("\n=== Step 1: CS-DiD on SNAP participation rate ===\n")

## Outcome: snap_rate (SNAP households / total households)
## Only cohorts with first_treat >= 2006 have pre-treatment periods in ACS data

cs_rate <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)

cat(sprintf("  Group-time ATTs estimated: %d\n", length(cs_rate$att)))

## Aggregate
agg_rate <- aggte(cs_rate, type = "simple")
cat(sprintf("  Overall ATT (SNAP rate): %.4f (SE: %.4f)\n",
            agg_rate$overall.att, agg_rate$overall.se))
cat(sprintf("  Interpretation: %.1f percentage point change in SNAP rate\n",
            agg_rate$overall.att * 100))

## Event study
es_rate <- aggte(cs_rate, type = "dynamic", min_e = -8, max_e = 10)
es_df <- data.frame(
  event_time = es_rate$egt,
  att = es_rate$att.egt,
  se = es_rate$se.egt,
  ci_lower = es_rate$att.egt - 1.96 * es_rate$se.egt,
  ci_upper = es_rate$att.egt + 1.96 * es_rate$se.egt
)
cat("\n  Event study:\n")
print(es_df)

## Group-level
agg_group <- aggte(cs_rate, type = "group")
group_df <- data.frame(
  group = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt
)
cat("\n  Group ATTs:\n")
print(group_df)

## ---- Step 2: CS-DiD on log SNAP households ----
cat("\n=== Step 2: CS-DiD on log(SNAP households) ===\n")

cs_log <- att_gt(
  yname = "log_snap_hh",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)

agg_log <- aggte(cs_log, type = "simple")
cat(sprintf("  Overall ATT (log SNAP HH): %.4f (SE: %.4f)\n",
            agg_log$overall.att, agg_log$overall.se))
cat(sprintf("  Interpretation: %.1f%% change in SNAP households\n",
            (exp(agg_log$overall.att) - 1) * 100))

es_log <- aggte(cs_log, type = "dynamic", min_e = -8, max_e = 10)

## ---- Step 3: TWFE ----
cat("\n=== Step 3: TWFE comparison ===\n")

twfe_rate <- feols(snap_rate ~ post | state_id + year, data = df, cluster = ~state_abbr)
cat("  TWFE (SNAP rate):\n")
print(summary(twfe_rate))

twfe_log <- feols(log_snap_hh ~ post | state_id + year, data = df, cluster = ~state_abbr)
cat("  TWFE (log SNAP HH):\n")
print(summary(twfe_log))

## ---- Step 4: Save results ----
cat("\n=== Step 4: Save results ===\n")

results <- list(
  cs_rate = cs_rate,
  agg_rate = agg_rate,
  es_rate = es_rate,
  es_df = es_df,
  agg_group = agg_group,
  group_df = group_df,
  cs_log = cs_log,
  agg_log = agg_log,
  es_log = es_log,
  twfe_rate = twfe_rate,
  twfe_log = twfe_log
)

saveRDS(results, "../data/main_results.rds")

## Diagnostics for validator
## Count cohorts that have pre-treatment periods
cohort_years <- unique(df$first_treat[df$first_treat >= 2006])
all_years <- sort(unique(df$year))
n_pre_per_cohort <- sapply(cohort_years, function(g) sum(all_years < g))

diagnostics <- list(
  n_treated = n_distinct(df$state_abbr[df$treated == 1]),
  n_pre = as.integer(median(n_pre_per_cohort)),
  n_obs = nrow(df),
  overall_att = agg_rate$overall.att,
  overall_se = agg_rate$overall.se,
  sd_y = sd(df$snap_rate, na.rm = TRUE)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("  Saved: main_results.rds, diagnostics.json\n")
cat("  DONE.\n")
