## 02_clean_data.R — Build analysis panel with treatment coding
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

source("00_packages.R")

data_dir <- "../data"

## ---------- Load parsed tables ----------
cert <- readRDS(file.path(data_dir, "cert.rds"))
income <- readRDS(file.path(data_dir, "income.rds"))
ncic <- readRDS(file.path(data_dir, "ncic.rds"))

## ---------- State reform treatment coding ----------
## Sources: Institute for Justice "Policing for Profit" reports,
## NCSL civil asset forfeiture legislation databases, state statutes
## Treatment year = fiscal year in which reform first applies.
## Reform types: abolition, conviction_required, burden_raised, reporting_only
## Anti-circumvention: whether state also enacted anti-federal-adoption statute

reforms <- tribble(
  ~state, ~reform_year, ~reform_type,              ~anti_circumvention,
  # Full abolition (no civil forfeiture)
  "NM",   2015,         "abolition",                TRUE,
  "NE",   2016,         "abolition",                TRUE,
  "NC",   2000,         "abolition",                FALSE,  # longstanding

  # Conviction required for forfeiture
  "MT",   2015,         "conviction_required",      FALSE,
  "MN",   2014,         "conviction_required",      FALSE,
  "NH",   2016,         "conviction_required",      FALSE,
  "CT",   2017,         "conviction_required",      FALSE,
  "CO",   2017,         "conviction_required",      TRUE,
  "ND",   2017,         "conviction_required",      FALSE,
  "MS",   2017,         "conviction_required",      FALSE,
  "WI",   2018,         "conviction_required",      FALSE,
  "SD",   2019,         "conviction_required",      FALSE,
  "AZ",   2019,         "conviction_required",      FALSE,
  "HI",   2019,         "conviction_required",      FALSE,
  "MI",   2019,         "conviction_required",      FALSE,
  "KY",   2020,         "conviction_required",      FALSE,
  "ID",   2020,         "conviction_required",      FALSE,
  "KS",   2020,         "conviction_required",      FALSE,
  "IA",   2021,         "conviction_required",      FALSE,
  "AR",   2021,         "conviction_required",      FALSE,
  "SC",   2022,         "conviction_required",      FALSE,

  # Raised burden of proof (clear and convincing or higher)
  "FL",   2016,         "burden_raised",            FALSE,
  "CA",   2016,         "burden_raised",            FALSE,
  "MD",   2016,         "burden_raised",            FALSE,
  "OK",   2016,         "burden_raised",            FALSE,
  "PA",   2017,         "burden_raised",            FALSE,
  "OH",   2017,         "burden_raised",            FALSE,
  "VA",   2017,         "burden_raised",            FALSE,
  "WY",   2018,         "burden_raised",            FALSE,
  "GA",   2019,         "burden_raised",            FALSE,
  "MO",   2019,         "burden_raised",            FALSE,
  "IN",   2019,         "burden_raised",            FALSE,
  "IL",   2018,         "burden_raised",            FALSE,

  # Reporting/transparency requirements only
  "TX",   2019,         "reporting_only",           FALSE,
  "TN",   2018,         "reporting_only",           FALSE,
  "UT",   2017,         "reporting_only",           FALSE,
  "NV",   2019,         "reporting_only",           FALSE
)

# Anti-circumvention states (enacted bans on federal equitable sharing adoption)
# CO (2017), NM (2015), NE (2016), DC (2015)
reforms <- reforms %>%
  mutate(anti_circumvention = case_when(
    state %in% c("NM", "NE", "CO") ~ TRUE,
    TRUE ~ anti_circumvention
  ))

# Reform stringency score (for intensity analysis)
reforms <- reforms %>%
  mutate(reform_stringency = case_when(
    reform_type == "abolition" ~ 4,
    reform_type == "conviction_required" ~ 3,
    reform_type == "burden_raised" ~ 2,
    reform_type == "reporting_only" ~ 1
  ))

cat("Reform states:", nrow(reforms), "\n")
cat("By type:\n")
print(table(reforms$reform_type))
cat("Anti-circumvention:", sum(reforms$anti_circumvention), "\n")

## ---------- Clean certification data ----------
# Extract state from NCIC code
cert_clean <- cert %>%
  as_tibble() %>%
  mutate(
    state = trimws(NCIC_ST),
    ncic_cd = trimws(NCIC_CD),
    fy = as.integer(FORM_FY),
    budget = as.numeric(CURRENT_FY_BUDGET),
    justice_end_bal = as.numeric(JUSTICE_CURR_FY_END_BAL),
    treasury_end_bal = as.numeric(TREASURY_CURR_FY_END_BAL),
    agency_name = trimws(OAG_NM),
    cert_id = CERT_ID,
    esac_status = trimws(ESAC_STATUS_CD),
    agency_type_cd = trimws(ACA_AGCY_TYP_CD)
  ) %>%
  filter(esac_status == "A") %>%
  filter(state %in% c(state.abb, "DC")) %>%
  filter(fy >= 2009 & fy <= 2024)

cat("\nCleaned certifications:", nrow(cert_clean), "\n")
cat("Fiscal year range:", min(cert_clean$fy), "-", max(cert_clean$fy), "\n")
cat("Unique agencies:", n_distinct(cert_clean$ncic_cd), "\n")
cat("Unique states:", n_distinct(cert_clean$state), "\n")

