# =============================================================================
# 04_robustness.R — Robustness checks for apep_0848
# =============================================================================

source("00_packages.R")

panel_hc <- readRDS("../data/panel_healthcare.rds")
panel_placebo <- readRDS("../data/panel_placebo.rds")
results <- readRDS("../data/main_results.rds")

# =============================================================================
# 1. Placebo: Retail and Accommodation (should show NO effect)
# =============================================================================
message("=== Placebo: Non-Healthcare Sectors ===")

placebo_results <- list()
for (sec in c("Retail", "Accommodation/Food")) {
  sub <- panel_placebo %>% filter(sector == sec)
  placebo_results[[sec]] <- list(
    emp = feols(log_emp ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    hire = feols(hire_rate ~ treated | county_fips + period, data = sub, cluster = ~state_fips),
    sep = feols(sep_rate ~ treated | county_fips + period, data = sub, cluster = ~state_fips)
  )
  message(sprintf("Placebo %s: emp=%.4f (%.4f), hire=%.4f (%.4f)",
                  sec,
                  coef(placebo_results[[sec]]$emp)["treated"],
                  se(placebo_results[[sec]]$emp)["treated"],
                  coef(placebo_results[[sec]]$hire)["treated"],
                  se(placebo_results[[sec]]$hire)["treated"]))
}

# =============================================================================
# 2. Triple-DiD: Healthcare vs Non-Healthcare within county
# =============================================================================
message("\n=== Triple Difference-in-Differences ===")

panel_full <- readRDS("../data/panel_full.rds")

# Create triple-DiD dataset
panel_triple <- panel_full %>%
  mutate(
    post = as.integer(yearqtr >= 2018),
    enlc_state = as.integer(group != "never"),
    healthcare = as.integer(is_healthcare),
    county_industry = paste(county_fips, industry)
  )

# Triple-DiD: healthcare × eNLC × post
triple_emp <- feols(
  log_emp ~ healthcare:enlc_state:post + healthcare:post + enlc_state:post +
    healthcare:enlc_state | county_industry + period,
  data = panel_triple,
  cluster = ~state_fips
)

triple_hire <- feols(
  hire_rate ~ healthcare:enlc_state:post + healthcare:post + enlc_state:post +
    healthcare:enlc_state | county_industry + period,
  data = panel_triple,
  cluster = ~state_fips
)

triple_sep <- feols(
  sep_rate ~ healthcare:enlc_state:post + healthcare:post + enlc_state:post +
    healthcare:enlc_state | county_industry + period,
  data = panel_triple,
  cluster = ~state_fips
)

message("Triple-DiD (healthcare × eNLC × post):")
etable(triple_emp, triple_hire, triple_sep)

# =============================================================================
# 3. Leave-one-out by cohort
# =============================================================================
message("\n=== Leave-One-Out by Cohort ===")

# Drop founding states, use only later adopters + never-treated
panel_later <- panel_hc %>%
  filter(group != "founding")

if (n_distinct(panel_later$county_fips[panel_later$group == "later"]) >= 50) {
  loo_emp <- feols(
    log_emp ~ treated | county_fips + period,
    data = panel_later,
    cluster = ~state_fips
  )

  loo_hire <- feols(
    hire_rate ~ treated | county_fips + period,
    data = panel_later,
    cluster = ~state_fips
  )

  message(sprintf("Later-only: emp=%.4f (%.4f), hire=%.4f (%.4f)",
                  coef(loo_emp)["treated"], se(loo_emp)["treated"],
                  coef(loo_hire)["treated"], se(loo_hire)["treated"]))
} else {
  message("Too few later-adopter counties for LOO analysis.")
  loo_emp <- NULL
  loo_hire <- NULL
}

# =============================================================================
# 4. Pre-2020 only (exclude COVID period)
# =============================================================================
message("\n=== Pre-COVID Window (2014-2019) ===")

panel_pre_covid <- panel_hc %>%
  filter(year <= 2019)

precovid_emp <- feols(
  log_emp ~ treated | county_fips + period,
  data = panel_pre_covid,
  cluster = ~state_fips
)

precovid_hire <- feols(
  hire_rate ~ treated | county_fips + period,
  data = panel_pre_covid,
  cluster = ~state_fips
)

precovid_sep <- feols(
  sep_rate ~ treated | county_fips + period,
  data = panel_pre_covid,
  cluster = ~state_fips
)

message(sprintf("Pre-COVID: emp=%.4f (%.4f), hire=%.4f (%.4f), sep=%.4f (%.4f)",
                coef(precovid_emp)["treated"], se(precovid_emp)["treated"],
                coef(precovid_hire)["treated"], se(precovid_hire)["treated"],
                coef(precovid_sep)["treated"], se(precovid_sep)["treated"]))

# =============================================================================
# 5. Education decomposition (associate's vs bachelor's+)
# =============================================================================
message("\n=== Education Decomposition ===")

df_se <- readRDS("../data/qwi_se_raw.rds")

# Process education data similarly to main panel
treatment <- readRDS("../data/treatment_assignment.rds")

df_se <- df_se %>%
  mutate(
    geography_str = sprintf("%05d", as.integer(geography)),
    state_fips = substr(geography_str, 1, 2),
    county_fips = geography_str,
    yearqtr = year + (quarter - 1) / 4
  ) %>%
  filter(state_fips %in% treatment$state_fips,
         industry %in% c("621", "622", "623")) %>%
  left_join(treatment, by = "state_fips") %>%
  mutate(
    treated = as.integer(yearqtr >= adopt_yearqtr),
    period = as.integer((year - 2014) * 4 + quarter),
    is_healthcare = TRUE
  ) %>%
  filter(!is.na(Emp), Emp > 0)

# Education levels: E1=less than HS, E2=HS, E3=some college/associate's, E4=bachelor's+, E5=not available, E0=all
# E3 is the nursing proxy (associate's degree is the typical RN credential)
edu_assoc <- df_se %>% filter(education == "E3")
edu_bach <- df_se %>% filter(education == "E4")

if (nrow(edu_assoc) > 1000 && nrow(edu_bach) > 1000) {
  edu_assoc_emp <- feols(
    log(Emp) ~ treated | county_fips + period,
    data = edu_assoc,
    cluster = ~state_fips
  )

  edu_bach_emp <- feols(
    log(Emp) ~ treated | county_fips + period,
    data = edu_bach,
    cluster = ~state_fips
  )

  edu_assoc_hire <- feols(
    I(HirA / Emp) ~ treated | county_fips + period,
    data = edu_assoc,
    cluster = ~state_fips
  )

  edu_bach_hire <- feols(
    I(HirA / Emp) ~ treated | county_fips + period,
    data = edu_bach,
    cluster = ~state_fips
  )

  message(sprintf("Associate's (nursing proxy): emp=%.4f (%.4f), hire=%.4f (%.4f)",
                  coef(edu_assoc_emp)["treated"], se(edu_assoc_emp)["treated"],
                  coef(edu_assoc_hire)["treated"], se(edu_assoc_hire)["treated"]))
  message(sprintf("Bachelor's+ (non-nursing): emp=%.4f (%.4f), hire=%.4f (%.4f)",
                  coef(edu_bach_emp)["treated"], se(edu_bach_emp)["treated"],
                  coef(edu_bach_hire)["treated"], se(edu_bach_hire)["treated"]))
} else {
  message("Insufficient education-disaggregated data for decomposition.")
  edu_assoc_emp <- NULL
  edu_bach_emp <- NULL
  edu_assoc_hire <- NULL
  edu_bach_hire <- NULL
}

# =============================================================================
# 6. Save robustness results
# =============================================================================

robustness <- list(
  placebo = placebo_results,
  triple = list(emp = triple_emp, hire = triple_hire, sep = triple_sep),
  loo = list(emp = loo_emp, hire = loo_hire),
  precovid = list(emp = precovid_emp, hire = precovid_hire, sep = precovid_sep),
  edu = list(assoc_emp = edu_assoc_emp, bach_emp = edu_bach_emp,
             assoc_hire = edu_assoc_hire, bach_hire = edu_bach_hire)
)

saveRDS(robustness, "../data/robustness_results.rds")

message("\nRobustness checks complete.")
