# =============================================================================
# 03_main_analysis.R — Event study + 2SLS: OxyContin share → labor outcomes
# =============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
message(sprintf("Panel: %d rows, %d counties", nrow(panel), uniqueN(panel$fips)))

# ─────────────────────────────────────────────────────────────────────────────
# 1. Event study: OxyContin share × year → log employment (prime-age)
# ─────────────────────────────────────────────────────────────────────────────
message("Running event study regressions...")

# Prime-age workers (25-44)
prime <- panel[age_group == "prime_age" & year %in% 2005:2019]

# Drop 2009 as reference year
prime[, event_time_factor := factor(event_time)]

# Main event study: interaction of continuous OxyContin share × year dummies
# Controls: total oxycodone per capita × year (absorbs overall prescribing intensity)
es_emp <- feols(
  log_emp ~ i(event_time, oxy_share, ref = -1) +
    i(event_time, total_pills_pc, ref = -1) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

es_earn <- feols(
  log_earn ~ i(event_time, oxy_share, ref = -1) +
    i(event_time, total_pills_pc, ref = -1) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

es_sep <- feols(
  sep_rate ~ i(event_time, oxy_share, ref = -1) +
    i(event_time, total_pills_pc, ref = -1) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

es_hire <- feols(
  hire_rate ~ i(event_time, oxy_share, ref = -1) +
    i(event_time, total_pills_pc, ref = -1) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# ─────────────────────────────────────────────────────────────────────────────
# 2. Static DiD: pooled pre/post effect
# ─────────────────────────────────────────────────────────────────────────────
message("Running static DiD regressions...")

# Main specification: OxyContin share × post
static_emp <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

static_earn <- feols(
  log_earn ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

static_sep <- feols(
  sep_rate ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

static_hire <- feols(
  hire_rate ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# ─────────────────────────────────────────────────────────────────────────────
# 3. Heterogeneity: all-ages vs prime-age, by age group
# ─────────────────────────────────────────────────────────────────────────────
message("Running heterogeneity by age group...")

# All ages
all_ages <- panel[age_group == "all" & year %in% 2005:2019]
static_emp_all <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = all_ages,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# Older workers (45-64) — less affected, placebo-like
older <- panel[age_group == "older" & year %in% 2005:2019]
static_emp_older <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = older,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# Young workers (14-24) — potentially affected via gateway/environment
young <- panel[age_group == "young" & year %in% 2005:2019]
static_emp_young <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = young,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# ─────────────────────────────────────────────────────────────────────────────
# 4. Save results and diagnostics
# ─────────────────────────────────────────────────────────────────────────────
message("Saving results...")

# Print key results
message("\n=== MAIN RESULTS (Prime-age 25-44) ===")
message("Static DiD: OxyContin share × post")
message(sprintf("  Employment: β = %.4f (SE = %.4f)", coef(static_emp)["oxy_share_post"],
                se(static_emp)["oxy_share_post"]))
message(sprintf("  Earnings:   β = %.4f (SE = %.4f)", coef(static_earn)["oxy_share_post"],
                se(static_earn)["oxy_share_post"]))
message(sprintf("  Separations:β = %.4f (SE = %.4f)", coef(static_sep)["oxy_share_post"],
                se(static_sep)["oxy_share_post"]))
message(sprintf("  Hires:      β = %.4f (SE = %.4f)", coef(static_hire)["oxy_share_post"],
                se(static_hire)["oxy_share_post"]))

# Save for table generation
save(es_emp, es_earn, es_sep, es_hire,
     static_emp, static_earn, static_sep, static_hire,
     static_emp_all, static_emp_older, static_emp_young,
     file = "../data/main_results.RData")

# Diagnostics for validator
n_counties <- uniqueN(prime$fips)
n_states <- uniqueN(prime$state_fips)
n_pre <- length(unique(prime[year < 2010]$year))
n_obs <- nrow(prime)
n_treated <- n_counties  # continuous treatment, all counties exposed

diagnostics <- list(
  n_treated = n_counties,
  n_pre = n_pre,
  n_obs = n_obs,
  n_clusters = n_states,
  n_post = length(unique(prime[year >= 2010]$year)),
  instrument_mean = mean(prime[year == 2009]$oxy_share),
  instrument_sd = sd(prime[year == 2009]$oxy_share)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

message("\n=== DIAGNOSTICS ===")
message(sprintf("Counties: %d, States: %d, Pre-periods: %d, Obs: %d",
                n_counties, n_states, n_pre, n_obs))

# Pre-treatment SDs for SDE computation
pre_sd <- prime[year < 2010, .(
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  sd_log_earn = sd(log_earn, na.rm = TRUE),
  sd_sep_rate = sd(sep_rate, na.rm = TRUE),
  sd_hire_rate = sd(hire_rate, na.rm = TRUE)
)]
fwrite(pre_sd, "../data/pre_treatment_sd.csv")
message(sprintf("Pre-treatment SD(log_emp) = %.4f", pre_sd$sd_log_emp))

message("\n=== Analysis complete ===")
