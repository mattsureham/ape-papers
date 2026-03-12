# ==============================================================================
# 03_main_analysis.R — Main DiD regressions
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

source("00_packages.R")

ratio_panel <- readRDS("../data/ratio_panel.rds")
triple_panel <- readRDS("../data/triple_panel.rds")
age_panel <- readRDS("../data/age_panel.rds")
ratio_panel_precovid <- readRDS("../data/ratio_panel_precovid.rds")

# ==============================================================================
# 1. STATE-LEVEL AGGREGATION (more power, fewer suppression issues)
# ==============================================================================

state_panel <- ratio_panel %>%
  group_by(state_abbr, state_fips, yq, t, first_treat_yq, sales_tax_rate) %>%
  summarise(
    retail_emp = sum(retail_emp, na.rm = TRUE),
    wh_emp = sum(wh_emp, na.rm = TRUE),
    retail_jbgn = sum(retail_jbgn, na.rm = TRUE),
    retail_jbls = sum(retail_jbls, na.rm = TRUE),
    wh_jbgn = sum(wh_jbgn, na.rm = TRUE),
    wh_jbls = sum(wh_jbls, na.rm = TRUE),
    n_counties = n(),
    .groups = "drop"
  ) %>%
  filter(retail_emp > 0 & wh_emp > 0) %>%
  mutate(
    log_ratio = log(retail_emp / wh_emp),
    log_retail = log(retail_emp),
    log_wh = log(wh_emp),
    retail_share = retail_emp / (retail_emp + wh_emp),
    retail_creation_rate = retail_jbgn / retail_emp,
    retail_destruction_rate = retail_jbls / retail_emp,
    wh_creation_rate = wh_jbgn / wh_emp,
    wh_destruction_rate = wh_jbls / wh_emp
  )

# State panel pre-COVID
state_precovid <- state_panel %>% filter(yq <= 20194)

cat("State panel:", nrow(state_panel), "state-quarters,",
    n_distinct(state_panel$state_abbr), "states\n")

# ==============================================================================
# 2. CALLAWAY-SANT'ANNA DiD — Main results
# ==============================================================================

# CS-DiD requires: yname, tname, idname, gname (first treatment period)
# Need numeric id for state
state_panel <- state_panel %>%
  mutate(state_id = as.integer(factor(state_abbr)))

state_precovid <- state_precovid %>%
  mutate(state_id = as.integer(factor(state_abbr)))

