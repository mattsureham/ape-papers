# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# =============================================================================

source("00_packages.R")

state_year_all <- readRDS("../data/state_year_all.rds")
state_year_race <- readRDS("../data/state_year_race.rds")
qwi_placebo <- readRDS("../data/qwi_placebo_agg.rds")
film_credits <- readRDS("../data/film_credits.rds")
results <- readRDS("../data/main_results.rds")

state_fips_df <- data.frame(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                 42,44,45,46,47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                 "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                 "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                 "UT","VT","VA","WA","WV","WI","WY")
)

# ---------------------------------------------------------------------------
# 1-3. Placebo tests using pre-aggregated sector data
# ---------------------------------------------------------------------------

# Data is already aggregated to state_fips x year x quarter x sector
# Collapse to state-year
build_placebo <- function(sector_name) {
  qwi_placebo %>%
    filter(sector == sector_name) %>%
    group_by(state_fips, year) %>%
    summarize(emp_placebo = mean(emp, na.rm = TRUE), .groups = "drop") %>%
    mutate(log_emp_placebo = log(pmax(emp_placebo, 1))) %>%
    left_join(state_fips_df, by = "state_fips") %>%
    left_join(film_credits %>% select(state_abbr, treat_year), by = "state_abbr") %>%
    mutate(
      first_treat = ifelse(is.na(treat_year), 0, treat_year),
      treated = ifelse(!is.na(treat_year) & year >= treat_year, 1, 0)
    ) %>%
    filter(!(state_abbr %in% c("NC", "MI")))
}

cat("=== Placebo: Manufacturing (NAICS 31-33) ===\n")
placebo_mfg <- build_placebo("Manufacturing")
twfe_mfg <- feols(log_emp_placebo ~ treated | state_fips + year,
                  data = placebo_mfg, cluster = ~state_fips)
cat("Manufacturing placebo:\n")
print(coeftable(twfe_mfg))

cat("\n=== Placebo: Finance (NAICS 52) ===\n")
placebo_fin <- build_placebo("Finance")
twfe_fin <- feols(log_emp_placebo ~ treated | state_fips + year,
                  data = placebo_fin, cluster = ~state_fips)
cat("Finance placebo:\n")
print(coeftable(twfe_fin))

cat("\n=== Placebo: Arts/Entertainment (NAICS 71) ===\n")
placebo_arts <- build_placebo("Arts")
twfe_arts <- feols(log_emp_placebo ~ treated | state_fips + year,
                   data = placebo_arts, cluster = ~state_fips)
cat("Arts/Entertainment placebo:\n")
print(coeftable(twfe_arts))

# ---------------------------------------------------------------------------
# 4. NC Repeal Analysis
# ---------------------------------------------------------------------------

cat("\n=== North Carolina Repeal Analysis ===\n")

nc_data <- state_year_all %>%
  filter(state_abbr %in% c("NC", "SC", "VA", "TN", "GA")) %>%
  mutate(
    is_nc = as.integer(state_abbr == "NC"),
    post_credit = as.integer(year >= 2009 & year < 2014),
    post_repeal = as.integer(year >= 2014)
  )

# Simple pre/during/post comparison
nc_summary <- nc_data %>%
  group_by(state_abbr, period = case_when(
    year < 2009 ~ "Pre-credit",
    year >= 2009 & year < 2014 ~ "Credit active",
    year >= 2014 ~ "Post-repeal"
  )) %>%
  summarize(mean_emp = mean(emp_512, na.rm = TRUE), .groups = "drop")

cat("NC vs neighbors (mean NAICS 512 employment):\n")
print(nc_summary %>% pivot_wider(names_from = period, values_from = mean_emp))

# DiD: NC credit period
nc_did_credit <- feols(log_emp_512 ~ is_nc:post_credit | state_fips + year,
                       data = nc_data %>% filter(year < 2014),
                       cluster = ~state_fips)
cat("\nNC credit adoption DiD:\n")
print(coeftable(nc_did_credit))

# DiD: NC repeal
nc_did_repeal <- feols(log_emp_512 ~ is_nc:post_repeal | state_fips + year,
                       data = nc_data %>% filter(year >= 2009),
                       cluster = ~state_fips)
cat("\nNC repeal DiD:\n")
print(coeftable(nc_did_repeal))

# ---------------------------------------------------------------------------
# 5. Heterogeneity by credit generosity
# ---------------------------------------------------------------------------

cat("\n=== Heterogeneity by Credit Generosity ===\n")

cs_data_het <- state_year_all %>%
  filter(!(state_abbr %in% c("NC", "MI"))) %>%
  mutate(
    generous = ifelse(!is.na(credit_rate_pct) & credit_rate_pct >= 25, 1, 0),
    state_id = as.numeric(as.factor(state_fips))
  )

# Generous credits (>= 25%)
generous_data <- cs_data_het %>%
  filter(generous == 1 | first_treat == 0)

twfe_generous <- feols(log_emp_512 ~ treated | state_fips + year,
                       data = generous_data, cluster = ~state_fips)
cat("Generous credits (>= 25%):\n")
print(coeftable(twfe_generous))

# Modest credits (15-24%)
modest_data <- cs_data_het %>%
  filter(generous == 0 | first_treat == 0) %>%
  filter(first_treat > 0 | state_abbr %in% c("AK","DE","IA","IN","KS","MO",
                                               "ND","NE","NH","SD","VT","WY","DC"))

twfe_modest <- feols(log_emp_512 ~ treated | state_fips + year,
                     data = modest_data, cluster = ~state_fips)
cat("Modest credits (15-24%):\n")
print(coeftable(twfe_modest))

# Credit type heterogeneity
twfe_type <- feols(log_emp_512 ~ treated:i(credit_type) | state_fips + year,
                   data = cs_data_het %>% filter(first_treat > 0),
                   cluster = ~state_fips)
cat("\nBy credit type:\n")
print(coeftable(twfe_type))

# ---------------------------------------------------------------------------
# 6. Save robustness results
# ---------------------------------------------------------------------------

rob_results <- list(
  twfe_mfg = twfe_mfg,
  twfe_fin = twfe_fin,
  twfe_arts = twfe_arts,
  nc_summary = nc_summary,
  nc_did_credit = nc_did_credit,
  nc_did_repeal = nc_did_repeal,
  twfe_generous = twfe_generous,
  twfe_modest = twfe_modest,
  twfe_type = twfe_type
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
