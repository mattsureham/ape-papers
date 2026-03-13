# 01_fetch_data.R — Fetch Census BDS data and code treatment
# apep_0653: Data Breach Notification Laws and Firm Dynamics

source("00_packages.R")

# ==============================================================================
# 1. Fetch Census BDS — State × Year (aggregate)
# ==============================================================================

cat("Fetching BDS aggregate state-year data...\n")

bds_vars <- "FIRM,ESTAB,ESTABS_ENTRY,ESTABS_ENTRY_RATE,ESTABS_EXIT,ESTABS_EXIT_RATE,EMP,JOB_CREATION,JOB_CREATION_RATE,JOB_DESTRUCTION,JOB_DESTRUCTION_RATE,NET_JOB_CREATION,NET_JOB_CREATION_RATE"

bds_agg <- data.frame()
for (yr in 1998:2022) {
  url <- paste0("https://api.census.gov/data/timeseries/bds?get=", bds_vars,
                 "&for=state:*&YEAR=", yr)
  resp <- GET(url)
  if (status_code(resp) != 200) {
    cat("  BDS aggregate failed for year", yr, "- status:", status_code(resp), "\n")
    next
  }
  raw <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$YEAR <- yr
  bds_agg <- bind_rows(bds_agg, df)
  cat("  Year", yr, ":", nrow(df), "states\n")
}

stopifnot("ESTABS_ENTRY_RATE" %in% names(bds_agg))
stopifnot(nrow(bds_agg) > 1000)
cat("BDS aggregate:", nrow(bds_agg), "rows\n")

# ==============================================================================
# 2. Fetch Census BDS — State × Year × NAICS sector
# ==============================================================================

cat("\nFetching BDS by NAICS sector...\n")

# Key sectors for mechanism test
naics_codes <- c("11", "23", "31-33", "42", "44-45", "51", "52", "53", "54", "56", "62", "72")
naics_labels <- c("Agriculture", "Construction", "Manufacturing", "Wholesale",
                   "Retail", "Information", "Finance", "Real Estate",
                   "Professional/Technical", "Admin/Waste", "Healthcare", "Accommodation/Food")

bds_naics <- data.frame()
for (yr in 1998:2022) {
  for (i in seq_along(naics_codes)) {
    nc <- naics_codes[i]
    url <- paste0("https://api.census.gov/data/timeseries/bds?get=ESTAB,ESTABS_ENTRY,ESTABS_ENTRY_RATE,ESTABS_EXIT,ESTABS_EXIT_RATE,EMP,JOB_CREATION,JOB_DESTRUCTION",
                   "&for=state:*&YEAR=", yr, "&NAICS=", nc)
    resp <- GET(url)
    if (status_code(resp) != 200) next
    raw <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(raw)
    if (is.null(parsed) || length(parsed) < 2) next
    df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    df$YEAR <- yr
    df$naics_label <- naics_labels[i]
    bds_naics <- bind_rows(bds_naics, df)
  }
  if (yr %% 5 == 0) cat("  NAICS year", yr, "done\n")
}

cat("BDS NAICS:", nrow(bds_naics), "rows\n")
stopifnot(nrow(bds_naics) > 5000)

# ==============================================================================
# 3. Hand-code BNL treatment dates
# ==============================================================================
# Source: NCSL Security Breach Notification Laws (2024 compilation)
# Cross-referenced with Perkins Coie State Data Breach Chart

bnl_laws <- tribble(
  ~state_fips, ~state_abbr, ~bnl_year,
  "01", "AL", 2018,
  "02", "AK", 2009,
  "04", "AZ", 2006,
  "05", "AR", 2005,
  "06", "CA", 2003,
  "08", "CO", 2006,
  "09", "CT", 2005,
  "10", "DE", 2005,
  "11", "DC", 2007,
  "12", "FL", 2005,
  "13", "GA", 2005,
  "15", "HI", 2007,
  "16", "ID", 2006,
  "17", "IL", 2006,
  "18", "IN", 2006,
  "19", "IA", 2008,
  "20", "KS", 2006,
  "21", "KY", 2014,
  "22", "LA", 2006,
  "23", "ME", 2006,
  "24", "MD", 2008,
  "25", "MA", 2008,
  "26", "MI", 2007,
  "27", "MN", 2006,
  "28", "MS", 2011,
  "29", "MO", 2009,
  "30", "MT", 2006,
  "31", "NE", 2006,
  "32", "NV", 2005,
  "33", "NH", 2007,
  "34", "NJ", 2006,
  "35", "NM", 2017,
  "36", "NY", 2005,
  "37", "NC", 2005,
  "38", "ND", 2005,
  "39", "OH", 2005,
  "40", "OK", 2006,
  "41", "OR", 2007,
  "42", "PA", 2006,
  "44", "RI", 2005,
  "45", "SC", 2009,
  "46", "SD", 2018,
  "47", "TN", 2005,
  "48", "TX", 2005,
  "49", "UT", 2006,
  "50", "VT", 2007,
  "51", "VA", 2008,
  "53", "WA", 2005,
  "54", "WV", 2008,
  "55", "WI", 2006,
  "56", "WY", 2007
)

cat("\nTreatment coding:\n")
cat("  States with BNL:", nrow(bnl_laws), "\n")
cat("  Adoption year range:", min(bnl_laws$bnl_year), "-", max(bnl_laws$bnl_year), "\n")
cat("  2005 mega-cohort:", sum(bnl_laws$bnl_year == 2005), "states\n")

# Cohort distribution
cohort_dist <- bnl_laws %>% count(bnl_year)
cat("\nCohort distribution:\n")
print(cohort_dist)

# ==============================================================================
# 4. Save raw data
# ==============================================================================

saveRDS(bds_agg, "../data/bds_aggregate.rds")
saveRDS(bds_naics, "../data/bds_naics.rds")
saveRDS(bnl_laws, "../data/bnl_laws.rds")

cat("\n-> data/bds_aggregate.rds (", nrow(bds_agg), " rows)")
cat("\n-> data/bds_naics.rds (", nrow(bds_naics), " rows)")
cat("\n-> data/bnl_laws.rds (", nrow(bnl_laws), " rows)\n")
