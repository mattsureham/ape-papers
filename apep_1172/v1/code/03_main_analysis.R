## 03_main_analysis.R — Primary DiD estimates
## apep_1172: Cage-Free Egg Mandates

source("00_packages.R")

analysis <- readRDS("../data/analysis_panel.rds")

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(analysis), "state-months\n")
cat("States:", n_distinct(analysis$state), "\n")
cat("Treated:", n_distinct(analysis$state[analysis$treated_state]), "\n")

# ============================================================
# 1. Collapse to YEARLY data for Callaway-Sant'Anna
# ============================================================

yearly <- analysis %>%
  group_by(state, state_id, year, treated_state, cohort_year) %>%
  summarise(
    avg_layers_k = mean(avg_layers_k, na.rm = TRUE),
    production_eggs = mean(production_eggs, na.rm = TRUE),
    eggs_per_100 = mean(eggs_per_100, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    ln_layers = log(avg_layers_k),
    ln_production = log(production_eggs),
    ln_eggs_per_100 = log(eggs_per_100),
    # CS gname: first treatment year (0 for never-treated)
    first_treat_year = ifelse(treated_state, cohort_year, 0),
    post = ifelse(treated_state & year >= cohort_year, 1, 0)
  ) %>%
  filter(!is.na(ln_layers))

cat("\nYearly panel:", nrow(yearly), "state-years\n")
cat("Years:", min(yearly$year), "-", max(yearly$year), "\n")
cat("Treated states:", n_distinct(yearly$state[yearly$treated_state]), "\n")
cat("Control states:", n_distinct(yearly$state[!yearly$treated_state]), "\n")

# ============================================================
# 2. Callaway-Sant'Anna — Yearly
# ============================================================

cat("\n--- Callaway-Sant'Anna: Log Layers (yearly) ---\n")

cs_layers <- att_gt(
  yname = "ln_layers",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = yearly,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cat("Group-time ATTs:\n")
summary(cs_layers)

# Aggregate: overall ATT
agg_overall_layers <- aggte(cs_layers, type = "simple")
cat("\nOverall ATT (layers):\n")
summary(agg_overall_layers)

# Event study
agg_es_layers <- aggte(cs_layers, type = "dynamic")
cat("\nEvent study (layers):\n")
summary(agg_es_layers)

# Group-specific
agg_group_layers <- aggte(cs_layers, type = "group")
cat("\nGroup ATT (layers):\n")
summary(agg_group_layers)

# --- Production ---
cat("\n--- Callaway-Sant'Anna: Log Production (yearly) ---\n")

cs_production <- att_gt(
  yname = "ln_production",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = yearly,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

agg_overall_prod <- aggte(cs_production, type = "simple")
cat("\nOverall ATT (production):\n")
summary(agg_overall_prod)
agg_es_prod <- aggte(cs_production, type = "dynamic")

# --- Eggs per 100 (productivity/placebo) ---
cat("\n--- Callaway-Sant'Anna: Log Eggs per 100 (yearly) ---\n")

cs_eggs_per <- att_gt(
  yname = "ln_eggs_per_100",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = yearly,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

agg_overall_epl <- aggte(cs_eggs_per, type = "simple")
cat("\nOverall ATT (eggs per 100):\n")
summary(agg_overall_epl)
agg_es_epl <- aggte(cs_eggs_per, type = "dynamic")

# ============================================================
# 3. TWFE with fixest (yearly)
# ============================================================

cat("\n--- TWFE (fixest, yearly) ---\n")

twfe_layers <- feols(ln_layers ~ post | state_id + year,
                     data = yearly, cluster = ~state_id)
cat("\nTWFE — Log Layers:\n")
summary(twfe_layers)

twfe_prod <- feols(ln_production ~ post | state_id + year,
                   data = yearly, cluster = ~state_id)

twfe_epl <- feols(ln_eggs_per_100 ~ post | state_id + year,
                  data = yearly, cluster = ~state_id)

# ============================================================
# 4. Sun-Abraham event study (yearly, cleaner for small samples)
# ============================================================

cat("\n--- Sun-Abraham (yearly) ---\n")

yearly_sa <- yearly %>%
  mutate(cohort = ifelse(first_treat_year == 0, Inf, first_treat_year))

sa_layers <- feols(ln_layers ~ sunab(cohort, year) | state_id + year,
                   data = yearly_sa, cluster = ~state_id)
cat("\nSun-Abraham — Log Layers:\n")
summary(sa_layers)

sa_prod <- feols(ln_production ~ sunab(cohort, year) | state_id + year,
                 data = yearly_sa, cluster = ~state_id)

# ============================================================
# 5. Save all results
# ============================================================

results <- list(
  cs_layers = cs_layers,
  cs_production = cs_production,
  cs_eggs_per = cs_eggs_per,
  agg_overall_layers = agg_overall_layers,
  agg_overall_prod = agg_overall_prod,
  agg_overall_epl = agg_overall_epl,
  agg_es_layers = agg_es_layers,
  agg_es_prod = agg_es_prod,
  agg_es_epl = agg_es_epl,
  agg_group_layers = agg_group_layers,
  twfe_layers = twfe_layers,
  twfe_prod = twfe_prod,
  twfe_epl = twfe_epl,
  sa_layers = sa_layers,
  sa_prod = sa_prod,
  yearly = yearly
)

saveRDS(results, "../data/main_results.rds")

# ============================================================
# 6. Diagnostics for validation
# ============================================================

diag <- list(
  n_treated = sum(yearly$post == 1),  # treated state-year cells contributing to ATT
  n_treated_states = n_distinct(yearly$state_id[yearly$first_treat_year > 0]),
  n_pre = length(unique(yearly$year[yearly$year < min(yearly$first_treat_year[yearly$first_treat_year > 0])])),
  n_obs = nrow(yearly),
  n_states = n_distinct(yearly$state_id),
  n_years = n_distinct(yearly$year),
  att_layers = agg_overall_layers$overall.att,
  se_layers = agg_overall_layers$overall.se,
  att_prod = agg_overall_prod$overall.att,
  se_prod = agg_overall_prod$overall.se
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("ATT (layers):", round(diag$att_layers, 4), "SE:", round(diag$se_layers, 4), "\n")
cat("ATT (production):", round(diag$att_prod, 4), "SE:", round(diag$se_prod, 4), "\n")
cat("n_treated:", diag$n_treated, "n_pre:", diag$n_pre, "n_obs:", diag$n_obs, "\n")
