## 01_fetch_data.R — Fetch QWI data from Azure and SC activation dates
## apep_0655: The Employer Side of Deportation

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("=== Connecting to Azure ===\n")
con <- apep_azure_connect()

# ------------------------------------------------------------------
# 1. QWI race/ethnicity x NAICS sector data
# ------------------------------------------------------------------
cat("=== Fetching QWI race/ethnicity data from Azure ===\n")
cat("  Querying all states, county-level, race/ethnicity x NAICS sector...\n")

# We need: Emp, HirA, HirN, Sep, FrmJbGn, FrmJbLs, EarnS
# by county x quarter x industry x ethnicity (Hispanic A2 vs Non-Hispanic A1)
# Period: 2005-2015 (pre/post SC rollout 2008-2013)

qwi <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    CAST(year AS INTEGER) AS year,
    CAST(quarter AS INTEGER) AS quarter,
    industry,
    race AS race_code,
    ethnicity AS eth_code,
    CAST(Emp AS DOUBLE) AS emp,
    CAST(HirA AS DOUBLE) AS hir_all,
    CAST(HirN AS DOUBLE) AS hir_new,
    CAST(Sep AS DOUBLE) AS sep,
    CAST(FrmJbGn AS DOUBLE) AS frm_job_gn,
    CAST(FrmJbLs AS DOUBLE) AS frm_job_ls,
    CAST(EarnS AS DOUBLE) AS earn_s,
    CAST(sEmp AS VARCHAR) AS s_emp,
    CAST(sHirA AS VARCHAR) AS s_hir_all,
    CAST(sSep AS VARCHAR) AS s_sep
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE year BETWEEN 2005 AND 2015
    AND ethnicity IN ('A1', 'A2')
    AND race = 'A0'
    AND industry != '00'
")

cat(sprintf("  QWI rows fetched: %s\n", format(nrow(qwi), big.mark = ",")))
cat(sprintf("  Unique counties: %d\n", n_distinct(qwi$county_fips)))
cat(sprintf("  Year range: %d-%d\n", min(qwi$year), max(qwi$year)))
cat(sprintf("  Industries: %d\n", n_distinct(qwi$industry)))

# Data validation
stopifnot("No QWI data returned" = nrow(qwi) > 0)
stopifnot("Missing county FIPS" = !any(is.na(qwi$county_fips)))
stopifnot("Missing years" = !any(is.na(qwi$year)))

# ------------------------------------------------------------------
# 2. Secure Communities activation dates
# ------------------------------------------------------------------
cat("\n=== Processing SC activation dates ===\n")

sc_raw <- read.csv("../data/sc_activation_dates.csv", stringsAsFactors = FALSE)
cat(sprintf("  Raw SC records: %d\n", nrow(sc_raw)))

# Parse activation dates
sc_raw$act_date <- as.Date(sc_raw$activation_date, format = "%B %d, %Y")
stopifnot("Failed to parse SC dates" = !any(is.na(sc_raw$act_date)))

# Convert to year-quarter
sc_raw$act_year <- year(sc_raw$act_date)
sc_raw$act_quarter <- quarter(sc_raw$act_date)
sc_raw$act_yq <- sc_raw$act_year + (sc_raw$act_quarter - 1) / 4

cat(sprintf("  Activation date range: %s to %s\n",
            min(sc_raw$act_date), max(sc_raw$act_date)))

# ------------------------------------------------------------------
# 3. FIPS crosswalk — match county names to FIPS codes
# ------------------------------------------------------------------
cat("\n=== Building FIPS crosswalk ===\n")

# Get unique counties from QWI
qwi_counties <- qwi %>%
  distinct(county_fips) %>%
  mutate(
    state_fips = substr(sprintf("%05d", as.integer(county_fips)), 1, 2),
    county_fips_3 = substr(sprintf("%05d", as.integer(county_fips)), 3, 5)
  )

# State FIPS mapping
state_fips_map <- tibble::tribble(
  ~state_name, ~state_fips,
  "Alabama", "01", "Alaska", "02", "Arizona", "04", "Arkansas", "05",
  "California", "06", "Colorado", "08", "Connecticut", "09", "Delaware", "10",
  "District Of Columbia", "11", "Florida", "12", "Georgia", "13", "Guam", "66",
  "Hawaii", "15", "Idaho", "16", "Illinois", "17", "Indiana", "18",
  "Iowa", "19", "Kansas", "20", "Kentucky", "21", "Louisiana", "22",
  "Maine", "23", "Maryland", "24", "Massachusetts", "25", "Michigan", "26",
  "Minnesota", "27", "Mississippi", "28", "Missouri", "29", "Montana", "30",
  "Nebraska", "31", "Nevada", "32", "New Hampshire", "33", "New Jersey", "34",
  "New Mexico", "35", "New York", "36", "North Carolina", "37", "North Dakota", "38",
  "Northern Mariana Islands", "69", "Ohio", "39", "Oklahoma", "40", "Oregon", "41",
  "Pennsylvania", "42", "Puerto Rico", "72", "Rhode Island", "44",
  "South Carolina", "45", "South Dakota", "46", "Tennessee", "47", "Texas", "48",
  "U.S. Virgin Islands", "78", "Utah", "49", "Vermont", "50", "Virginia", "51",
  "Washington", "53", "West Virginia", "54", "Wisconsin", "55", "Wyoming", "56"
)

