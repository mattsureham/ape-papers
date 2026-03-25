# 02_clean_data.R — Clean CMS GV PUF and construct DiD panel
# apep_0920: MAID Laws and End-of-Life Medicare Spending

source("00_packages.R")

data_dir <- "../data"

# --- Load raw data ---
raw <- readRDS(file.path(data_dir, "cms_gv_puf_raw.rds"))
cat("Raw data:", nrow(raw), "rows x", ncol(raw), "cols\n")

# ============================================================================
# STEP 1: Filter to state-level, all-ages observations
# ============================================================================

# Keep only state-level data (exclude county and national)
state_data <- raw %>%
  filter(BENE_GEO_LVL == "State") %>%
  filter(BENE_AGE_LVL == "All") %>%  # All ages (not age-specific subgroups)
  select(
    year = YEAR,
    state_name = BENE_GEO_DESC,
    state_fips = BENE_GEO_CD,
    # Beneficiary counts
    benes_total = BENES_TOTAL_CNT,
    benes_ffs = BENES_FFS_CNT,
    bene_avg_age = BENE_AVG_AGE,
    bene_female_pct = BENE_FEML_PCT,
    bene_white_pct = BENE_RACE_WHT_PCT,
    bene_black_pct = BENE_RACE_BLACK_PCT,
    bene_hispanic_pct = BENE_RACE_HSPNC_PCT,
    bene_dual_pct = BENE_DUAL_PCT,
    bene_risk_score = BENE_AVG_RISK_SCRE,
    ma_rate = MA_PRTCPTN_RATE,
    # Total spending
    tot_stdzd_pymt_pc = TOT_MDCR_STDZD_PYMT_PC,
    # Inpatient
    ip_stdzd_pymt_pc = IP_MDCR_STDZD_PYMT_PC,
    ip_pymt_pct = IP_MDCR_STDZD_PYMT_PCT,
    ip_stays_per_1000 = IP_CVRD_STAYS_PER_1000_BENES,
    ip_days_per_1000 = IP_CVRD_DAYS_PER_1000_BENES,
    readmission_pct = ACUTE_HOSP_READMSN_PCT,
    # Hospice
    hospc_stdzd_pymt_pc = HOSPC_MDCR_STDZD_PYMT_PC,
    hospc_pymt_pct = HOSPC_MDCR_STDZD_PYMT_PCT,
    hospc_pymt_per_user = HOSPC_MDCR_STDZD_PYMT_PER_USER,
    hospc_users_pct = BENES_HOSPC_PCT,
    hospc_stays_per_1000 = HOSPC_CVRD_STAYS_PER_1000_BENES,
    hospc_days_per_1000 = HOSPC_CVRD_DAYS_PER_1000_BENES,
    # ER
    er_visits_per_1000 = ER_VISITS_PER_1000_BENES,
    # SNF
    snf_stdzd_pymt_pc = SNF_MDCR_STDZD_PYMT_PC,
    snf_pymt_pct = SNF_MDCR_STDZD_PYMT_PCT,
    # Home health
    hh_stdzd_pymt_pc = HH_MDCR_STDZD_PYMT_PC,
    hh_pymt_pct = HH_MDCR_STDZD_PYMT_PCT
  )

# Exclude territories and aggregates (PR, VI, Territory, ZZ)
state_data <- state_data %>%
  filter(!state_name %in% c("PR", "VI", "Territory", "ZZ"))

cat("State-level panel:", nrow(state_data), "state-years\n")
cat("States:", n_distinct(state_data$state_name), "\n")
cat("Years:", paste(range(state_data$year), collapse = "-"), "\n")

# ============================================================================
# STEP 2: Add MAID treatment coding
# ============================================================================

