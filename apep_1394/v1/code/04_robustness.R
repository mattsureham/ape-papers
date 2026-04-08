## 04_robustness.R — Robustness checks
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n")

panel <- readRDS("../data/panel_clean.rds")
panel_finance <- readRDS("../data/panel_finance.rds")
panel_nursing <- readRDS("../data/panel_nursing.rds")
qwi_age <- readRDS("../data/qwi_age.rds")
pfl_states <- readRDS("../data/pfl_states.rds")
results <- readRDS("../data/main_results.rds")

# -----------------------------------------------------------------------
# 1. Placebo: Male-only turnover (should be null)
# -----------------------------------------------------------------------

cat("\n--- Placebo: Male-only ---\n")
m_male <- feols(
  turnover ~ post_pfl | state_fips + time_id,
  data = panel |> filter(female == 0, !is.na(turnover)),
  cluster = ~state_fips
)
summary(m_male)

cat("\n--- Placebo: Female-only ---\n")
m_female <- feols(
  turnover ~ post_pfl | state_fips + time_id,
  data = panel |> filter(female == 1, !is.na(turnover)),
  cluster = ~state_fips
)
summary(m_female)

# -----------------------------------------------------------------------
# 2. Falsification: Finance sector (NAICS 52)
# -----------------------------------------------------------------------

cat("\n--- Falsification: Finance (NAICS 52) ---\n")

panel_finance <- panel_finance |>
  mutate(
    turnover = as.numeric(TurnOvrS),
    state_sex_id = as.integer(factor(paste0(state_fips, "_", sex)))
  )

m_finance <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel_finance |> filter(!is.na(turnover)),
  cluster = ~state_fips
)
summary(m_finance)

# -----------------------------------------------------------------------
# 3. Subsector: Nursing & residential care (NAICS 623)
# -----------------------------------------------------------------------

cat("\n--- Subsector: Nursing (NAICS 623) ---\n")

panel_nursing <- panel_nursing |>
  mutate(
    turnover = as.numeric(TurnOvrS),
    state_sex_id = as.integer(factor(paste0(state_fips, "_", sex)))
  )

m_nursing <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel_nursing |> filter(!is.na(turnover)),
  cluster = ~state_fips
)
summary(m_nursing)

# -----------------------------------------------------------------------
# 4. Exclude early adopter (CA 2004)
# -----------------------------------------------------------------------

cat("\n--- Excluding California ---\n")
m_noca <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(state_fips != 6, !is.na(turnover)),
  cluster = ~state_fips
)
summary(m_noca)

# -----------------------------------------------------------------------
# 5. Exclude COVID period (2020-2021)
# -----------------------------------------------------------------------

cat("\n--- Excluding COVID (2020-2021) ---\n")
m_nocovid <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!(year %in% c(2020, 2021)), !is.na(turnover)),
  cluster = ~state_fips
)
summary(m_nocovid)

# -----------------------------------------------------------------------
# 6. Age heterogeneity (childbearing age vs older)
# -----------------------------------------------------------------------

cat("\n--- Age Heterogeneity ---\n")

# Build age panel
age_panel <- qwi_age |>
  as_tibble() |>
  mutate(
    state_fips = as.integer(geography),
    female = as.integer(sex == 2),
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2001) * 4 + quarter,
    turnover = as.numeric(TurnOvrS),
    young = agegrp %in% c("A02", "A03", "A04"),  # 19-44
    prime_child = agegrp %in% c("A03", "A04")     # 25-44
  ) |>
  left_join(pfl_states |> select(state_fips, pfl_year, pfl_quarter, pfl_yq),
            by = "state_fips") |>
  mutate(
    pfl_state = !is.na(pfl_year),
    post_pfl = ifelse(pfl_state, as.integer(yq >= pfl_yq), 0L),
    treated_ddd = post_pfl * female
  )

# Young women (childbearing age 25-44)
m_young <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = age_panel |> filter(prime_child, !is.na(turnover)),
  cluster = ~state_fips
)

# Older women (45+)
m_older <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = age_panel |> filter(!young, !is.na(turnover)),
  cluster = ~state_fips
)

cat("Young (25-44):\n"); summary(m_young)
cat("Older (45+):\n"); summary(m_older)

# -----------------------------------------------------------------------
# 7. Alternative clustering (state-sex level)
# -----------------------------------------------------------------------

cat("\n--- Alt clustering: state × sex ---\n")
m_altclust <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(turnover)),
  cluster = ~state_sex_id
)
summary(m_altclust)

# -----------------------------------------------------------------------
# 8. Save
# -----------------------------------------------------------------------

robust <- list(
  male_placebo = m_male,
  female_only = m_female,
  finance_falsification = m_finance,
  nursing_subsector = m_nursing,
  no_california = m_noca,
  no_covid = m_nocovid,
  young_age = m_young,
  older_age = m_older,
  alt_cluster = m_altclust
)

saveRDS(robust, "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
