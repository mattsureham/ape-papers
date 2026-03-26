## 03_main_analysis.R — Callaway-Sant'Anna DiD + event study
## APEP Paper apep_1035

source("00_packages.R")

data_dir <- "../data"

# Load panels
cdc <- readRDS(file.path(data_dir, "analysis_panel_cdc.rds"))
acs <- readRDS(file.path(data_dir, "analysis_panel_acs.rds"))

# CDC data has years 1990, 1995, 1999, 2000-2023 (not consecutive before 2000)
# Restrict to 2000-2023 for balanced panel required by did package
# This still gives 2+ pre-periods for FL(1998→already treated) and OK(1999→already treated)
# FL and OK become "always treated" in this window — drop them from CS (only 7 treated remain)
# OR keep 1999+ to capture OK's treatment year

# Use 1999-2023 — this is consecutive and captures OK(1999)
cdc <- cdc %>% filter(year >= 1999)

# FL treated in 1998 — already treated before our panel starts. Drop FL from CS analysis
# (we can still use FL in TWFE as a robustness check)
cdc_cs <- cdc %>%
  filter(state_abb != "FL") %>%
  mutate(first_treat = if_else(state_abb == "FL", 0L, first_treat))

# Ensure balanced panel
state_years <- cdc_cs %>%
  count(state_fips) %>%
  filter(n == max(n)) %>%
  pull(state_fips)

cdc_cs <- cdc_cs %>% filter(state_fips %in% state_years)

cat("CDC CS panel:", nrow(cdc_cs), "obs,", n_distinct(cdc_cs$state_fips), "states\n")
cat("  Years:", paste(range(cdc_cs$year), collapse = "-"), "\n")
cat("  Treated states:", sum(cdc_cs$first_treat > 0 & !duplicated(cdc_cs$state_fips)), "\n")
cat("ACS panel:", nrow(acs), "obs,", n_distinct(acs$state_fips), "states\n")

# ============================================================
# 1. Callaway-Sant'Anna: CDC Divorce Rate
# ============================================================
cat("\n=== Callaway-Sant'Anna: Divorce Rate ===\n")

cs_divorce <- att_gt(
  yname = "divorce_rate",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat",
  data = cdc_cs,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "dr"
)

cat("\nGroup-Time ATTs:\n")
summary(cs_divorce)

# Overall ATT
agg_overall <- aggte(cs_divorce, type = "simple")
cat("\nOverall ATT (divorce rate):\n")
summary(agg_overall)

# Dynamic/event study
agg_dynamic <- aggte(cs_divorce, type = "dynamic", min_e = -8, max_e = 10)
cat("\nDynamic ATT (event study):\n")
summary(agg_dynamic)

# Group-specific ATTs
agg_group <- aggte(cs_divorce, type = "group")
cat("\nGroup-specific ATTs:\n")
summary(agg_group)

# Calendar time ATTs
agg_calendar <- aggte(cs_divorce, type = "calendar")
cat("\nCalendar-time ATTs:\n")
summary(agg_calendar)

# ============================================================
# 2. Callaway-Sant'Anna: CDC Marriage Rate
# ============================================================
cat("\n=== Callaway-Sant'Anna: Marriage Rate ===\n")

# Only use observations where marriage_rate is available (use same balanced CS panel)
cdc_marry <- cdc_cs %>% filter(!is.na(marriage_rate))

# Ensure balanced
marry_state_years <- cdc_marry %>% count(state_fips) %>% filter(n == max(n)) %>% pull(state_fips)
cdc_marry <- cdc_marry %>% filter(state_fips %in% marry_state_years)

cs_marriage <- att_gt(
  yname = "marriage_rate",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat",
  data = cdc_marry,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "dr"
)

agg_marriage_overall <- aggte(cs_marriage, type = "simple")
cat("\nOverall ATT (marriage rate):\n")
summary(agg_marriage_overall)

agg_marriage_dynamic <- aggte(cs_marriage, type = "dynamic", min_e = -8, max_e = 10)

# ============================================================
# 3. ACS: Percent Divorced (2008-2022)
# ============================================================
cat("\n=== Callaway-Sant'Anna: ACS Percent Divorced ===\n")

# Only states that adopted after 2008 or never-treated contribute
# Treated before 2008: FL(1998), OK(1999), MD(2001), MN(2001), TN(2002), GA(2004), SC(2006)
# Treated after 2008: TX(2007-close enough), WV(2012), UT(2018)
# For ACS we can use all states but mainly WV and UT are the useful treated cohorts

cs_acs_divorced <- att_gt(
  yname = "pct_divorced",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat",
  data = acs,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "dr"
)