# Medical Aid in Dying (MAID) law effective dates
# Source: Death with Dignity National Center; state legislation records
maid_laws <- tribble(
  ~state_name, ~maid_year,  ~maid_date,
  "OR",        1997,        "1997-10-27",  # Death with Dignity Act
  "WA",        2009,        "2009-03-05",  # Washington Death with Dignity Act (I-1000)
  "MT",        2010,        "2010-01-01",  # Baxter v. Montana court ruling (Dec 2009)
  "VT",        2013,        "2013-05-20",  # Patient Choice and Control at End of Life Act
  "CA",        2016,        "2016-06-09",  # End of Life Option Act
  "CO",        2016,        "2016-12-16",  # End of Life Options Act (Prop 106)
  "DC",        2017,        "2017-02-18",  # Death with Dignity Act
  "HI",        2019,        "2019-01-01",  # Our Care Our Choice Act
  "NJ",        2019,        "2019-08-01",  # Aid in Dying for the Terminally Ill Act
  "ME",        2019,        "2019-09-19",  # Death with Dignity Act
  "NM",        2021,        "2021-06-18"   # Elizabeth Whitefield End-of-Life Options Act
)

# Merge MAID treatment into panel
panel <- state_data %>%
  left_join(maid_laws %>% select(state_name, maid_year), by = "state_name") %>%
  mutate(
    # Treatment indicator: 1 if MAID law is in effect
    maid_enacted = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    # First treatment year for CS-DiD (0 = never treated)
    first_treat = if_else(!is.na(maid_year), as.integer(maid_year), 0L),
    # Treatment cohort labels
    cohort = case_when(
      is.na(maid_year) ~ "Never treated",
      maid_year <= 2013 ~ "Always treated (pre-2014)",
      TRUE ~ paste0("Cohort ", maid_year)
    )
  )

cat("\n=== Treatment Assignment ===\n")
cat("Treated states:\n")
panel %>%
  filter(!is.na(maid_year)) %>%
  distinct(state_name, maid_year, cohort) %>%
  arrange(maid_year) %>%
  print(n = 20)

cat("\nNever-treated states:", sum(panel$cohort == "Never treated") / n_distinct(panel$year), "\n")

# For Callaway-Sant'Anna, we need to handle "always treated" states
# States treated before our sample window (OR 1997, WA 2009, MT 2010, VT 2013)
# are "always treated" and should be EXCLUDED from the CS estimator
# (CS requires either never-treated or not-yet-treated as controls)

panel <- panel %>%
  mutate(
    always_treated = (cohort == "Always treated (pre-2014)"),
    # For CS-DiD: set first_treat = 0 for always-treated (exclude from estimation)
    first_treat_cs = if_else(always_treated, 0L, first_treat)
  )

cat("\nSample composition:\n")
print(table(panel$cohort))

# ============================================================================
# STEP 3: Convert numeric columns and validate
# ============================================================================

# Ensure numeric columns are actually numeric
numeric_cols <- c("tot_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "hospc_stdzd_pymt_pc",
                  "hospc_pymt_pct", "hospc_users_pct", "hospc_stays_per_1000",
                  "hospc_days_per_1000", "ip_stays_per_1000", "ip_days_per_1000",
                  "er_visits_per_1000", "snf_stdzd_pymt_pc", "hh_stdzd_pymt_pc",
                  "bene_avg_age", "bene_dual_pct", "bene_risk_score", "ma_rate",
                  "readmission_pct", "benes_ffs", "ip_pymt_pct", "hospc_pymt_per_user",
                  "snf_pymt_pct", "hh_pymt_pct")

for (col in numeric_cols) {
  if (col %in% names(panel)) {
    panel[[col]] <- as.numeric(panel[[col]])
  }
}

# Check for missing values in key outcomes
cat("\n=== Missing Values in Key Outcomes ===\n")
key_outcomes <- c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "tot_stdzd_pymt_pc",
                  "hospc_users_pct", "er_visits_per_1000")
for (col in key_outcomes) {
  n_miss <- sum(is.na(panel[[col]]))
  cat(col, ":", n_miss, "missing (", round(100*n_miss/nrow(panel), 1), "%)\n")
}