## ---------- Merge income data ----------
income_clean <- income %>%
  as_tibble() %>%
  mutate(
    cert_id = CERT_ID,
    income_type = as.character(trimws(INCOME_TYP_CD)),
    justice_amt = as.numeric(JUSTICE_AMT),
    treasury_amt = as.numeric(TREASURY_AMT)
  ) %>%
  mutate(
    justice_amt = replace_na(justice_amt, 0),
    treasury_amt = replace_na(treasury_amt, 0),
    total_amt = justice_amt + treasury_amt
  )

# Income types (numeric in raw data):
# 1 = Equitable Sharing Funds Received (key outcome)
# 2 = ES Funds from Other LE Agencies/Task Forces
# 3 = Other income
# 4 = Interest Income

# Aggregate equitable sharing income per certification
income_by_cert <- income_clean %>%
  mutate(category = case_when(
    income_type == "1" ~ "es_funds",
    income_type == "2" ~ "es_funds_other",
    income_type == "4" ~ "es_interest",
    TRUE ~ "other_income"
  )) %>%
  group_by(cert_id, category) %>%
  summarize(total = sum(total_amt, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = category, values_from = total, values_fill = 0)

# Merge income onto certifications
panel <- cert_clean %>%
  left_join(income_by_cert, by = "cert_id") %>%
  mutate(across(any_of(c("es_funds", "es_funds_other", "es_interest", "other_income")),
                ~replace_na(., 0)))

# Ensure all income columns exist
for (col in c("es_funds", "es_funds_other", "es_interest", "other_income")) {
  if (!col %in% names(panel)) panel[[col]] <- 0
}
panel <- panel %>%
  mutate(es_total = es_funds + es_funds_other + es_interest)

## ---------- Merge treatment coding ----------
panel <- panel %>%
  left_join(reforms, by = "state") %>%
  mutate(
    # Never-reformed states get reform_year = 0 (for Callaway-Sant'Anna)
    reform_year = replace_na(reform_year, 0),
    reform_type = replace_na(reform_type, "never_reformed"),
    reform_stringency = replace_na(reform_stringency, 0),
    anti_circumvention = replace_na(anti_circumvention, FALSE),
    # Post-reform indicator
    post_reform = ifelse(reform_year > 0 & fy >= reform_year, 1L, 0L),
    # For CS-DiD: first_treat = reform_year (0 for never-treated)
    first_treat = reform_year
  )

## ---------- Collapse to agency-year panel ----------
# Some agencies may have multiple certifications per FY — aggregate
agency_panel <- panel %>%
  group_by(ncic_cd, state, fy, first_treat, reform_type, reform_stringency,
           anti_circumvention, post_reform, agency_name, agency_type_cd) %>%
  summarize(
    es_funds = sum(es_funds, na.rm = TRUE),
    es_total = sum(es_total, na.rm = TRUE),
    budget = mean(budget, na.rm = TRUE),
    n_certs = n(),
    .groups = "drop"
  ) %>%
  # Create log outcome (adding 1 for zeros)
  mutate(
    log_es_funds = log(es_funds + 1),
    log_es_total = log(es_total + 1),
    has_es = as.integer(es_funds > 0),
    es_funds_pc = es_funds / (budget + 1) * 1000  # per $1000 budget
  )

## ---------- Build balanced panel ----------
# For DiD, we want a balanced panel of agencies observed across FYs
# Keep agencies with at least 3 years of data
agency_counts <- agency_panel %>%
  group_by(ncic_cd) %>%
  summarize(n_years = n_distinct(fy), .groups = "drop")

# Keep agencies with >= 3 years
balanced <- agency_panel %>%
  inner_join(agency_counts %>% filter(n_years >= 3), by = "ncic_cd")

cat("\n--- Panel summary ---\n")
cat("Total agency-years:", nrow(balanced), "\n")
cat("Unique agencies:", n_distinct(balanced$ncic_cd), "\n")
cat("Fiscal year range:", min(balanced$fy), "-", max(balanced$fy), "\n")
cat("States:", n_distinct(balanced$state), "\n")
cat("\nBy reform type:\n")
print(table(balanced$reform_type, useNA = "always"))
cat("\nTreated agency-years:", sum(balanced$post_reform), "\n")
cat("Control agency-years:", sum(balanced$post_reform == 0), "\n")
cat("\nReform states:", n_distinct(balanced$state[balanced$first_treat > 0]), "\n")
cat("Never-reform states:", n_distinct(balanced$state[balanced$first_treat == 0]), "\n")

## ---------- State-level panel (for robustness) ----------
state_panel <- balanced %>%
  group_by(state, fy, first_treat, reform_type, reform_stringency,
           anti_circumvention, post_reform) %>%
  summarize(
    total_es_funds = sum(es_funds, na.rm = TRUE),
    total_es_total = sum(es_total, na.rm = TRUE),
    n_agencies = n_distinct(ncic_cd),
    n_agencies_with_es = sum(has_es),
    mean_es_funds = mean(es_funds, na.rm = TRUE),
    share_participating = n_agencies_with_es / n_agencies,
    .groups = "drop"
  ) %>%
  mutate(
    log_total_es = log(total_es_funds + 1),
    log_mean_es = log(mean_es_funds + 1)
  )

cat("\n--- State panel ---\n")
cat("State-years:", nrow(state_panel), "\n")

## ---------- Save ----------
saveRDS(balanced, file.path(data_dir, "agency_panel.rds"))
saveRDS(state_panel, file.path(data_dir, "state_panel.rds"))
saveRDS(reforms, file.path(data_dir, "reforms.rds"))

cat("\n=== Data cleaning complete ===\n")
