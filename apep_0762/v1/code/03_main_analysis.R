## =============================================================================
## 03_main_analysis.R — Callaway-Sant'Anna DiD + Event Study
## apep_0762
## =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- readRDS("../data/analysis_panel.rds")
overall_stats <- readRDS("../data/overall_stats.rds")

## ---- Step 1: Callaway-Sant'Anna ATT(g,t) ----
cat("\n=== Step 1: Callaway-Sant'Anna ATT(g,t) ===\n")

## Main specification: log(ZHVI) with never-treated as control group
cs_out <- att_gt(
  yname = "log_zhvi",
  tname = "year",
  idname = "zip_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",    # Doubly robust
  base_period = "varying"
)

cat("  ATT(g,t) estimation complete.\n")
cat(sprintf("  Number of group-time ATTs: %d\n", length(cs_out$att)))

## ---- Step 2: Aggregate to overall ATT ----
cat("\n=== Step 2: Overall ATT ===\n")

agg_simple <- aggte(cs_out, type = "simple")
cat(sprintf("  Overall ATT: %.4f (SE: %.4f)\n", agg_simple$overall.att, agg_simple$overall.se))
cat(sprintf("  Interpretation: %.1f%% change in home values\n",
            (exp(agg_simple$overall.att) - 1) * 100))

## ---- Step 3: Event study (dynamic aggregation) ----
cat("\n=== Step 3: Dynamic event study ===\n")

es <- aggte(cs_out, type = "dynamic", min_e = -10, max_e = 10)

cat("  Event study estimates:\n")
es_df <- data.frame(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt,
  ci_lower = es$att.egt - 1.96 * es$se.egt,
  ci_upper = es$att.egt + 1.96 * es$se.egt
)
print(es_df)

## ---- Step 4: Group-level ATTs ----
cat("\n=== Step 4: Group-level aggregation ===\n")

agg_group <- aggte(cs_out, type = "group")
group_df <- data.frame(
  group = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt
)
cat("  Group-level ATTs:\n")
print(group_df)

## ---- Step 5: Calendar-time aggregation ----
cat("\n=== Step 5: Calendar-time aggregation ===\n")

agg_cal <- aggte(cs_out, type = "calendar")
cal_df <- data.frame(
  year = agg_cal$egt,
  att = agg_cal$att.egt,
  se = agg_cal$se.egt
)
cat("  Calendar-time ATTs:\n")
print(cal_df)

## ---- Step 6: TWFE for comparison ----
cat("\n=== Step 6: TWFE comparison (for reference) ===\n")

twfe <- feols(log_zhvi ~ post | zip_id + year, data = df, cluster = ~zip_code)
cat("  TWFE estimate:\n")
print(summary(twfe))

## ---- Step 7: Save results ----
cat("\n=== Step 7: Save results ===\n")

results <- list(
  cs_out = cs_out,
  agg_simple = agg_simple,
  es = es,
  es_df = es_df,
  agg_group = agg_group,
  group_df = group_df,
  agg_cal = agg_cal,
  cal_df = cal_df,
  twfe = twfe
)

saveRDS(results, "../data/main_results.rds")

## Write diagnostics.json for validator
## n_pre: median number of pre-treatment periods across treated cohorts
cohort_years <- unique(df$first_treat[df$first_treat > 0])
all_years <- sort(unique(df$year))
n_pre_per_cohort <- sapply(cohort_years, function(g) sum(all_years < g))
median_n_pre <- as.integer(median(n_pre_per_cohort))

diagnostics <- list(
  n_treated = n_distinct(df$zip_code[df$treated == 1]),
  n_pre = median_n_pre,
  n_obs = nrow(df),
  overall_att = agg_simple$overall.att,
  overall_se = agg_simple$overall.se,
  n_cohorts = n_distinct(df$first_treat[df$first_treat > 0]),
  sd_y = sd(df$log_zhvi, na.rm = TRUE)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("  Saved: main_results.rds, diagnostics.json\n")
cat("  DONE.\n")
