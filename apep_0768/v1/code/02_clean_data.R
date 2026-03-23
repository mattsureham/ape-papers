# =============================================================================
# 02_clean_data.R — Construct analysis dataset with treatment timing
# =============================================================================

source("00_packages.R")

qwi_rh <- readRDS("../data/qwi_rh_512.rds")
qwi_total <- readRDS("../data/qwi_total_rh.rds")
qwi_sa <- readRDS("../data/qwi_sa_512.rds")

# ---------------------------------------------------------------------------
# 1. Treatment timing: State film tax credit adoption/major enhancement
#    Sources: NCSL, Button (2019), Thom (2018), state statutes
#    Treatment = first year-quarter with credit rate >= 15%
# ---------------------------------------------------------------------------

# State FIPS codes for reference
state_fips <- data.frame(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                 42,44,45,46,47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                 "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                 "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                 "UT","VT","VA","WA","WV","WI","WY")
)

# Film tax credit treatment dates (year of first significant credit >= 15%)
# Based on NCSL surveys, Button (2019 Table 1), Thom (2018), state legislative records
# Format: state_abbr, treat_year (year credit first offered at >= 15%), credit_rate, type
film_credits <- tribble(
  ~state_abbr, ~treat_year, ~credit_rate_pct, ~credit_type,
  "LA",  2002, 25, "transferable",      # First major state; enhanced 2005 to 30%
  "NM",  2003, 25, "refundable",        # 25% refundable credit
  "IL",  2004, 20, "transferable",      # Tax credit for accredited productions
  "CT",  2006, 30, "transferable",      # 30% transferable credit
  "GA",  2005, 20, "transferable",      # 9% initially; major enhancement 2008 (20-30%)
  "PA",  2004, 25, "tax_credit",        # 25% tax credit
  "MA",  2006, 25, "transferable",      # Payroll + production spend credits
  "NY",  2004, 30, "refundable",        # Qualified production facility credit
  "NJ",  2005, 20, "tax_credit",        # Film production tax credit
  "NC",  2009, 25, "refundable",        # Enacted ~2009; REPEALED 2014
  "MI",  2008, 42, "refundable",        # Very generous; capped 2012, ended 2015
  "OH",  2009, 25, "refundable",        # Motion Picture Tax Credit
  "OK",  2005, 15, "rebate",            # Rebate program
  "OR",  2005, 20, "tax_credit",        # Greenlight Oregon
  "TX",  2007, 15, "grant",             # Texas Moving Image Industry Incentive
  "VA",  2010, 20, "tax_credit",        # Motion Picture Tax Credit
  "CO",  2012, 20, "rebate",            # Operational Grant
  "WA",  2006, 15, "tax_credit",        # Motion Picture Competitiveness Program
  "RI",  2005, 25, "transferable",      # Motion Picture Production Tax Credits
  "SC",  2005, 20, "rebate",            # Supplier Rebate Incentive
  "FL",  2010, 20, "tax_credit",        # Entertainment Industry Financial Incentive
  "HI",  2006, 20, "refundable",        # Act 88
  "MT",  2005, 15, "tax_credit",        # Big Sky on the Big Screen
  "UT",  2005, 20, "refundable",        # Motion Picture Incentive
  "NV",  2013, 15, "transferable",      # Film Tax Credit
  "MN",  2012, 25, "rebate",            # Snowbate Program revival
  "WV",  2007, 27, "transferable",      # Film Industry Investment Act
  "KY",  2009, 20, "tax_credit",        # Film Production Tax Credit
  "MS",  2005, 25, "rebate",            # Rebate program
  "MD",  2011, 25, "tax_credit",        # Film Production Activity Tax Credit
  "ME",  2006, 15, "rebate",            # Visual Media
  "TN",  2006, 15, "grant",             # Entertainment Commission incentives
  "AR",  2009, 15, "rebate",            # Digital Product & Motion Picture Incentive
  "AZ",  2006, 20, "transferable",      # Motion Picture Production Tax Incentive
  "ID",  2005, 20, "rebate",            # Film and Television Production Rebate
  "WI",  2008, 25, "tax_credit",        # Film Production Services Tax Credit
  "AL",  2009, 25, "rebate"             # Alabama Entertainment Industry Incentive Act
)

