# =============================================================================
# 02_clean_data.R — Build DDD analysis panel
# =============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_raw.rds")

# ---------------------------------------------------------------------------
# 1. Treatment assignment — county FIPS to Fair Workweek law mapping
# ---------------------------------------------------------------------------

# Treatment cohorts: (county FIPS, effective quarter as year_q numeric)
# Using year + quarter/4 coding: e.g., 2017.75 = Q3 2017
treatment_map <- tribble(
  ~fips,  ~cohort_yq,  ~jurisdiction,
  # San Francisco: Q3 2015
  6075L,  2015.50,     "San Francisco",
  # Seattle (King County): Q3 2017
  53033L, 2017.50,     "Seattle",
  # NYC boroughs (fast food): Q4 2017
  36005L, 2017.75,     "NYC",
  36047L, 2017.75,     "NYC",
  36061L, 2017.75,     "NYC",
  36081L, 2017.75,     "NYC",
  36085L, 2017.75,     "NYC",
  # Philadelphia: Q2 2020
  42101L, 2020.25,     "Philadelphia",
  # Chicago (Cook County): Q3 2020
  17031L, 2020.50,     "Chicago"
)

# Oregon statewide: Q3 2018 — all Oregon counties
or_fips <- unique(qwi$geography[qwi$geography >= 41000 & qwi$geography <= 41999])
oregon_map <- tibble(
  fips = or_fips,
  cohort_yq = 2018.50,
  jurisdiction = "Oregon"
)

treatment_map <- bind_rows(treatment_map, oregon_map)
cat(sprintf("Treatment map: %d county-FIPS entries (%d jurisdictions)\n",
            nrow(treatment_map), n_distinct(treatment_map$jurisdiction)))

# ---------------------------------------------------------------------------
# 2. Construct panel variables
# ---------------------------------------------------------------------------

df <- qwi %>%
  mutate(
    fips = as.integer(geography),
    state_fips = as.integer(floor(fips / 1000)),
    yq = year + (quarter - 1) / 4,
    black = as.integer(race == "A2"),
    # Time index: quarters since 2013Q1
    t = (year - 2013) * 4 + quarter
  ) %>%
  left_join(treatment_map, by = "fips") %>%
  mutate(
    # Treatment indicator
    treated_ever = !is.na(cohort_yq),
    post = ifelse(treated_ever, as.integer(yq >= cohort_yq), 0L),
    treat_post = post * treated_ever,
    # DDD interaction
    treat_post_black = treat_post * black,
    # For CS estimator: first treatment period (0 for never-treated)
    first_treat = ifelse(treated_ever, cohort_yq, 0),
    # County-race unit ID
    unit_cr = paste0(fips, "_", race)
  )

# ---------------------------------------------------------------------------
# 3. Data quality checks
# ---------------------------------------------------------------------------

# Drop suppressed cells (status flag indicates data is suppressed)
# QWI uses -1 or NA for suppressed values
df <- df %>%
  filter(!is.na(EmpEnd) & EmpEnd > 0)

cat("\n--- Panel Summary ---\n")
cat(sprintf("Total obs: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("Counties: %d\n", n_distinct(df$fips)))
cat(sprintf("States: %d\n", n_distinct(df$state_fips)))
cat(sprintf("Quarters: %d (%s to %s)\n",
            n_distinct(df$yq), min(df$yq), max(df$yq)))
cat(sprintf("Treated counties: %d\n", n_distinct(df$fips[df$treated_ever])))
cat(sprintf("Control counties: %d\n", n_distinct(df$fips[!df$treated_ever])))

# NAICS breakdown
cat("\n--- By Industry ---\n")
df %>%
  group_by(industry) %>%
  summarise(
    n = n(),
    n_counties = n_distinct(fips),
    mean_emp = mean(EmpEnd, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Race breakdown
cat("\n--- By Race ---\n")
df %>%
  group_by(race, industry) %>%
  summarise(
    n = n(),
    mean_emp = mean(EmpEnd, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Treatment cohort sizes
cat("\n--- Treatment Cohorts ---\n")
df %>%
  filter(treated_ever & industry == "72" & race == "A0") %>%
  distinct(fips, jurisdiction, cohort_yq) %>%
  count(jurisdiction, cohort_yq) %>%
  arrange(cohort_yq) %>%
  print()

# ---------------------------------------------------------------------------
# 4. Create pre-COVID subsample flag
# ---------------------------------------------------------------------------

# Pre-COVID adopters: SF (2015), Seattle (2017), NYC (2017), Oregon (2018)
pre_covid_cohorts <- c(2015.50, 2017.50, 2017.75, 2018.50)

df <- df %>%
  mutate(
    pre_covid_treated = treated_ever & cohort_yq %in% pre_covid_cohorts,
    # For pre-COVID analysis: drop COVID-era treated counties entirely
    in_pre_covid_sample = (!treated_ever | pre_covid_treated) & yq <= 2020.00
  )

cat(sprintf("\nPre-COVID sample (through 2019Q4): %s obs\n",
            format(sum(df$in_pre_covid_sample), big.mark = ",")))

# ---------------------------------------------------------------------------
# 5. Log outcomes for elasticity interpretation
# ---------------------------------------------------------------------------

df <- df %>%
  mutate(
    ln_emp = log(EmpEnd),
    ln_earn = ifelse(EarnS > 0, log(EarnS), NA_real_),
    ln_sep = ifelse(Sep > 0, log(Sep), NA_real_),
    ln_hir = ifelse(HirA > 0, log(HirA), NA_real_)
  )

# ---------------------------------------------------------------------------
# 6. Save
# ---------------------------------------------------------------------------

saveRDS(df, "../data/panel.rds")
cat(sprintf("\nSaved analysis panel: %s obs\n", format(nrow(df), big.mark = ",")))
