# 01_fetch_data.R — Fetch QWI data from Azure
# apep_0756: Fair Workweek, Unfair Turnover?

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ── Treatment assignment ──────────────────────────────────────────────────────
# Predictive scheduling law adoption dates and affected county FIPS codes
treatment_df <- tribble(
  ~jurisdiction, ~treat_quarter, ~fips,
  # San Francisco, CA — July 2015
  "San Francisco", "2015.3", "06075",
  # Seattle, WA — July 2017
  "Seattle", "2017.3", "53033",
  # NYC boroughs — November 2017 (effective quarter: 2017Q4)
  "New York City", "2017.4", "36005",
  "New York City", "2017.4", "36047",
  "New York City", "2017.4", "36061",
  "New York City", "2017.4", "36081",
  "New York City", "2017.4", "36085",
  # Oregon statewide — July 2018
  "Oregon", "2018.3", NA_character_,
  # Philadelphia, PA — January 2020
  "Philadelphia", "2020.1", "42101",
  # Chicago, IL — July 2020
  "Chicago", "2020.3", "17031"
)

# Oregon: all 36 counties (FIPS 41001–41071)
oregon_fips <- sprintf("41%03d", seq(1, 71, by = 2))
oregon_rows <- tibble(
  jurisdiction = "Oregon",
  treat_quarter = "2018.3",
  fips = oregon_fips
)

treatment_df <- treatment_df %>%
  filter(!is.na(fips)) %>%
  bind_rows(oregon_rows)

cat("Treatment counties:", nrow(treatment_df), "\n")

# ── Define industries ─────────────────────────────────────────────────────────
# Treated industries (covered by scheduling laws)
treated_industries <- c("72", "44-45")
# Control industries (NOT covered)
control_industries <- c("31-33", "54")
all_industries <- c(treated_industries, control_industries)

# ── Fetch QWI from Azure ─────────────────────────────────────────────────────
cat("Querying QWI from Azure (sex x age, NAICS sector)...\n")

# Query all counties for our industries, 2012-2022
qwi_query <- paste0(
  "SELECT * FROM 'az://derived/qwi/sa/ns/*.parquet' ",
  "WHERE industry IN ('72', '44-45', '31-33', '54') ",
  "AND agegrp = 'A00' ",
  "AND sex = '0' ",
  "AND year >= 2012 AND year <= 2022"
)

df_all <- dbGetQuery(con, qwi_query)
cat("Raw QWI rows (all counties, 4 industries, 2012-2022):", nrow(df_all), "\n")

stopifnot("No data returned from Azure" = nrow(df_all) > 0)

# ── Also fetch age-specific data for heterogeneity ───────────────────────────
cat("Querying age-specific QWI for heterogeneity analysis...\n")

qwi_age_query <- paste0(
  "SELECT * FROM 'az://derived/qwi/sa/ns/*.parquet' ",
  "WHERE industry IN ('72', '44-45', '31-33', '54') ",
  "AND agegrp IN ('A01', 'A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08') ",
  "AND sex = '0' ",
  "AND year >= 2012 AND year <= 2022"
)

df_age <- dbGetQuery(con, qwi_age_query)
cat("Age-specific QWI rows:", nrow(df_age), "\n")

apep_azure_disconnect(con)

# ── Save raw data ────────────────────────────────────────────────────────────
saveRDS(df_all, "../data/qwi_raw.rds")
saveRDS(df_age, "../data/qwi_age_raw.rds")
saveRDS(treatment_df, "../data/treatment_assignment.rds")

cat("Data saved to data/\n")
cat("  qwi_raw.rds:", format(file.size("../data/qwi_raw.rds"), big.mark = ","), "bytes\n")
cat("  qwi_age_raw.rds:", format(file.size("../data/qwi_age_raw.rds"), big.mark = ","), "bytes\n")