# Mark NC repeal
film_credits$repealed_year <- ifelse(film_credits$state_abbr == "NC", 2014,
                              ifelse(film_credits$state_abbr == "MI", 2015, NA))

# Never-treated states (no significant film credit >= 15% as of 2019)
never_treated <- c("AK", "DE", "IA", "IN", "KS", "MO", "ND", "NE", "NH",
                   "SD", "VT", "WY", "DC")

# Merge treatment timing with state FIPS
film_credits <- film_credits %>%
  left_join(state_fips, by = "state_abbr")

cat(sprintf("Treatment timing: %d treated states, %d never-treated\n",
            nrow(film_credits), length(never_treated)))

# ---------------------------------------------------------------------------
# 2. Extract state FIPS from QWI geography codes
# ---------------------------------------------------------------------------

# QWI geography codes are county FIPS (SSFFF format)
# State FIPS = geography %/% 1000
qwi_rh <- qwi_rh %>%
  mutate(state_fips = geography %/% 1000)

# ---------------------------------------------------------------------------
# 3. Aggregate to state-quarter level
# ---------------------------------------------------------------------------

# Overall (all races): aggregate across race/ethnicity/sex/age
state_quarter_all <- qwi_rh %>%
  group_by(state_fips, year, quarter) %>%
  summarize(
    emp_512 = sum(Emp, na.rm = TRUE),
    emp_end_512 = sum(EmpEnd, na.rm = TRUE),
    hir_512 = sum(HirA, na.rm = TRUE),
    sep_512 = sum(Sep, na.rm = TRUE),
    earn_512 = sum(EarnS, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(avg_earn_512 = ifelse(emp_512 > 0, earn_512 / emp_512, NA))

# By race: aggregate across sex/age but keep race
state_quarter_race <- qwi_rh %>%
  group_by(state_fips, year, quarter, race, ethnicity) %>%
  summarize(
    emp_512 = sum(Emp, na.rm = TRUE),
    hir_512 = sum(HirA, na.rm = TRUE),
    sep_512 = sum(Sep, na.rm = TRUE),
    earn_512 = sum(EarnS, na.rm = TRUE),
    .groups = "drop"
  )

# Create broad race categories for analysis
# QWI race codes: A0=All, A1=White alone, A2=Black alone, A3=Amer Indian,
#                 A4=Asian alone, A5=Pacific Islander, A7=Two+
# QWI ethnicity codes: A0=All, A1=Not Hispanic, A2=Hispanic
state_quarter_race <- state_quarter_race %>%
  mutate(
    race_cat = case_when(
      race == "A1" & ethnicity == "A1" ~ "White_NonHisp",
      race == "A2" & ethnicity == "A0" ~ "Black",
      ethnicity == "A2" ~ "Hispanic",
      race == "A4" & ethnicity == "A0" ~ "Asian",
      TRUE ~ "Other"
    )
  ) %>%
  filter(race_cat != "Other")

# Aggregate within race categories
state_quarter_race <- state_quarter_race %>%
  group_by(state_fips, year, quarter, race_cat) %>%
  summarize(
    emp_512 = sum(emp_512, na.rm = TRUE),
    hir_512 = sum(hir_512, na.rm = TRUE),
    sep_512 = sum(sep_512, na.rm = TRUE),
    earn_512 = sum(earn_512, na.rm = TRUE),
    .groups = "drop"
  )

# ---------------------------------------------------------------------------
# 4. Add total employment for normalization
# ---------------------------------------------------------------------------

total_state <- qwi_total %>%
  mutate(state_fips = geography %/% 1000) %>%
  group_by(state_fips, year, quarter) %>%
  summarize(
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  )

state_quarter_all <- state_quarter_all %>%
  left_join(total_state, by = c("state_fips", "year", "quarter")) %>%
  mutate(emp_share_512 = emp_512 / total_emp * 1000)  # per 1000 workers

# ---------------------------------------------------------------------------
# 5. Add treatment timing
# ---------------------------------------------------------------------------

# Create time variable (year-quarter as numeric)
state_quarter_all <- state_quarter_all %>%
  mutate(time = year + (quarter - 1) / 4)

# Merge treatment
state_quarter_all <- state_quarter_all %>%
  left_join(state_fips, by = "state_fips") %>%
  left_join(
    film_credits %>% select(state_abbr, treat_year, credit_rate_pct, credit_type, repealed_year),
    by = "state_abbr"
  ) %>%
  mutate(
    # For CS-DiD: first_treat = treat_year if treated, 0 if never-treated
    first_treat = ifelse(is.na(treat_year), 0, treat_year),
    # Binary treated indicator
    treated = ifelse(!is.na(treat_year) & year >= treat_year, 1, 0),
    # For NC/MI: turn off treatment after repeal
    treated = ifelse(!is.na(repealed_year) & year >= repealed_year, 0, treated)
  )

# Add race-level treatment timing
state_quarter_race <- state_quarter_race %>%
  mutate(time = year + (quarter - 1) / 4) %>%
  left_join(state_fips %>% mutate(state_fips = as.numeric(state_fips)),
            by = "state_fips") %>%
  left_join(
    film_credits %>% select(state_abbr, treat_year),
    by = "state_abbr"
  ) %>%
  mutate(first_treat = ifelse(is.na(treat_year), 0, treat_year))

# ---------------------------------------------------------------------------
# 6. Create annual panel (collapsing quarters for CS-DiD)
# ---------------------------------------------------------------------------

state_year_all <- state_quarter_all %>%
  group_by(state_fips, state_abbr, year, first_treat, treat_year,
           credit_rate_pct, credit_type, repealed_year) %>%
  summarize(
    emp_512 = mean(emp_512, na.rm = TRUE),
    hir_512 = sum(hir_512, na.rm = TRUE),
    sep_512 = sum(sep_512, na.rm = TRUE),
    total_emp = mean(total_emp, na.rm = TRUE),
    avg_earn_512 = mean(avg_earn_512, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    emp_share_512 = emp_512 / total_emp * 1000,
    log_emp_512 = log(pmax(emp_512, 1)),
    treated = ifelse(!is.na(treat_year) & year >= treat_year, 1, 0),
    treated = ifelse(!is.na(repealed_year) & year >= repealed_year, 0, treated)
  )

state_year_race <- state_quarter_race %>%
  group_by(state_fips, state_abbr, year, race_cat, first_treat, treat_year) %>%
  summarize(
    emp_512 = mean(emp_512, na.rm = TRUE),
    hir_512 = sum(hir_512, na.rm = TRUE),
    sep_512 = sum(sep_512, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(log_emp_512 = log(pmax(emp_512, 1)))

# ---------------------------------------------------------------------------
# 7. Summary statistics
# ---------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")
cat(sprintf("States in sample: %d\n", n_distinct(state_year_all$state_fips)))
cat(sprintf("Treated states: %d\n",
            n_distinct(state_year_all$state_fips[state_year_all$first_treat > 0])))
cat(sprintf("Never-treated states: %d\n",
            n_distinct(state_year_all$state_fips[state_year_all$first_treat == 0])))
cat(sprintf("Years: %d-%d\n", min(state_year_all$year), max(state_year_all$year)))
cat(sprintf("Total obs (state-year): %d\n", nrow(state_year_all)))

# Pre-treatment SD of outcome for SDE
pre_sd <- state_year_all %>%
  filter(year < first_treat | first_treat == 0) %>%
  filter(year <= 2004) %>%
  pull(log_emp_512) %>%
  sd(na.rm = TRUE)
cat(sprintf("Pre-treatment SD(log emp 512): %.3f\n", pre_sd))

# Georgia spotlight
ga <- state_year_all %>% filter(state_abbr == "GA")
cat(sprintf("\nGeorgia: emp_512 in 2005 = %.0f, 2019 = %.0f, change = +%.0f%%\n",
            ga$emp_512[ga$year == 2005],
            ga$emp_512[ga$year == 2019],
            100 * (ga$emp_512[ga$year == 2019] / ga$emp_512[ga$year == 2005] - 1)))

# ---------------------------------------------------------------------------
# 8. Save
# ---------------------------------------------------------------------------

saveRDS(state_year_all, "../data/state_year_all.rds")
saveRDS(state_year_race, "../data/state_year_race.rds")
saveRDS(state_quarter_all, "../data/state_quarter_all.rds")
saveRDS(film_credits, "../data/film_credits.rds")

cat("\n02_clean_data.R complete.\n")