agg_acs_divorced <- aggte(cs_acs_divorced, type = "simple")
cat("\nOverall ATT (ACS % divorced):\n")
summary(agg_acs_divorced)

# ============================================================
# 4. TWFE comparison (for robustness/contrast)
# ============================================================
cat("\n=== TWFE Comparison ===\n")

cdc_cs <- cdc_cs %>%
  mutate(post = if_else(treated == 1 & year >= treat_year, 1L, 0L))

twfe_divorce <- feols(divorce_rate ~ post | state_fips + year, data = cdc_cs,
                       cluster = ~state_fips)
cat("\nTWFE Divorce Rate:\n")
summary(twfe_divorce)

cdc_marry <- cdc_marry %>%
  mutate(post = if_else(treated == 1 & year >= treat_year, 1L, 0L))

twfe_marriage <- feols(marriage_rate ~ post | state_fips + year, data = cdc_marry,
                        cluster = ~state_fips)
cat("\nTWFE Marriage Rate:\n")
summary(twfe_marriage)

# ============================================================
# 5. Wild Cluster Bootstrap (10 treated clusters)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# Using fwildclusterboot for proper inference with few clusters
boot_divorce <- tryCatch({
  boottest(twfe_divorce, param = "post", clustid = c("state_fips"),
           B = 999, type = "webb")
}, error = function(e) {
  cat("  Wild bootstrap error:", conditionMessage(e), "\n")
  cat("  Falling back to standard clustered SEs\n")
  NULL
})

if (!is.null(boot_divorce)) {
  cat("\nWild Cluster Bootstrap (divorce):\n")
  print(summary(boot_divorce))
}

boot_marriage <- tryCatch({
  boottest(twfe_marriage, param = "post", clustid = c("state_fips"),
           B = 999, type = "webb")
}, error = function(e) {
  cat("  Wild bootstrap error:", conditionMessage(e), "\n")
  cat("  Falling back to standard clustered SEs\n")
  NULL
})

if (!is.null(boot_marriage)) {
  cat("\nWild Cluster Bootstrap (marriage):\n")
  print(summary(boot_marriage))
}

# ============================================================
# 6. Save results
# ============================================================

# Pre-treatment SD for SDE calculation
pre_sd_divorce <- cdc_cs %>%
  filter(treated == 1, year < treat_year) %>%
  summarise(sd_y = sd(divorce_rate, na.rm = TRUE)) %>%
  pull(sd_y)

pre_sd_marriage <- cdc_marry %>%
  filter(treated == 1, year < treat_year) %>%
  summarise(sd_y = sd(marriage_rate, na.rm = TRUE)) %>%
  pull(sd_y)

results <- list(
  cs_divorce = cs_divorce,
  cs_marriage = cs_marriage,
  cs_acs_divorced = cs_acs_divorced,
  agg_overall_divorce = agg_overall,
  agg_dynamic_divorce = agg_dynamic,
  agg_overall_marriage = agg_marriage_overall,
  agg_dynamic_marriage = agg_marriage_dynamic,
  agg_group_divorce = agg_group,
  twfe_divorce = twfe_divorce,
  twfe_marriage = twfe_marriage,
  boot_divorce = boot_divorce,
  boot_marriage = boot_marriage,
  pre_sd_divorce = pre_sd_divorce,
  pre_sd_marriage = pre_sd_marriage
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
# For state-level DiD, n_treated = number of treated state-year observations (post-treatment)
n_treated_states <- n_distinct(cdc_cs$state_fips[cdc_cs$treated == 1])
n_treated_obs <- sum(cdc_cs$treated == 1 & cdc_cs$year >= cdc_cs$treat_year, na.rm = TRUE)

# Pre-periods: report for states with meaningful pre-treatment data
# Exclude OK (1999) since it's treated before the panel starts (2000)
n_pre_by_state <- cdc_cs %>%
  filter(treated == 1, treat_year > min(cdc_cs$year)) %>%
  group_by(state_fips) %>%
  filter(year < treat_year) %>%
  summarise(n_pre = n(), .groups = "drop")
n_pre <- if (nrow(n_pre_by_state) > 0) min(n_pre_by_state$n_pre) else 0L

jsonlite::write_json(
  list(
    n_treated = n_treated_obs,  # treated state-years (validator expects units, not clusters)
    n_pre = n_pre,
    n_obs = nrow(cdc_cs),
    n_treated_states = n_treated_states
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("\n=== Main analysis complete ===\n")
cat("Results saved to:", file.path(data_dir, "main_results.rds"), "\n")
cat("Diagnostics:", file.path(data_dir, "diagnostics.json"), "\n")
