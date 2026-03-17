## 01_fetch_data.R — Data acquisition
## apep_0714: Marijuana Expungement × Black Employment DDD
## REAL DATA ONLY — no simulated fallbacks

source("code/00_packages.R")
source("../../../scripts/lib/azure_data.R")

# ============================================================
# 1. QWI RACE PANEL — Azure DuckDB
# ============================================================

cat("Connecting to Azure QWI race panel...\n")
con <- apep_azure_connect()

# County FIPS numeric ranges for our 19 target states
# geography column in QWI is integer (e.g. CA = 6001-6999, not 06001-06999)
state_fips <- c(
  CA="06", IL="17", NJ="34", VA="51", NY="36",
  CO="08", WA="53", OR="41", AK="02",
  TX="48", FL="12", GA="13", NC="37", OH="39",
  MI="26", PA="42", WI="55", MN="27", AZ="04"
)

# Build BETWEEN clauses for each state's county FIPS range
fips_ranges <- sapply(state_fips, function(f) {
  lo <- as.integer(f) * 1000 + 1
  hi <- as.integer(f) * 1000 + 999
  sprintf("(geography BETWEEN %d AND %d)", lo, hi)
})
geo_filter <- paste(fips_ranges, collapse = " OR ")

cat("Fetching QWI race×ethnicity panel from Azure (2013-2023)...\n")
cat("Using path: az://derived/qwi/rh/ns/*.parquet\n")

# Single query across all state files using wildcard
# rh/ns = race×ethnicity, NAICS sector level
# industry='00' = all industries aggregate
query <- sprintf("
  SELECT
    CAST(geography AS VARCHAR) AS county_fips_num,
    year,
    quarter,
    race,
    Emp,
    EarnS
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE
    (%s)
    AND ethnicity = 'A0'
    AND race IN ('A1', 'A2')
    AND industry = '00'
    AND firmage = '0'
    AND firmsize = '0'
    AND sex = '0'
    AND agegrp = 'A00'
    AND education = 'E0'
    AND year BETWEEN 2013 AND 2023
  ORDER BY county_fips_num, year, quarter, race
", geo_filter)

qwi_raw <- tryCatch({
  df <- DBI::dbGetQuery(con, query)
  if (nrow(df) == 0) stop("No rows returned from QWI panel query")
  df
}, error = function(e) {
  stop(sprintf("FATAL: QWI data fetch failed: %s", e$message))
})

# Add state FIPS from county FIPS
qwi_raw <- qwi_raw %>%
  mutate(
    county_fips_num = as.integer(county_fips_num),
    state_fips_num = county_fips_num %/% 1000,
    state_fips = sprintf("%02d", state_fips_num),
    county_fips = sprintf("%05d", county_fips_num)
  )

cat(sprintf("\nTotal QWI rows: %d\n", nrow(qwi_raw)))
cat(sprintf("States (FIPS): %s\n", paste(sort(unique(qwi_raw$state_fips)), collapse=", ")))
cat(sprintf("Years: %d-%d\n", min(qwi_raw$year), max(qwi_raw$year)))
cat(sprintf("Counties: %d\n", length(unique(qwi_raw$county_fips))))

if (nrow(qwi_raw) < 10000) {
  stop("FATAL: Too few rows — data fetch appears incomplete")
}

# Save raw QWI
saveRDS(qwi_raw, "data/qwi_raw.rds")
cat("QWI raw saved.\n")

# ============================================================
# 2. STATE MARIJUANA LAW DATES (self-constructed from legislative records)
# ============================================================

cat("Building marijuana law timeline...\n")

marijuana_laws <- tibble(
  state = c("CA", "IL", "NJ", "VA", "NY",     # expunge states
            "CO", "WA", "OR", "AK",             # legalize-only
            "TX", "FL", "GA", "NC", "OH",       # never-legalized
            "MI", "PA", "WI", "MN", "AZ"),      # never-legalized
  state_fips = c("06", "17", "34", "51", "36",
                 "08", "53", "41", "02",
                 "48", "12", "13", "37", "39",
                 "26", "42", "55", "27", "04"),
  group = c(rep("expunge", 5), rep("legalize_only", 4), rep("never_legal", 10)),
  # Date of legal recreational RETAIL sales
  retail_date = as.Date(c(
    "2018-01-01",  # CA: Jan 1 2018
    "2020-01-01",  # IL: Jan 1 2020
    "2022-02-22",  # NJ: Feb 22 2022
    "2021-07-01",  # VA: Jul 1 2021
    "2022-12-29",  # NY: Dec 29 2022
    "2014-01-01",  # CO: Jan 1 2014
    "2014-07-08",  # WA: Jul 8 2014
    "2015-10-01",  # OR: Oct 1 2015
    "2016-10-29",  # AK: Oct 29 2016
    NA, NA, NA, NA, NA,  # never
    NA, NA, NA, NA, NA   # never
  )),
  # Date of automatic expungement (start of record clearing)
  expunge_date = as.Date(c(
    "2019-01-01",  # CA: AB 1793, Jan 2019
    "2020-01-01",  # IL: CRTA automatic, Jan 2020
    "2021-02-22",  # NJ: signed Feb 2021, automatic
    "2021-07-01",  # VA: MRTA effective Jul 2021
    "2021-03-31",  # NY: MRTA signed Mar 2021
    NA, NA, NA, NA,  # legalize-only: no auto expunge
    NA, NA, NA, NA, NA,  # never
    NA, NA, NA, NA, NA   # never
  ))
)

# Convert to quarter numbers for merge
marijuana_laws <- marijuana_laws %>%
  mutate(
    expunge_year = year(expunge_date),
    expunge_qtr = quarter(expunge_date),
    retail_year = year(retail_date),
    retail_qtr = quarter(retail_date)
  )

write_csv(marijuana_laws, "data/marijuana_laws.csv")
cat("Marijuana law timeline saved.\n")
cat("Treatment groups:\n")
print(table(marijuana_laws$group))

# ============================================================
# 3. COUNTY CONTROLS — ACS via Census API
# ============================================================

cat("Fetching county demographics from Census ACS 2019 5-year...\n")
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not set")

# ACS 5-year 2019: county-level Black pop share, poverty rate, median income
acs_vars <- "B01003_001E,B02001_003E,B17001_002E,B19013_001E"
acs_states <- paste(state_fips, collapse=",")

acs_list <- list()
for (fips_val in state_fips) {
  url <- sprintf(
    "https://api.census.gov/data/2019/acs/acs5?get=%s,NAME&for=county:*&in=state:%s&key=%s",
    acs_vars, fips_val, census_key
  )
  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: Census API failed for state %s (status %d)", fips_val, httr::status_code(resp)))
  }
  data <- httr::content(resp, as = "parsed")
  # data[[1]] is header row
  headers <- unlist(data[[1]])
  rows <- lapply(data[-1], function(x) setNames(as.data.frame(t(unlist(x))), headers))
  acs_list[[fips_val]] <- bind_rows(rows)
}

