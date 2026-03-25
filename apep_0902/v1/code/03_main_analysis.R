# ============================================================================
# 03_main_analysis.R — Main DiD analysis for RTF paper
# ============================================================================

source("00_packages.R")

panel_112 <- readRDS("../data/panel_112.rds")
panel_111 <- readRDS("../data/panel_111.rds")
treatment_dates <- readRDS("../data/treatment_dates.rds")

# ============================================================================
# 1. Callaway-Sant'Anna (2021) — Main specification
# ============================================================================

cat("=== Callaway-Sant'Anna: NAICS 112 (Animal Production) ===\n")

# Balanced panel check — CS estimator works better with balanced panels
# but can handle unbalanced; let's proceed with what we have.

cs_out <- att_gt(
  yname   = "log_emp",
  tname   = "time_id",
  idname  = "county_id",
  gname   = "cohort_id",
  data    = as.data.frame(panel_112),
  control_group = "notyettreated",
  base_period = "universal",
  clustervars = "state_fips",
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  anticipation = 0
)

cat("\nGroup-time ATTs:\n")
summary(cs_out)

# Aggregate to overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT (simple):\n")
summary(cs_agg)

# Aggregate to dynamic (event study)
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 16)
cat("\nDynamic ATT (event study):\n")
summary(cs_dynamic)

# Aggregate by cohort
cs_group <- aggte(cs_out, type = "group")
cat("\nCohort-specific ATTs:\n")
summary(cs_group)

# ============================================================================
# 2. TWFE (fixest) — Comparison specification
# ============================================================================

cat("\n=== TWFE via fixest ===\n")

twfe_main <- feols(
  log_emp ~ treat_indicator | county_id + time_id,
  data = panel_112,
  cluster = ~state_fips
)
cat("\nTWFE main result:\n")
summary(twfe_main)

# ============================================================================
# 3. Sun-Abraham (2021) — Alternative heterogeneity-robust estimator
# ============================================================================

cat("\n=== Sun-Abraham via fixest::sunab ===\n")

# Need relative time variable
panel_112 <- panel_112 %>%
  mutate(
    rel_time = ifelse(cohort_id > 0, time_id - cohort_id, -Inf)
  )

sa_main <- feols(
  log_emp ~ sunab(cohort_id, time_id) | county_id + time_id,
  data = panel_112 %>% filter(cohort_id > 0 | cohort_id == 0),  # keep never-treated
  cluster = ~state_fips
)
cat("\nSun-Abraham result:\n")
summary(sa_main)

# ============================================================================
# 4. Heterogeneity by outcome (employment, hires, separations, earnings)
# ============================================================================

cat("\n=== Additional outcomes (TWFE) ===\n")

# Hires
twfe_hires <- feols(
  log(HirN) ~ treat_indicator | county_id + time_id,
  data = panel_112 %>% filter(!is.na(HirN) & HirN > 0),
  cluster = ~state_fips
)
cat("Hires:\n")
summary(twfe_hires)

# Separations
twfe_sep <- feols(
  log(Sep) ~ treat_indicator | county_id + time_id,
  data = panel_112 %>% filter(!is.na(Sep) & Sep > 0),
  cluster = ~state_fips
)
cat("Separations:\n")
summary(twfe_sep)

# Job creation
twfe_jbgn <- feols(
  log(FrmJbGn) ~ treat_indicator | county_id + time_id,
  data = panel_112 %>% filter(!is.na(FrmJbGn) & FrmJbGn > 0),
  cluster = ~state_fips
)
cat("Job Creation:\n")
summary(twfe_jbgn)

# Job destruction
twfe_jbls <- feols(
  log(FrmJbLs) ~ treat_indicator | county_id + time_id,
  data = panel_112 %>% filter(!is.na(FrmJbLs) & FrmJbLs > 0),
  cluster = ~state_fips
)
cat("Job Destruction:\n")
summary(twfe_jbls)

# Earnings
twfe_earn <- feols(
  log_earn ~ treat_indicator | county_id + time_id,
  data = panel_112 %>% filter(!is.na(log_earn)),
  cluster = ~state_fips
)
cat("Earnings:\n")
summary(twfe_earn)

# ============================================================================
# 5. Write diagnostics.json
# ============================================================================

n_treated_units <- n_distinct(panel_112$county_id[panel_112$treated_state])
n_pre <- min(
  panel_112 %>%
    filter(treated_state) %>%
    group_by(state_fips) %>%
    summarize(pre = sum(yq < first(treat_yq[!is.na(treat_yq)])), .groups = "drop") %>%
    pull(pre)
)

diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = as.integer(n_distinct(panel_112$time_id[panel_112$yq < min(treatment_dates$treat_yq)])),
  n_obs = nrow(panel_112),
  n_counties = n_distinct(panel_112$county_fips),
  n_states = n_distinct(panel_112$state_fips),
  n_clusters = n_distinct(panel_112$state_fips),
  mean_emp = round(mean(panel_112$Emp, na.rm = TRUE), 1),
  sd_emp = round(sd(panel_112$Emp, na.rm = TRUE), 1),
  sd_log_emp = round(sd(panel_112$log_emp, na.rm = TRUE), 4)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\ndiagnostics.json written.\n")

# ============================================================================
# 6. Save model objects
# ============================================================================

saveRDS(cs_out, "../data/cs_out.rds")
saveRDS(cs_agg, "../data/cs_agg.rds")
saveRDS(cs_dynamic, "../data/cs_dynamic.rds")
saveRDS(cs_group, "../data/cs_group.rds")
saveRDS(twfe_main, "../data/twfe_main.rds")
saveRDS(sa_main, "../data/sa_main.rds")
saveRDS(list(
  hires = twfe_hires,
  sep = twfe_sep,
  jbgn = twfe_jbgn,
  jbls = twfe_jbls,
  earn = twfe_earn
), "../data/twfe_outcomes.rds")

cat("\nAll model objects saved.\n")
