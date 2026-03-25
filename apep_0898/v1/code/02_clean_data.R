## 02_clean_data.R — Construct treatment and outcome variables for apep_0898
## Grocery exit cascades: anchor store hypothesis
##
## Strategy: Bartik shift-share IV using chain bankruptcy events (2010+)
## Pre-period: 2005-2009; Treatment cohorts: 2010, 2015, 2017, 2018, 2020

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Load and reshape CBP data
## ============================================================
cbp_raw <- readRDS(file.path(data_dir, "cbp_raw.rds"))
bankruptcy_exposure <- readRDS(file.path(data_dir, "bankruptcy_exposure.rds"))
chain_bankruptcies <- readRDS(file.path(data_dir, "chain_bankruptcies.rds"))

## Pivot NAICS sectors to columns
cbp_wide <- cbp_raw %>%
  select(fips, state, year, naics, estab, emp) %>%
  pivot_wider(
    id_cols = c(fips, state, year),
    names_from = naics,
    values_from = c(estab, emp),
    names_sep = "_"
  ) %>%
  rename(
    grocery_estab = estab_445,
    grocery_sub_estab = estab_4451,
    foodservice_estab = estab_722,
    health_estab = estab_446,
    personal_estab = estab_812,
    grocery_emp = emp_445,
    grocery_sub_emp = emp_4451,
    foodservice_emp = emp_722,
    health_emp = emp_446,
    personal_emp = emp_812
  )

cat(sprintf("CBP wide panel: %d county-years, %d unique counties\n",
            nrow(cbp_wide), n_distinct(cbp_wide$fips)))

## ============================================================
## 2. Build balanced panel
## ============================================================
## Require counties to have grocery + foodservice data for at least 14 of 18 years
county_coverage <- cbp_wide %>%
  filter(!is.na(grocery_estab) & !is.na(foodservice_estab)) %>%
  group_by(fips) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")

balanced_counties <- county_coverage %>% filter(n_years >= 14) %>% pull(fips)
cat(sprintf("Counties with ≥14 years of grocery+foodservice data: %d\n",
            length(balanced_counties)))

panel <- cbp_wide %>%
  filter(fips %in% balanced_counties) %>%
  arrange(fips, year)

## ============================================================
## 3. Construct Bartik shift-share IV (2010+ bankruptcies only)
## ============================================================
## Drop Winn-Dixie (2005) — in first year, no pre-period
## Focus on: A&P 2010, A&P/Haggen 2015, Marsh 2017, Tops/SE Grocers 2018,
##           Earth Fare/Lucky's/Fairway 2020

post2010_bankruptcies <- chain_bankruptcies %>% filter(bankruptcy_year >= 2010)
post2010_exposure <- bankruptcy_exposure %>% filter(bankruptcy_year >= 2010)

cat(sprintf("\nUsing %d bankruptcy events (2010+), %d state exposures\n",
            nrow(post2010_bankruptcies), nrow(post2010_exposure)))

## Base year: 2008 (pre-A&P bankruptcy, avoiding 2005 Winn-Dixie distortion)
base_year <- 2008

base_year_data <- panel %>%
  filter(year == base_year) %>%
  select(fips, state, grocery_estab_base = grocery_estab)

## State totals in base year
state_base_totals <- base_year_data %>%
  group_by(state) %>%
  summarise(state_grocery_base = sum(grocery_estab_base, na.rm = TRUE), .groups = "drop")

base_year_data <- base_year_data %>%
  left_join(state_base_totals, by = "state") %>%
  mutate(
    county_state_share = ifelse(state_grocery_base > 0,
                                grocery_estab_base / state_grocery_base, 0)
  )

## Bartik IV: predicted grocery loss from chain bankruptcies
## Bartik_ct = Σ_k share_{c} × I[chain_k in state(c)] × stores_k × I[year ≥ bankruptcy_year_k]
years_df <- tibble(year = 2005:2022)

bartik_components <- base_year_data %>%
  select(fips, state, county_state_share) %>%
  cross_join(
    post2010_exposure %>%
      select(chain, bankruptcy_year, state_fips, approx_stores) %>%
      rename(exposed_state = state_fips)
  ) %>%
  filter(state == exposed_state)

bartik_panel <- bartik_components %>%
  cross_join(years_df) %>%
  mutate(
    active = as.integer(year >= bankruptcy_year),
    bartik_contribution = county_state_share * approx_stores * active
  ) %>%
  group_by(fips, year) %>%
  summarise(
    bartik_iv = sum(bartik_contribution),
    n_active_bankruptcies = sum(active),
    .groups = "drop"
  )