# Add state FIPS to SC data
sc_raw <- sc_raw %>%
  left_join(state_fips_map, by = c("state" = "state_name"))

cat(sprintf("  SC records with state FIPS: %d / %d\n",
            sum(!is.na(sc_raw$state_fips)), nrow(sc_raw)))

# For county-to-FIPS matching, use tidycensus fips_codes if available,
# otherwise build a crosswalk from the QWI county names
# We'll use a fuzzy approach: QWI has county FIPS, SC has county names
# The cleanest approach is to use the tidycensus built-in crosswalk

if (requireNamespace("tidycensus", quietly = TRUE)) {
  fips_xwalk <- tidycensus::fips_codes %>%
    mutate(
      county_clean = tolower(gsub(" County| Parish| Borough| Census Area| city| Municipality| Municipio", "",
                                  county, ignore.case = TRUE)),
      county_clean = trimws(county_clean),
      county_fips_5 = paste0(state_code, county_code)
    ) %>%
    select(state_name = state_name, county_clean, county_fips_5)
} else {
  # Fallback: install tidycensus
  install.packages("tidycensus", repos = "https://cloud.r-project.org")
  library(tidycensus)
  fips_xwalk <- fips_codes %>%
    mutate(
      county_clean = tolower(gsub(" County| Parish| Borough| Census Area| city| Municipality| Municipio", "",
                                  county, ignore.case = TRUE)),
      county_clean = trimws(county_clean),
      county_fips_5 = paste0(state_code, county_code)
    ) %>%
    select(state_name = state_name, county_clean, county_fips_5)
}

# Clean SC county names for matching
sc_raw <- sc_raw %>%
  mutate(
    county_clean = tolower(county),
    county_clean = gsub("saint ", "st. ", county_clean),
    county_clean = gsub("sainte ", "ste. ", county_clean),
    county_clean = trimws(county_clean)
  )

# Merge SC with FIPS
sc_matched <- sc_raw %>%
  left_join(fips_xwalk, by = c("state" = "state_name", "county_clean"))

matched_n <- sum(!is.na(sc_matched$county_fips_5))
cat(sprintf("  Matched to FIPS: %d / %d (%.1f%%)\n",
            matched_n, nrow(sc_matched), 100 * matched_n / nrow(sc_matched)))

# Handle unmatched — try alternate name patterns
unmatched <- sc_matched %>% filter(is.na(county_fips_5))
if (nrow(unmatched) > 0) {
  cat(sprintf("  Unmatched counties: %d\n", nrow(unmatched)))

  # Try matching without "St." conversion
  unmatched2 <- unmatched %>%
    select(-county_fips_5) %>%
    mutate(county_clean = tolower(county)) %>%
    left_join(fips_xwalk, by = c("state" = "state_name", "county_clean"))

  # Fill in newly matched
  newly_matched <- sum(!is.na(unmatched2$county_fips_5))
  cat(sprintf("  Additional matches with alternate names: %d\n", newly_matched))

  # Combine
  sc_matched <- bind_rows(
    sc_matched %>% filter(!is.na(county_fips_5)),
    unmatched2 %>% filter(!is.na(county_fips_5)),
    unmatched2 %>% filter(is.na(county_fips_5))
  )
}

# Keep only matched records for analysis
sc_final <- sc_matched %>%
  filter(!is.na(county_fips_5)) %>%
  select(county_fips = county_fips_5, state, county, act_date, act_year, act_quarter, act_yq) %>%
  distinct(county_fips, .keep_all = TRUE)

cat(sprintf("\n  Final SC activation dataset: %d counties with FIPS\n", nrow(sc_final)))
cat(sprintf("  First activation: %s\n", min(sc_final$act_date)))
cat(sprintf("  Last activation: %s\n", max(sc_final$act_date)))

# ------------------------------------------------------------------
# 4. Save processed data
# ------------------------------------------------------------------
cat("\n=== Saving data ===\n")
saveRDS(qwi, "../data/qwi_rh_raw.rds")
saveRDS(sc_final, "../data/sc_activation_dates.rds")

cat(sprintf("  Saved qwi_rh_raw.rds: %s rows\n", format(nrow(qwi), big.mark = ",")))
cat(sprintf("  Saved sc_activation_dates.rds: %d counties\n", nrow(sc_final)))
cat("=== Data fetch complete ===\n")

dbDisconnect(con, shutdown = TRUE)