# Create a state ID for panel estimation
panel <- panel %>%
  mutate(state_id = as.integer(factor(state_name)))

# ============================================================================
# STEP 4: Summary statistics
# ============================================================================

cat("\n=== Summary Statistics (State-Year Panel) ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state_name), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Treated states (ever):", sum(!is.na(panel$maid_year)) / n_distinct(panel$year), "\n")

# Pre-treatment summary for treated vs control
pre_treat_summary <- panel %>%
  filter(year <= 2015, !always_treated) %>%
  group_by(ever_treated = (first_treat > 0)) %>%
  summarise(
    n_states = n_distinct(state_name),
    avg_hospc_pc = mean(hospc_stdzd_pymt_pc, na.rm = TRUE),
    avg_ip_pc = mean(ip_stdzd_pymt_pc, na.rm = TRUE),
    avg_tot_pc = mean(tot_stdzd_pymt_pc, na.rm = TRUE),
    avg_hospc_pct = mean(hospc_users_pct, na.rm = TRUE),
    avg_er = mean(er_visits_per_1000, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment (2014-2015) means:\n")
print(pre_treat_summary)

# ============================================================================
# STEP 5: Save clean panel
# ============================================================================

saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
cat("\nSaved clean panel to:", file.path(data_dir, "panel_clean.rds"), "\n")

# Also save the county-level data for robustness
cat("\n=== Preparing county-level panel ===\n")
county_data <- raw %>%
  filter(BENE_GEO_LVL == "County") %>%
  filter(BENE_AGE_LVL == "All") %>%
  select(
    year = YEAR,
    county_name = BENE_GEO_DESC,
    county_fips = BENE_GEO_CD,
    benes_ffs = BENES_FFS_CNT,
    tot_stdzd_pymt_pc = TOT_MDCR_STDZD_PYMT_PC,
    ip_stdzd_pymt_pc = IP_MDCR_STDZD_PYMT_PC,
    hospc_stdzd_pymt_pc = HOSPC_MDCR_STDZD_PYMT_PC,
    hospc_users_pct = BENES_HOSPC_PCT,
    er_visits_per_1000 = ER_VISITS_PER_1000_BENES,
    snf_stdzd_pymt_pc = SNF_MDCR_STDZD_PYMT_PC,
    hh_stdzd_pymt_pc = HH_MDCR_STDZD_PYMT_PC,
    bene_avg_age = BENE_AVG_AGE,
    bene_dual_pct = BENE_DUAL_PCT,
    bene_risk_score = BENE_AVG_RISK_SCRE
  ) %>%
  mutate(
    across(c(tot_stdzd_pymt_pc, ip_stdzd_pymt_pc, hospc_stdzd_pymt_pc,
             hospc_users_pct, er_visits_per_1000, snf_stdzd_pymt_pc,
             hh_stdzd_pymt_pc, bene_avg_age, bene_dual_pct, bene_risk_score,
             benes_ffs),
           as.numeric),
    # Extract state FIPS from county FIPS (first 2 digits)
    state_fips = substr(county_fips, 1, 2)
  )

# Merge state-level treatment assignment
state_treat <- panel %>%
  distinct(state_fips, maid_year, first_treat, first_treat_cs, always_treated, cohort)

county_panel <- county_data %>%
  left_join(state_treat, by = "state_fips") %>%
  mutate(
    maid_enacted = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    county_id = as.integer(factor(county_fips))
  )

cat("County panel:", nrow(county_panel), "county-years\n")
cat("Counties:", n_distinct(county_panel$county_fips), "\n")

saveRDS(county_panel, file.path(data_dir, "county_panel_clean.rds"))
cat("Saved county panel to:", file.path(data_dir, "county_panel_clean.rds"), "\n")

cat("\n=== Data cleaning complete ===\n")