panel <- panel %>%
  left_join(bartik_panel, by = c("fips", "year")) %>%
  mutate(
    bartik_iv = replace_na(bartik_iv, 0),
    n_active_bankruptcies = replace_na(n_active_bankruptcies, 0)
  )

## ============================================================
## 4. Define treatment cohorts based on first bankruptcy exposure
## ============================================================
## Treatment = first year a county's state is hit by any chain bankruptcy (2010+)
## This gives us staggered treatment with known timing

exposed_states <- post2010_exposure %>%
  group_by(state_fips) %>%
  summarise(first_exposure_year = min(bankruptcy_year), .groups = "drop")

panel <- panel %>%
  left_join(exposed_states, by = c("state" = "state_fips")) %>%
  mutate(
    first_exposure_year = replace_na(first_exposure_year, 0),
    ever_exposed = first_exposure_year > 0,
    post_exposure = year >= first_exposure_year & ever_exposed
  )

## Also track actual grocery establishment changes for reduced form
panel <- panel %>%
  group_by(fips) %>%
  arrange(year) %>%
  mutate(
    grocery_estab_lag = lag(grocery_estab),
    grocery_change = grocery_estab - grocery_estab_lag,
    grocery_pct_change = ifelse(grocery_estab_lag > 0,
                                grocery_change / grocery_estab_lag, NA_real_)
  ) %>%
  ungroup()

## For Callaway-Sant'Anna: first_treat is first_exposure_year (0 = never treated)
panel <- panel %>%
  mutate(first_treat = first_exposure_year)

## ============================================================
## 5. Construct outcome variables
## ============================================================
panel <- panel %>%
  mutate(
    nongrocery_estab = foodservice_estab + health_estab + personal_estab,
    log_grocery = log(pmax(grocery_estab, 1)),
    log_foodservice = log(pmax(foodservice_estab, 1)),
    log_health = log(pmax(health_estab, 1)),
    log_personal = log(pmax(personal_estab, 1)),
    log_nongrocery = log(pmax(nongrocery_estab, 1))
  )

## ============================================================
## 6. County characteristics for heterogeneity
## ============================================================
panel <- panel %>%
  left_join(
    base_year_data %>% select(fips, grocery_estab_base),
    by = "fips"
  ) %>%
  mutate(
    few_grocers = grocery_estab_base <= median(grocery_estab_base, na.rm = TRUE),
    rural = grocery_estab_base <= 5,
    urban = grocery_estab_base > 20
  )

## ============================================================
## 7. Summary and validation
## ============================================================
treat_tab <- panel %>%
  filter(year == base_year + 1) %>%
  count(ever_exposed)

n_treated <- sum(treat_tab$n[treat_tab$ever_exposed])
n_control <- sum(treat_tab$n[!treat_tab$ever_exposed])

cat(sprintf("\n========== CLEAN PANEL SUMMARY ==========\n"))
cat(sprintf("Counties: %d\n", n_distinct(panel$fips)))
cat(sprintf("Years: %d-%d (%d years)\n", min(panel$year), max(panel$year),
            n_distinct(panel$year)))
cat(sprintf("Total county-years: %d\n", nrow(panel)))
cat(sprintf("Ever-exposed (treated): %d counties\n", n_treated))
cat(sprintf("Never-exposed (control): %d counties\n", n_control))

## Treatment cohorts
cat(sprintf("\nTreatment cohorts (first exposure year):\n"))
cohort_tab <- panel %>%
  filter(ever_exposed, year == base_year + 1) %>%
  count(first_treat) %>%
  arrange(first_treat)
print(cohort_tab, n = 10)

## Pre-period check
min_treat_year <- min(panel$first_treat[panel$first_treat > 0])
n_pre <- min_treat_year - min(panel$year)
cat(sprintf("\nFirst treatment year: %d\n", min_treat_year))
cat(sprintf("Pre-treatment periods: %d (need ≥5)\n", n_pre))
cat(sprintf("=========================================\n"))

## Diagnostics for V1 validation
n_obs <- nrow(panel)
cat(sprintf("\nDiagnostics for V1 validation:\n"))
cat(sprintf("  n_treated = %d (need ≥20)\n", n_treated))
cat(sprintf("  n_pre = %d (need ≥5)\n", n_pre))
cat(sprintf("  n_obs = %d (need ≥100)\n", n_obs))

if (n_treated < 20) stop("FATAL: Fewer than 20 treated units")
if (n_pre < 5) stop("FATAL: Fewer than 5 pre-treatment periods")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

## Save diagnostics for validator
jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("\nSaved analysis_panel.rds and diagnostics.json\n")
