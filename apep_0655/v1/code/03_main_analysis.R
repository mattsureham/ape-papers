## 03_main_analysis.R — Main DDD estimation
## apep_0655: The Employer Side of Deportation

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/panel_main.rds")

# ------------------------------------------------------------------
# 1. Main DDD specification (fixest)
# ------------------------------------------------------------------
# Y_{c,q,e} = alpha_c + gamma_q + delta_e + beta(Post_SC * Hispanic) + eps
# With county-ethnicity FE, quarter FE, and county-quarter FE
# Triple-diff: Hispanic vs Non-Hispanic x Pre vs Post SC activation
# ------------------------------------------------------------------

cat("=== Running main DDD regressions ===\n")

# Create panel ID for county-ethnicity
panel <- panel %>%
  mutate(
    county_eth = paste0(county_fips, "_", ethnicity),
    county_qtr = paste0(county_fips, "_", cal_q)
  )

# Specification 1: Basic DDD with county-ethnicity and quarter FE
m1_emp <- feols(ln_emp ~ treat_ddd | county_eth + cal_q,
                data = panel, cluster = ~state_fips)
m1_hir <- feols(ln_hir ~ treat_ddd | county_eth + cal_q,
                data = panel, cluster = ~state_fips)
m1_sep <- feols(ln_sep ~ treat_ddd | county_eth + cal_q,
                data = panel, cluster = ~state_fips)
m1_earn <- feols(ln_earn ~ treat_ddd | county_eth + cal_q,
                 data = panel, cluster = ~state_fips)

cat("\n--- Specification 1: County-ethnicity + Quarter FE ---\n")
cat("Employment:\n"); print(summary(m1_emp))
cat("Hiring:\n"); print(summary(m1_hir))

# Specification 2: Saturated DDD with county-quarter FE
# This absorbs all county-time shocks, leaving only the ethnic differential
# Filter to observations with non-missing outcomes for each model
panel_emp <- panel %>% filter(!is.na(ln_emp))
panel_earn <- panel %>% filter(!is.na(ln_earn) & is.finite(ln_earn))

m2_emp <- feols(ln_emp ~ treat_ddd | county_eth + county_qtr,
                data = panel_emp, cluster = ~state_fips)
m2_hir <- feols(ln_hir ~ treat_ddd | county_eth + county_qtr,
                data = panel_emp, cluster = ~state_fips)
m2_sep <- feols(ln_sep ~ treat_ddd | county_eth + county_qtr,
                data = panel_emp, cluster = ~state_fips)
# Earnings: use county_eth + cal_q FE (county_qtr creates too many singletons)
m2_earn <- feols(ln_earn ~ treat_ddd | county_eth + cal_q,
                 data = panel_earn, cluster = ~state_fips)

cat("\n--- Specification 2: County-ethnicity + County-quarter FE ---\n")
cat("Employment:\n"); print(summary(m2_emp))
cat("Hiring:\n"); print(summary(m2_hir))

# Specification 3: Firm dynamics (job creation/destruction)
m2_jgn <- feols(ln_frm_job_gn ~ treat_ddd | county_eth + county_qtr,
                data = panel_emp, cluster = ~state_fips)
m2_jls <- feols(ln_frm_job_ls ~ treat_ddd | county_eth + county_qtr,
                data = panel_emp, cluster = ~state_fips)

cat("\n--- Firm Dynamics ---\n")
cat("Job Creation:\n"); print(summary(m2_jgn))
cat("Job Destruction:\n"); print(summary(m2_jls))

# ------------------------------------------------------------------
# 2. Event study (DDD event study)
# ------------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Trim event time to [-8, +8] quarters
panel_es <- panel %>%
  filter(event_q >= -8 & event_q <= 8)

# Event study: interact event_q dummies with Hispanic indicator
# Reference period: event_q = -1
panel_es <- panel_es %>%
  mutate(event_q_f = factor(event_q))

# Event study for employment
es_emp <- feols(ln_emp ~ i(event_q, hispanic, ref = -1) | county_eth + county_qtr,
                data = panel_es, cluster = ~state_fips)
cat("Event study (employment):\n")
print(summary(es_emp))

# Event study for hiring
es_hir <- feols(ln_hir ~ i(event_q, hispanic, ref = -1) | county_eth + county_qtr,
                data = panel_es, cluster = ~state_fips)

# Event study for separations
es_sep <- feols(ln_sep ~ i(event_q, hispanic, ref = -1) | county_eth + county_qtr,
                data = panel_es, cluster = ~state_fips)

# Event study for earnings (use county_eth + cal_q since county_qtr creates singletons)
panel_es_earn <- panel_es %>% filter(!is.na(ln_earn) & is.finite(ln_earn))
es_earn <- feols(ln_earn ~ i(event_q, hispanic, ref = -1) | county_eth + cal_q,
                 data = panel_es_earn, cluster = ~state_fips)

# ------------------------------------------------------------------
# 3. Save results
# ------------------------------------------------------------------
cat("\n=== Saving results ===\n")

results <- list(
  # Main DDD
  m1_emp = m1_emp, m1_hir = m1_hir, m1_sep = m1_sep, m1_earn = m1_earn,
  m2_emp = m2_emp, m2_hir = m2_hir, m2_sep = m2_sep, m2_earn = m2_earn,
  m2_jgn = m2_jgn, m2_jls = m2_jls,
  # Event studies
  es_emp = es_emp, es_hir = es_hir, es_sep = es_sep, es_earn = es_earn
)
saveRDS(results, "../data/main_results.rds")

# ------------------------------------------------------------------
# 4. Diagnostics for validator
# ------------------------------------------------------------------
cat("=== Writing diagnostics ===\n")

n_treated <- n_distinct(panel$county_fips[panel$post_sc == 1])
n_pre <- length(unique(panel$cal_q[panel$event_q < 0]))
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = n_distinct(panel$county_fips),
  n_states = n_distinct(panel$state_fips),
  outcomes = c("ln_emp", "ln_hir", "ln_sep", "ln_earn", "ln_frm_job_gn", "ln_frm_job_ls")
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("  n_treated: %d counties\n", n_treated))
cat(sprintf("  n_pre: %d quarters\n", n_pre))
cat(sprintf("  n_obs: %s\n", format(n_obs, big.mark = ",")))
cat("=== Main analysis complete ===\n")
