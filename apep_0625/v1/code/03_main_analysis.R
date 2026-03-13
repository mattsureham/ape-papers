# =============================================================================
# 03_main_analysis.R — Primary estimation: CS-DiD + event studies
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
ban_dates <- readRDS("../data/ban_dates.rds")

cat("Panel dimensions:", nrow(panel), "obs,",
    n_distinct(panel$unit_id), "units,",
    n_distinct(panel$time_int), "periods\n")

# =============================================================================
# 1. State-level aggregation for CS-DiD
# =============================================================================
# Aggregate to state×quarter level (across industries) for the main spec
state_qtr <- panel %>%
  group_by(state_fips, year, quarter, yq, time_int, first_treat_yq, first_treat_int, treated) %>%
  summarise(
    earn_gap_log = weighted.mean(earn_gap_log, total_emp, na.rm = TRUE),
    earn_gap_ratio = weighted.mean(earn_gap_ratio, total_emp, na.rm = TRUE),
    female_earn = weighted.mean(EarnHirNS_Female, Emp_Female, na.rm = TRUE),
    male_earn = weighted.mean(EarnHirNS_Male, Emp_Male, na.rm = TRUE),
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Numeric state ID for CS-DiD
 mutate(state_id = as.numeric(as.factor(state_fips)))

cat("State-quarter panel:", nrow(state_qtr), "obs\n")
cat("Treated states:", sum(state_qtr$treated & state_qtr$time_int == 1), "\n")
cat("Never-treated states:", sum(!state_qtr$treated & state_qtr$time_int == 1), "\n")

# =============================================================================
# 2. Callaway-Sant'Anna: Gender earnings gap
# =============================================================================
cat("\n=== Running CS-DiD on gender earnings gap (log) ===\n")

cs_gap <- att_gt(
  yname = "earn_gap_log",
  tname = "time_int",
  idname = "state_id",
  gname = "first_treat_int",
  data = state_qtr,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cat("CS-DiD completed. Number of group-time ATTs:", length(cs_gap$att), "\n")

# Overall ATT
agg_simple <- aggte(cs_gap, type = "simple", na.rm = TRUE)
cat("\nOverall ATT (simple):\n")
summary(agg_simple)

# Group-level ATT (by cohort)
agg_group <- aggte(cs_gap, type = "group", na.rm = TRUE)
cat("\nGroup-level ATT:\n")
summary(agg_group)

# Dynamic/event-study ATT
agg_dynamic <- aggte(cs_gap, type = "dynamic", min_e = -12, max_e = 12, na.rm = TRUE)
cat("\nDynamic ATT (event study):\n")
summary(agg_dynamic)

# =============================================================================
# 3. CS-DiD: Female new-hire earnings (levels)
# =============================================================================
cat("\n=== Running CS-DiD on female new-hire earnings (log) ===\n")

state_qtr <- state_qtr %>%
  mutate(log_female_earn = log(female_earn))

cs_female <- att_gt(
  yname = "log_female_earn",
  tname = "time_int",
  idname = "state_id",
  gname = "first_treat_int",
  data = state_qtr,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_female_simple <- aggte(cs_female, type = "simple", na.rm = TRUE)
cat("Female earnings ATT:\n")
summary(agg_female_simple)

agg_female_dynamic <- aggte(cs_female, type = "dynamic", min_e = -12, max_e = 12, na.rm = TRUE)

# =============================================================================
# 4. TWFE as robustness (with Sun-Abraham correction)
# =============================================================================
cat("\n=== TWFE with fixest (Sun-Abraham) ===\n")

# Stacked long panel at state×industry×quarter level
panel <- panel %>%
  mutate(state_num = as.numeric(as.factor(state_fips)))

# Sun-Abraham event study
sa_es <- feols(
  earn_gap_log ~ sunab(first_treat_yq, yq) |
    unit_id + yq,
  data = panel %>% filter(first_treat_yq == 0 | first_treat_yq > 0),
  cluster = ~state_fips,
  weights = ~total_emp
)

cat("Sun-Abraham event study:\n")
summary(sa_es)

# Simple TWFE DiD
twfe <- feols(
  earn_gap_log ~ post |
    unit_id + yq,
  data = panel,
  cluster = ~state_fips,
  weights = ~total_emp
)

cat("\nTWFE DiD:\n")
summary(twfe)

# =============================================================================
# 5. Placebo: Government sector (NAICS 92 — exempt from private bans)
# =============================================================================
cat("\n=== Placebo: Government sector ===\n")

gov_panel <- panel %>% filter(industry == "92")

if (nrow(gov_panel) > 100) {
  twfe_gov <- feols(
    earn_gap_log ~ post |
      state_fips + yq,
    data = gov_panel,
    cluster = ~state_fips
  )
  cat("Government placebo (should be ~0):\n")
  summary(twfe_gov)
} else {
  cat("Insufficient government sector observations.\n")
}

# =============================================================================
# 6. Save all results
# =============================================================================
results <- list(
  cs_gap = cs_gap,
  agg_simple = agg_simple,
  agg_group = agg_group,
  agg_dynamic = agg_dynamic,
  cs_female = cs_female,
  agg_female_simple = agg_female_simple,
  agg_female_dynamic = agg_female_dynamic,
  sa_es = sa_es,
  twfe = twfe,
  state_qtr = state_qtr,
  n_treated = n_distinct(panel$state_fips[panel$treated]),
  n_control = n_distinct(panel$state_fips[!panel$treated]),
  n_obs = nrow(panel),
  n_state_qtr = nrow(state_qtr)
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
# n_treated counts state×industry units (the unit of observation in the panel)
diagnostics <- list(
  n_treated = n_distinct(panel$unit_id[panel$treated]),
  n_pre = length(unique(state_qtr$time_int[state_qtr$yq < 2017.75])),
  n_obs = nrow(panel)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Overall ATT on gender gap:", round(agg_simple$overall.att, 4),
    "(SE:", round(agg_simple$overall.se, 4), ")\n")
cat("Diagnostics: n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre,
    ", n_obs =", diagnostics$n_obs, "\n")