# --- Main outcome: log(retail/warehouse ratio) ---
cat("\n=== CS-DiD: Log Retail/Warehouse Ratio ===\n")
cs_ratio <- att_gt(
  yname = "log_ratio",
  tname = "t",
  idname = "state_id",
  gname = "first_treat_yq",
  data = state_panel %>%
    mutate(first_treat_yq = ifelse(first_treat_yq == 0, 0,
           # Convert YYYY*10+Q to t index
           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

# Aggregate: overall ATT
agg_ratio <- aggte(cs_ratio, type = "simple")
cat("Overall ATT (log ratio):", round(agg_ratio$overall.att, 4),
    "SE:", round(agg_ratio$overall.se, 4), "\n")

# Event study
es_ratio <- aggte(cs_ratio, type = "dynamic", min_e = -8, max_e = 12)
cat("Event study computed.\n")

# --- Log retail employment ---
cat("\n=== CS-DiD: Log Retail Employment ===\n")
cs_retail <- att_gt(
  yname = "log_retail",
  tname = "t",
  idname = "state_id",
  gname = "first_treat_yq",
  data = state_panel %>%
    mutate(first_treat_yq = ifelse(first_treat_yq == 0, 0,
           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_retail <- aggte(cs_retail, type = "simple")
cat("ATT (log retail):", round(agg_retail$overall.att, 4),
    "SE:", round(agg_retail$overall.se, 4), "\n")

es_retail <- aggte(cs_retail, type = "dynamic", min_e = -8, max_e = 12)

# --- Log warehouse employment ---
cat("\n=== CS-DiD: Log Warehouse Employment ===\n")
cs_wh <- att_gt(
  yname = "log_wh",
  tname = "t",
  idname = "state_id",
  gname = "first_treat_yq",
  data = state_panel %>%
    mutate(first_treat_yq = ifelse(first_treat_yq == 0, 0,
           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_wh <- aggte(cs_wh, type = "simple")
cat("ATT (log warehouse):", round(agg_wh$overall.att, 4),
    "SE:", round(agg_wh$overall.se, 4), "\n")

es_wh <- aggte(cs_wh, type = "dynamic", min_e = -8, max_e = 12)

# ==============================================================================
# 3. TWFE (Sun-Abraham) for comparison
# ==============================================================================

cat("\n=== Sun-Abraham TWFE ===\n")

state_panel_sa <- state_panel %>%
  mutate(
    first_treat_t = ifelse(first_treat_yq == 0, 10000,  # Never-treated
           (floor(first_treat_yq / 10) - 2014) * 4 + first_treat_yq %% 10)
  )

# Log ratio
sa_ratio <- feols(
  log_ratio ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)
cat("Sun-Abraham ATT (log ratio):\n")
summary(sa_ratio)

# Log retail
sa_retail <- feols(
  log_retail ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)

# Log warehouse
sa_wh <- feols(
  log_wh ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)

# ==============================================================================
# 4. TRIPLE DIFFERENCE: Retail vs Non-Tradeable
# ==============================================================================

cat("\n=== Triple Difference: Retail vs Healthcare/Education ===\n")

# State-industry-quarter panel
state_triple <- triple_panel %>%
  group_by(state_abbr, state_fips, yq, t, first_treat_yq,
           ind_label, treated_sector) %>%
  summarise(
    total_emp = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(total_emp > 0) %>%
  mutate(
    log_emp = log(total_emp),
    state_id = as.integer(factor(state_abbr)),
    post = yq >= first_treat_yq & first_treat_yq > 0,
    treated_x_post = treated_sector * post
  )

# DDD: state + time + sector FE, interaction is the treatment effect
ddd <- feols(
  log_emp ~ treated_x_post | state_abbr^ind_label + yq^ind_label + state_abbr^yq,
  data = state_triple,
  cluster = ~state_abbr
)
cat("DDD coefficient:\n")
summary(ddd)

# ==============================================================================
# 5. FIRM DYNAMICS
# ==============================================================================

cat("\n=== Firm Dynamics ===\n")

# Retail job creation rate
sa_retail_creation <- feols(
  retail_creation_rate ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)

# Retail job destruction rate
sa_retail_destruction <- feols(
  retail_destruction_rate ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)

# Warehouse creation rate
sa_wh_creation <- feols(
  wh_creation_rate ~ sunab(first_treat_t, t) | state_id + t,
  data = state_panel_sa,
  cluster = ~state_id
)

# ==============================================================================
# 6. DOSE-RESPONSE: Tax rate intensity
# ==============================================================================

cat("\n=== Dose-Response: Tax Rate ===\n")

state_panel_dose <- state_panel_sa %>%
  mutate(
    post = t >= first_treat_t,
    tax_x_post = sales_tax_rate * post
  )

dose_ratio <- feols(
  log_ratio ~ tax_x_post | state_id + t,
  data = state_panel_dose %>% filter(first_treat_t < 10000 | sales_tax_rate == 0),
  cluster = ~state_id
)
cat("Dose-response (tax rate × post):\n")
summary(dose_ratio)

# ==============================================================================
# 7. DIAGNOSTICS for validator
# ==============================================================================

diagnostics <- list(
  n_treated = n_distinct(state_panel$state_abbr[state_panel$first_treat_yq > 0]),
  n_pre = length(unique(state_panel$t[state_panel$t < 19])),  # Pre Q3 2018
  n_obs = nrow(state_panel),
  n_states = n_distinct(state_panel$state_abbr),
  n_counties_ratio = n_distinct(ratio_panel$county_fips),
  n_county_quarters = nrow(ratio_panel),
  att_ratio = round(agg_ratio$overall.att, 4),
  se_ratio = round(agg_ratio$overall.se, 4),
  att_retail = round(agg_retail$overall.att, 4),
  att_wh = round(agg_wh$overall.att, 4)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written.\n")

# ==============================================================================
# 8. SAVE RESULTS
# ==============================================================================

results <- list(
  cs_ratio = cs_ratio, cs_retail = cs_retail, cs_wh = cs_wh,
  agg_ratio = agg_ratio, agg_retail = agg_retail, agg_wh = agg_wh,
  es_ratio = es_ratio, es_retail = es_retail, es_wh = es_wh,
  sa_ratio = sa_ratio, sa_retail = sa_retail, sa_wh = sa_wh,
  ddd = ddd, dose_ratio = dose_ratio,
  sa_retail_creation = sa_retail_creation,
  sa_retail_destruction = sa_retail_destruction,
  sa_wh_creation = sa_wh_creation,
  state_panel = state_panel,
  state_panel_sa = state_panel_sa,
  diagnostics = diagnostics
)

saveRDS(results, "../data/results_main.rds")
cat("Main results saved.\n")
