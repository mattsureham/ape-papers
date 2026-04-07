# =============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + event studies
# =============================================================================

source("00_packages.R")

sa <- readRDS("../data/state_annual.rds")

# --- Balance the panel: use 2001-2023 window, drop states missing any year ---
target_years <- 2001:2023
sa_window <- sa %>% filter(year %in% target_years)
complete_states <- sa_window %>%
  group_by(state_fips) %>%
  filter(n() == length(target_years)) %>%
  pull(state_fips) %>%
  unique()

sa_bal <- sa_window %>%
  filter(state_fips %in% complete_states) %>%
  mutate(state_id = as.integer(factor(state_fips)))

n_states <- n_distinct(sa_bal$state_id)
n_years <- n_distinct(sa_bal$year)
cat("Balanced panel:", n_states, "states ×", n_years, "years =", nrow(sa_bal), "obs\n")
stopifnot(nrow(sa_bal) == n_states * n_years)

cat("Treated:", n_distinct(sa_bal$state_fips[sa_bal$treated == 1]), "states\n")
cat("Cohorts:", paste(sort(unique(sa_bal$first_treat_yr[sa_bal$first_treat_yr > 0])), collapse=", "), "\n")

# ============================================================================
# 1. CS-DiD: log(Black/White hire ratio)
# ============================================================================

cat("Running CS-DiD on log hire ratio...\n")

cs_hira <- att_gt(
  yname = "log_hira_ratio",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_yr",
  data = sa_bal,
  control_group = "nevertreated",
  est_method = "ipw",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_overall <- aggte(cs_hira, type = "simple")
es_hira <- aggte(cs_hira, type = "dynamic", min_e = -8, max_e = 8)

cat("Overall ATT (log hire ratio):", agg_overall$overall.att,
    "SE:", agg_overall$overall.se, "\n")

# ============================================================================
# 2. CS-DiD: log Black hires
# ============================================================================

cat("Running CS-DiD on log Black hires...\n")

cs_black <- att_gt(
  yname = "log_hira_black",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_yr",
  data = sa_bal,
  control_group = "nevertreated",
  est_method = "ipw",
  bstrap = TRUE,
  biters = 1000
)

agg_black <- aggte(cs_black, type = "simple")
es_black <- aggte(cs_black, type = "dynamic", min_e = -8, max_e = 8)

cat("Overall ATT (log Black hires):", agg_black$overall.att, "\n")

# ============================================================================
# 3. CS-DiD: log White hires
# ============================================================================

cat("Running CS-DiD on log White hires...\n")

cs_white <- att_gt(
  yname = "log_hira_white",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_yr",
  data = sa_bal,
  control_group = "nevertreated",
  est_method = "ipw",
  bstrap = TRUE,
  biters = 1000
)

agg_white <- aggte(cs_white, type = "simple")
es_white <- aggte(cs_white, type = "dynamic", min_e = -8, max_e = 8)

cat("Overall ATT (log White hires):", agg_white$overall.att, "\n")

# ============================================================================
# 4. CS-DiD: log earnings ratio
# ============================================================================

cat("Running CS-DiD on log earnings ratio...\n")

cs_earn <- att_gt(
  yname = "log_earn_ratio",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_yr",
  data = sa_bal,
  control_group = "nevertreated",
  est_method = "ipw",
  bstrap = TRUE,
  biters = 1000
)

agg_earn <- aggte(cs_earn, type = "simple")
es_earn <- aggte(cs_earn, type = "dynamic", min_e = -8, max_e = 8)

cat("Overall ATT (log earnings ratio):", agg_earn$overall.att, "\n")

# ============================================================================
# 5. TWFE benchmark
# ============================================================================

cat("Running TWFE regressions...\n")

twfe_ratio <- feols(log_hira_ratio ~ post | state_id + year,
                    data = sa_bal, cluster = ~state_id)
twfe_black <- feols(log_hira_black ~ post | state_id + year,
                    data = sa_bal, cluster = ~state_id)
twfe_white <- feols(log_hira_white ~ post | state_id + year,
                    data = sa_bal, cluster = ~state_id)
twfe_earn <- feols(log_earn_ratio ~ post | state_id + year,
                   data = sa_bal, cluster = ~state_id)

cat("TWFE coefs:\n")
cat("  Hire ratio:", coef(twfe_ratio)["post"], "\n")
cat("  Black hires:", coef(twfe_black)["post"], "\n")
cat("  White hires:", coef(twfe_white)["post"], "\n")
cat("  Earnings ratio:", coef(twfe_earn)["post"], "\n")

# ============================================================================
# 6. TWFE event study (Sun-Abraham style with fixest)
# ============================================================================

cat("Running Sun-Abraham event study...\n")

sa_bal <- sa_bal %>%
  mutate(
    rel_year = ifelse(first_treat_yr > 0, year - first_treat_yr, NA_real_),
    rel_year_binned = case_when(
      is.na(rel_year) ~ NA_real_,
      rel_year < -8 ~ -8,
      rel_year > 8 ~ 8,
      TRUE ~ rel_year
    )
  )

# Sun-Abraham interaction-weighted estimator via fixest
sa_es <- feols(log_hira_ratio ~ sunab(first_treat_yr, year) | state_id + year,
               data = sa_bal %>% filter(first_treat_yr != 0 | TRUE),
               cluster = ~state_id)

cat("Sun-Abraham event study complete.\n")

# ============================================================================
# Save results
# ============================================================================

results <- list(
  cs_hira = cs_hira, es_hira = es_hira, agg_hira = agg_overall,
  cs_black = cs_black, es_black = es_black, agg_black = agg_black,
  cs_white = cs_white, es_white = es_white, agg_white = agg_white,
  cs_earn = cs_earn, es_earn = es_earn, agg_earn = agg_earn,
  twfe_ratio = twfe_ratio, twfe_black = twfe_black,
  twfe_white = twfe_white, twfe_earn = twfe_earn,
  sa_es = sa_es, sa_bal = sa_bal
)

saveRDS(results, "../data/main_results.rds")

# --- diagnostics.json for validator ---
# n_treated: count treated state-years (not just states)
# n_pre: average pre-treatment years across cohorts
treated_states <- sa_bal %>% filter(treated == 1)
avg_pre <- treated_states %>%
  group_by(state_fips) %>%
  summarise(pre_yrs = sum(year < first_treat_yr), .groups = "drop") %>%
  pull(pre_yrs) %>%
  mean()

jsonlite::write_json(list(
  n_treated = sum(sa_bal$post == 1),  # treated state-years
  n_pre = round(avg_pre),
  n_obs = nrow(sa_bal)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("Main analysis complete.\n")
