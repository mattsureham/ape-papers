## 02_clean_data.R — Merge and construct analysis variables for apep_0689
## Uses coastal proximity as flood risk proxy

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================
hmda <- readRDS(file.path(data_dir, "hmda_fl_raw.rds"))
acs  <- readRDS(file.path(data_dir, "acs_fl_with_coast.rds"))

# ============================================================
# 2. Clean HMDA
# ============================================================
cat("=== Cleaning HMDA ===\n")

# Construct tract FIPS (11-digit)
hmda[, tract_fips := as.character(census_tract)]
hmda[nchar(tract_fips) == 10, tract_fips := paste0("0", tract_fips)]
hmda <- hmda[nchar(tract_fips) == 11]

# Key outcome: denied = 1, originated = 0
hmda[, denied := as.integer(action_taken == 3)]

# Clean numeric fields
hmda[, income := as.numeric(income)]
hmda[, loan_amount := as.numeric(loan_amount)]
hmda[, property_value := as.numeric(property_value)]
hmda[, interest_rate := as.numeric(interest_rate)]

# County code (5-digit FIPS)
hmda[, county_fips := substr(tract_fips, 1, 5)]

# Race categories — CFPB codes: 1=AI/AN, 2=Asian, 3=Black, 4=NHPI, 5=White
hmda[, applicant_race_1 := as.character(applicant_race_1)]
hmda[, applicant_ethnicity_1 := as.character(applicant_ethnicity_1)]
hmda[, race_white := as.integer(applicant_race_1 == "5")]
hmda[, race_black := as.integer(applicant_race_1 == "3")]
hmda[, race_hispanic := as.integer(applicant_ethnicity_1 == "1")]
hmda[, race_minority := as.integer(!(applicant_race_1 == "5" & applicant_ethnicity_1 != "1"))]

# Denial reason categories
hmda[, denial_reason_1 := as.character(denial_reason_1)]
hmda[, denial_dti := as.integer(denial_reason_1 == "1")]
hmda[, denial_credit := as.integer(denial_reason_1 == "3")]
hmda[, denial_collateral := as.integer(denial_reason_1 == "4")]
hmda[, denial_cash := as.integer(denial_reason_1 == "5")]

# Loan purpose
hmda[, purchase := as.integer(loan_purpose == 1)]

# Filter: keep owner-occupied, valid income and loan amount
hmda_clean <- hmda[
  occupancy_type == 1 &
  !is.na(income) & income > 0 &
  !is.na(loan_amount) & loan_amount > 0
]

cat(sprintf("HMDA after cleaning: %s (from %s)\n",
            format(nrow(hmda_clean), big.mark = ","),
            format(nrow(hmda), big.mark = ",")))

# ============================================================
# 3. Clean ACS + coastal distance
# ============================================================
cat("\n=== Cleaning ACS ===\n")

acs_dt <- as.data.table(acs)
acs_dt[, tract_fips := GEOID]

# Construct tract-level controls
acs_dt[, `:=`(
  pct_minority     = 1 - (white_popE / pmax(total_popE, 1)),
  pct_black        = black_popE / pmax(total_popE, 1),
  pct_hispanic     = hispanic_popE / pmax(total_popE, 1),
  pct_poverty      = poverty_popE / pmax(total_pov_denomE, 1),
  pct_owner_occ    = owner_occupiedE / pmax(total_housingE, 1),
  pct_bachelor     = bachelor_plusE / pmax(total_25plusE, 1),
  pct_vacant       = vacancy_rate_nE / pmax(total_units_occE, 1),
  log_median_income = log(pmax(median_incomeE, 1)),
  log_median_value  = log(pmax(median_valueE, 1))
)]

# Coastal distance: already computed in 01_fetch_data.R
# Key variable: coast_dist_km — lower = more coastal = more flood risk

# Flood exposure proxy: inverse coastal distance (standardized)
acs_dt[, flood_exposure := -coast_dist_km]  # More negative = further from coast
acs_dt[, flood_exposure_std := (flood_exposure - mean(flood_exposure, na.rm = TRUE)) /
         sd(flood_exposure, na.rm = TRUE)]

# Coastal indicator: within 10km of coast
acs_dt[, coastal_10km := as.integer(coast_dist_km <= 10)]
acs_dt[, coastal_5km := as.integer(coast_dist_km <= 5)]
acs_dt[, coastal_20km := as.integer(coast_dist_km <= 20)]

# Coastal distance quartiles
acs_dt[, coast_dist_q4 := cut(coast_dist_km,
                                breaks = quantile(coast_dist_km, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                                labels = c("Q1_Coastal", "Q2", "Q3", "Q4_Inland"),
                                include.lowest = TRUE)]

cat(sprintf("ACS tracts: %s\n", nrow(acs_dt)))
cat(sprintf("Coastal (<10km): %d, Inland (>10km): %d\n",
            sum(acs_dt$coastal_10km), sum(!acs_dt$coastal_10km)))

# Select tract-level controls
acs_controls <- acs_dt[, .(
  tract_fips, total_popE, total_housingE, median_incomeE, median_valueE,
  pct_minority, pct_black, pct_hispanic, pct_poverty,
  pct_owner_occ, pct_bachelor, pct_vacant,
  log_median_income, log_median_value,
  coast_dist_km, flood_exposure, flood_exposure_std,
  coastal_10km, coastal_5km, coastal_20km, coast_dist_q4,
  lon, lat
)]

# ============================================================
# 4. Merge datasets
# ============================================================
cat("\n=== Merging datasets ===\n")

hmda_merged <- merge(hmda_clean, acs_controls, by = "tract_fips", all.x = TRUE)

# Drop observations with missing ACS data
hmda_merged <- hmda_merged[!is.na(coast_dist_km)]
hmda_merged <- hmda_merged[total_popE > 100]

# Income terciles (applicant level)
hmda_merged[, income_tercile := cut(income,
                                     breaks = quantile(income, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
                                     labels = c("Low", "Middle", "High"),
                                     include.lowest = TRUE)]

cat(sprintf("Final merged dataset: %s observations in %s tracts, %s counties\n",
            format(nrow(hmda_merged), big.mark = ","),
            length(unique(hmda_merged$tract_fips)),
            length(unique(hmda_merged$county_fips))))

# ============================================================
# 5. Tract-level aggregated dataset
# ============================================================
tract_agg <- hmda_merged[, .(
  n_applications = .N,
  n_denied = sum(denied),
  n_originated = sum(denied == 0),
  denial_rate = mean(denied),
  mean_interest = mean(interest_rate, na.rm = TRUE),
  mean_income = mean(income, na.rm = TRUE),
  mean_loan_amount = mean(loan_amount, na.rm = TRUE),
  pct_purchase = mean(purchase, na.rm = TRUE),
  pct_minority_app = mean(race_minority, na.rm = TRUE),
  n_denial_dti = sum(denial_dti, na.rm = TRUE),
  n_denial_credit = sum(denial_credit, na.rm = TRUE),
  n_denial_collateral = sum(denial_collateral, na.rm = TRUE)
), by = .(tract_fips, county_fips)]

tract_agg <- merge(tract_agg, acs_controls, by = "tract_fips", all.x = TRUE)

cat(sprintf("Tract-level dataset: %s tracts\n", nrow(tract_agg)))

# ============================================================
# 6. Save analysis-ready datasets
# ============================================================
saveRDS(hmda_merged, file.path(data_dir, "analysis_individual.rds"))
saveRDS(tract_agg, file.path(data_dir, "analysis_tract.rds"))

cat("\n=== Cleaning complete. Analysis datasets saved. ===\n")
