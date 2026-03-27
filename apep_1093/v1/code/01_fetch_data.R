# 01_fetch_data.R — Fetch QWI race x 3-digit NAICS data from Azure
# Pay Transparency Laws and the Racial New-Hire Earnings Gap

source("00_packages.R")

# CRITICAL: Force-load Azure connection string from .env
# (bash source truncates at semicolons)
env_path <- normalizePath(file.path("..", "..", "..", "..", ".env"), mustWork = FALSE)
env_lines <- readLines(env_path, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\']|["\']$', '', val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

# ---- Treatment coding ----
# Salary-range-in-job-posting mandate adoption dates
treatment_states <- data.frame(
  state_fips = c("08", "53", "06", "36", "15", "17", "27"),
  state_abbr = c("CO", "WA", "CA", "NY", "HI", "IL", "MN"),
  adopt_date = as.Date(c(
    "2021-01-01",  # Colorado
    "2023-01-01",  # Washington
    "2023-01-01",  # California
    "2023-09-17",  # New York (statewide)
    "2024-01-01",  # Hawaii
    "2025-01-01",  # Illinois
    "2025-01-01"   # Minnesota
  ))
)
# Convert to adoption quarter (year * 4 + quarter)
treatment_states$adopt_year <- as.integer(format(treatment_states$adopt_date, "%Y"))
treatment_states$adopt_qtr <- as.integer(format(treatment_states$adopt_date, "%m")) %/% 4 + 1
# For Q-based matching: adopt_yq = year*10 + quarter
treatment_states$adopt_yq <- treatment_states$adopt_year * 10 + treatment_states$adopt_qtr

cat("Treatment states:\n")
print(treatment_states)

# ---- Connect to Azure ----
con <- apep_azure_connect()

# ---- Query QWI race/ethnicity x 3-digit NAICS ----
# We need: EarnHirAS (new-hire earnings), HirA (hires), Sep (separations)
# by race (A1=White alone, A2=Black alone) and 3-digit NAICS
# Filter to relevant industries for DDD:
#   High-dispersion: 541 (Professional services), 522 (Credit intermediation),
#                    511 (Publishing/Information)
#   Low-dispersion:  722 (Food services), 445 (Food/beverage stores),
#                    721 (Accommodation)
# Also keep broad sectors for context

cat("Querying QWI race x 3-digit NAICS from Azure...\n")

# Query all states — filter to key industries and 2018Q1+ for efficiency
# Race codes: A1 = White alone, A2 = Black or African American alone
# Ethnicity A0 = All ethnicities (avoid double-counting by ethnicity cross)
# File naming: lowercase state abbreviation (e.g., al.parquet, co.parquet)
df_raw <- DBI::dbGetQuery(con, "
  SELECT
    geography,
    year,
    quarter,
    industry,
    race,
    EarnHirAS,
    HirA,
    Sep,
    Emp,
    EarnS,
    sEarnHirAS,
    sHirA,
    sSep
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE year >= 2018
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND industry IN ('541', '522', '511', '722', '445', '721',
                     '611', '621', '238', '423', '561', '812')
")

cat(sprintf("Raw rows fetched: %s\n", format(nrow(df_raw), big.mark = ",")))

# ---- Basic validation ----
stopifnot("No data returned from Azure" = nrow(df_raw) > 0)
stopifnot("Missing key columns" = all(c("EarnHirAS", "HirA", "geography") %in% names(df_raw)))

# Check state coverage
df_raw$state_fips <- substr(sprintf("%05d", as.integer(df_raw$geography)), 1, 2)
states_present <- unique(df_raw$state_fips)
cat(sprintf("States in data: %d\n", length(states_present)))

# Check year-quarter coverage
cat("Year-quarter coverage:\n")
print(table(df_raw$year, df_raw$quarter))

# ---- Save raw data ----
saveRDS(df_raw, "../data/qwi_raw.rds")
write.csv(treatment_states, "../data/treatment_states.csv", row.names = FALSE)

cat("Data fetched and saved successfully.\n")
cat(sprintf("Rows: %s | States: %d | Industries: %d\n",
    format(nrow(df_raw), big.mark = ","),
    length(unique(df_raw$state_fips)),
    length(unique(df_raw$industry))))

apep_azure_disconnect(con)
