# =============================================================================
# 03_main_analysis.R — Triple-difference estimation of Section 232 tariff effects
# =============================================================================

source("00_packages.R")

state_panel <- readRDS("../data/state_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")

# =============================================================================
# 1. State-Level DDD: Main specification
# =============================================================================
cat("=== STATE-LEVEL DDD RESULTS ===\n\n")

# Main DDD: log employment
# Y_{set} = state_edu FE + edu_time FE + state_time FE
#   + beta1 * exposure * post
#   + beta2 * exposure * post * high_edu
m1_emp <- feols(
  log_emp ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m1_emp)

# DDD: separation rate
m1_sep <- feols(
  sep_rate ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m1_sep)

# DDD: log earnings
m1_earn <- feols(
  log_earn ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m1_earn)

# DDD: hire rate
m1_hire <- feols(
  hire_rate ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m1_hire)

# =============================================================================
# 2. Education-group-specific effects (four separate coefficients)
# =============================================================================
cat("\n=== EDUCATION-SPECIFIC EFFECTS ===\n\n")

# Create education-specific interaction terms
state_panel <- state_panel %>%
  mutate(
    exp_post_E1 = exposure * post * as.integer(education == "E1"),
    exp_post_E2 = exposure * post * as.integer(education == "E2"),
    exp_post_E3 = exposure * post * as.integer(education == "E3"),
    exp_post_E4 = exposure * post * as.integer(education == "E4")
  )

m2_emp <- feols(
  log_emp ~ exp_post_E1 + exp_post_E2 + exp_post_E3 + exp_post_E4 |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m2_emp)

m2_sep <- feols(
  sep_rate ~ exp_post_E1 + exp_post_E2 + exp_post_E3 + exp_post_E4 |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m2_sep)

m2_earn <- feols(
  log_earn ~ exp_post_E1 + exp_post_E2 + exp_post_E3 + exp_post_E4 |
    state_edu + edu_time + state_time,
  data = state_panel,
  cluster = ~state_fips
)
summary(m2_earn)

# =============================================================================
# 3. County-Level DDD (preferred — richer variation)
# =============================================================================
cat("\n=== COUNTY-LEVEL DDD RESULTS ===\n\n")

# Main DDD at county level
m3_emp <- feols(
  log_emp ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)
summary(m3_emp)

m3_sep <- feols(
  sep_rate ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)
summary(m3_sep)

m3_earn <- feols(
  log_earn ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)
summary(m3_earn)

# County-level education-specific effects
county_panel <- county_panel %>%
  mutate(
    exp_post_E1 = exposure * post * as.integer(education == "E1"),
    exp_post_E2 = exposure * post * as.integer(education == "E2"),
    exp_post_E3 = exposure * post * as.integer(education == "E3"),
    exp_post_E4 = exposure * post * as.integer(education == "E4")
  )

m4_emp <- feols(
  log_emp ~ exp_post_E1 + exp_post_E2 + exp_post_E3 + exp_post_E4 |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)
summary(m4_emp)

# =============================================================================
# 4. Event Study — Quarter-by-quarter coefficients by education group
# =============================================================================
cat("\n=== EVENT STUDY ===\n\n")

# Event time: 2018Q2 = time_id 22 (since 2013Q1 = 1)
state_panel <- state_panel %>%
  mutate(event_time = time_id - 22)

# Event study separately by education group (state + time FE)
# This shows whether pre-trends are parallel within each education group
es_by_edu <- list()
for (edu in c("E1", "E2", "E3", "E4")) {
  es_by_edu[[edu]] <- feols(
    log_emp ~ i(event_time, exposure, ref = -1) |
      state_fips + time_id,
    data = filter(state_panel, education == edu),
    cluster = ~state_fips
  )
  cat("Event study for", edu, ":\n")
  print(summary(es_by_edu[[edu]]))
}

# County-level event study by education (richer variation)
county_panel <- county_panel %>%
  mutate(event_time = time_id - 22)

es_county_by_edu <- list()
for (edu in c("E1", "E2", "E3", "E4")) {
  es_county_by_edu[[edu]] <- feols(
    log_emp ~ i(event_time, exposure, ref = -1) |
      county_fips + time_id,
    data = filter(county_panel, education == edu),
    cluster = ~state_fips
  )
}

# =============================================================================
# 5. Save results and diagnostics
# =============================================================================

# Diagnostics for validation
n_treated_states <- state_panel %>%
  filter(exposure > median(exposure)) %>%
  pull(state_fips) %>%
  n_distinct()

n_pre <- state_panel %>%
  filter(post == 0) %>%
  pull(time_id) %>%
  n_distinct()

state_exposure <- readRDS("../data/state_exposure.rds")

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = nrow(state_panel),
  n_states = n_distinct(state_panel$state_fips),
  n_counties = n_distinct(county_panel$county_fips),
  n_quarters = n_distinct(state_panel$time_id),
  mean_exposure = mean(state_exposure$exposure, na.rm = TRUE),
  sd_exposure = sd(state_exposure$exposure, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save model objects
saveRDS(list(
  m1_emp = m1_emp, m1_sep = m1_sep, m1_earn = m1_earn, m1_hire = m1_hire,
  m2_emp = m2_emp, m2_sep = m2_sep, m2_earn = m2_earn,
  m3_emp = m3_emp, m3_sep = m3_sep, m3_earn = m3_earn,
  m4_emp = m4_emp,
  es_by_edu = es_by_edu, es_county_by_edu = es_county_by_edu
), "../data/main_results.rds")

cat("\nDiagnostics:\n")
print(diagnostics)
cat("\nMain analysis complete.\n")