acs_raw <- bind_rows(acs_list)
cat(sprintf("ACS counties fetched: %d\n", nrow(acs_raw)))

# Clean ACS
acs_clean <- acs_raw %>%
  mutate(
    county_fips = paste0(state, county),
    total_pop = as.numeric(B01003_001E),
    black_pop = as.numeric(B02001_003E),
    poverty_pop = as.numeric(B17001_002E),
    median_income = as.numeric(B19013_001E)
  ) %>%
  mutate(
    black_share = black_pop / total_pop,
    poverty_rate = poverty_pop / total_pop
  ) %>%
  select(county_fips, total_pop, black_pop, black_share, poverty_pop, poverty_rate, median_income) %>%
  filter(!is.na(total_pop) & total_pop > 0)

write_csv(acs_clean, "data/acs_county_controls.csv")
cat(sprintf("ACS clean: %d counties\n", nrow(acs_clean)))

# ============================================================
# 4. SUMMARY VALIDATION
# ============================================================

cat("\n=== DATA SUMMARY ===\n")
cat(sprintf("QWI panel: %d county-race-quarter obs\n", nrow(qwi_raw)))
cat(sprintf("Expunge states: %d\n", sum(marijuana_laws$group=="expunge")))
cat(sprintf("Legalize-only states: %d\n", sum(marijuana_laws$group=="legalize_only")))
cat(sprintf("Never-legalized states: %d\n", sum(marijuana_laws$group=="never_legal")))
cat(sprintf("ACS county controls: %d counties\n", nrow(acs_clean)))

# Quick sanity: Black employment visible in treated states
black_check <- qwi_raw %>%
  filter(race == "A2", state_fips %in% c("06","17","34","51","36")) %>%
  filter(!is.na(Emp) & Emp > 0) %>%
  group_by(state_fips, year) %>%
  summarise(n_counties = n_distinct(county_fips), avg_emp = mean(Emp, na.rm=TRUE), .groups="drop")

cat("\nBlack employment coverage in expunge states:\n")
print(black_check %>% filter(year %in% c(2016, 2019, 2022)))

if (nrow(black_check) == 0) {
  stop("FATAL: No Black employment data found in expunge states")
}

cat("\nData fetch complete.\n")
DBI::dbDisconnect(con)
