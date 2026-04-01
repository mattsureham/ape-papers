# =============================================================================
# 01_fetch_data.R — Fetch QWI race-ethnicity + MW panel
# Minimum Wages and the Racial Hiring Gap (apep_1277)
# =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# --- Load Azure connection string from .env ---
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
cat("Azure connection string length:", nchar(Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")), "\n")
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()
cat("Connected to Azure DuckDB.\n")

# =============================================================================
# 1. QWI: State-level aggregates by race (sum counties, all-industry total)
# =============================================================================
cat("Querying QWI state × race aggregates (all industries)...\n")

qwi_state <- dbGetQuery(con, "
  SELECT
    LPAD(CAST(CAST(geography / 1000 AS INTEGER) AS VARCHAR), 2, '0') AS state_fips,
    year, quarter, race,
    SUM(HirA) AS hires,
    SUM(Sep) AS seps,
    SUM(Emp) AS emp,
    SUM(EmpEnd) AS emp_end,
    SUM(CAST(EarnS AS DOUBLE) * CAST(Emp AS DOUBLE)) / NULLIF(SUM(CAST(Emp AS DOUBLE)), 0) AS avg_earnings
  FROM read_parquet('az://derived/qwi/rh/ns/*.parquet')
  WHERE industry = '00'
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year BETWEEN 2005 AND 2023
  GROUP BY 1, 2, 3, 4
  ORDER BY 1, 2, 3, 4
")
cat(sprintf("  State-level rows: %s\n", format(nrow(qwi_state), big.mark = ",")))
stopifnot("No QWI state data returned" = nrow(qwi_state) > 0)

# Verify coverage
cat("  States:", length(unique(qwi_state$state_fips)), "\n")
cat("  Year range:", range(qwi_state$year), "\n")
cat("  Races:", unique(qwi_state$race), "\n")

# =============================================================================
# 2. QWI: County-level by race, all industries (for Kaitz index DDD)
# =============================================================================
cat("Querying QWI county × race aggregates (all industries)...\n")

qwi_county <- dbGetQuery(con, "
  SELECT
    LPAD(CAST(geography AS VARCHAR), 5, '0') AS county_fips,
    LPAD(CAST(CAST(geography / 1000 AS INTEGER) AS VARCHAR), 2, '0') AS state_fips,
    year, quarter, race,
    SUM(HirA) AS hires,
    SUM(Emp) AS emp,
    SUM(CAST(EarnS AS DOUBLE) * CAST(Emp AS DOUBLE)) / NULLIF(SUM(CAST(Emp AS DOUBLE)), 0) AS avg_earnings
  FROM read_parquet('az://derived/qwi/rh/ns/*.parquet')
  WHERE industry = '00'
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year BETWEEN 2005 AND 2023
  GROUP BY 1, 2, 3, 4, 5
  ORDER BY 1, 3, 4, 5
")
cat(sprintf("  County-level rows: %s\n", format(nrow(qwi_county), big.mark = ",")))
stopifnot("No QWI county data returned" = nrow(qwi_county) > 0)
cat("  Counties:", length(unique(qwi_county$county_fips)), "\n")

# =============================================================================
# 3. QWI: State-level by industry × race (for mechanism/placebo)
# =============================================================================
cat("Querying QWI state × industry × race (low-wage + placebo sectors)...\n")

qwi_industry <- dbGetQuery(con, "
  SELECT
    LPAD(CAST(CAST(geography / 1000 AS INTEGER) AS VARCHAR), 2, '0') AS state_fips,
    year, quarter, race, industry,
    SUM(HirA) AS hires,
    SUM(Emp) AS emp
  FROM read_parquet('az://derived/qwi/rh/ns/*.parquet')
  WHERE industry IN ('44-45', '72', '62', '54', '52')
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year BETWEEN 2005 AND 2023
  GROUP BY 1, 2, 3, 4, 5
  ORDER BY 1, 2, 3, 4, 5
")
cat(sprintf("  Industry-level rows: %s\n", format(nrow(qwi_industry), big.mark = ",")))

apep_azure_disconnect(con)
cat("Azure disconnected.\n")

# =============================================================================
# 4. Minimum wage panel — download from Lislejoem/DOL data (1968-2020)
#    Supplement 2021-2023 from DOL published rates
# =============================================================================
cat("Downloading state minimum wage data...\n")

mw_url <- "https://raw.githubusercontent.com/Lislejoem/Minimum-Wage-by-State-1968-to-2020/master/Minimum%20Wage%20Data.csv"

mw_raw <- tryCatch({
  df <- read_csv(mw_url, show_col_types = FALSE)
  # Standardize column names
  df <- df %>%
    rename(
      year = Year,
      state = State,
      state_mw = State.Minimum.Wage,
      federal_mw = Federal.Minimum.Wage,
      effective_mw = Effective.Minimum.Wage
    ) %>%
    select(year, state, state_mw, federal_mw, effective_mw) %>%
    filter(year >= 2005)
  df
}, error = function(e) {
  cat("  Download failed:", e$message, "\n")
  NULL
})

if (is.null(mw_raw) || nrow(mw_raw) == 0) {
  stop("ERROR: Could not download minimum wage data. APEP prohibits simulated data.")
}

# Supplement 2021-2023 from DOL published effective rates (key states that changed)
# Source: DOL Wage and Hour Division, "Changes in Basic Minimum Wages"
cat("  Adding 2021-2023 MW updates from DOL...\n")

# Get 2020 as baseline, then update states that changed
mw_2020 <- mw_raw %>% filter(year == 2020) %>% select(state, effective_mw)

mw_supp <- list()
for (yr in 2021:2023) {
  yr_data <- mw_2020 %>% mutate(year = yr, federal_mw = 7.25, state_mw = effective_mw)
  mw_supp[[as.character(yr)]] <- yr_data
}
mw_supp <- bind_rows(mw_supp)

# Apply known state MW increases 2021-2023 (DOL published rates)
mw_updates <- tribble(
  ~state, ~year, ~new_mw,
  "Arizona", 2021, 12.15, "Arizona", 2022, 12.80, "Arizona", 2023, 13.85,
  "Arkansas", 2021, 11.00, "Arkansas", 2022, 11.00, "Arkansas", 2023, 11.00,
  "California", 2021, 14.00, "California", 2022, 15.00, "California", 2023, 15.50,
  "Colorado", 2021, 12.32, "Colorado", 2022, 12.56, "Colorado", 2023, 13.65,
  "Connecticut", 2021, 13.00, "Connecticut", 2022, 14.00, "Connecticut", 2023, 15.00,
  "Delaware", 2021, 9.25, "Delaware", 2022, 10.50, "Delaware", 2023, 11.75,
  "District of Columbia", 2021, 15.20, "District of Columbia", 2022, 16.10, "District of Columbia", 2023, 17.00,
  "Florida", 2021, 10.00, "Florida", 2022, 11.00, "Florida", 2023, 12.00,
  "Illinois", 2021, 11.00, "Illinois", 2022, 12.00, "Illinois", 2023, 13.00,
  "Maine", 2021, 12.15, "Maine", 2022, 12.75, "Maine", 2023, 13.80,
  "Maryland", 2021, 11.75, "Maryland", 2022, 12.50, "Maryland", 2023, 13.25,
  "Massachusetts", 2021, 13.50, "Massachusetts", 2022, 14.25, "Massachusetts", 2023, 15.00,
  "Michigan", 2021, 9.87, "Michigan", 2022, 9.87, "Michigan", 2023, 10.10,
  "Minnesota", 2021, 10.08, "Minnesota", 2022, 10.33, "Minnesota", 2023, 10.59,
  "Missouri", 2021, 10.30, "Missouri", 2022, 11.15, "Missouri", 2023, 12.00,
  "Montana", 2021, 8.75, "Montana", 2022, 9.20, "Montana", 2023, 9.95,
  "Nebraska", 2021, 9.00, "Nebraska", 2022, 9.00, "Nebraska", 2023, 10.50,
  "Nevada", 2021, 9.75, "Nevada", 2022, 10.50, "Nevada", 2023, 10.50,
  "New Jersey", 2021, 12.00, "New Jersey", 2022, 13.00, "New Jersey", 2023, 14.13,
  "New Mexico", 2021, 10.50, "New Mexico", 2022, 11.50, "New Mexico", 2023, 12.00,
  "New York", 2021, 12.50, "New York", 2022, 13.20, "New York", 2023, 14.20,
  "Ohio", 2021, 8.80, "Ohio", 2022, 9.30, "Ohio", 2023, 10.10,
  "Oregon", 2021, 12.75, "Oregon", 2022, 13.50, "Oregon", 2023, 13.50,
  "Rhode Island", 2021, 11.50, "Rhode Island", 2022, 12.25, "Rhode Island", 2023, 13.00,
  "South Dakota", 2021, 9.45, "South Dakota", 2022, 9.95, "South Dakota", 2023, 10.80,
  "Vermont", 2021, 11.75, "Vermont", 2022, 12.55, "Vermont", 2023, 13.18,
  "Virginia", 2021, 9.50, "Virginia", 2022, 11.00, "Virginia", 2023, 12.00,
  "Washington", 2021, 13.69, "Washington", 2022, 14.49, "Washington", 2023, 15.74,
  "West Virginia", 2021, 8.75, "West Virginia", 2022, 8.75, "West Virginia", 2023, 8.75
)

for (i in seq_len(nrow(mw_updates))) {
  idx <- mw_supp$state == mw_updates$state[i] & mw_supp$year == mw_updates$year[i]
  if (any(idx)) {
    mw_supp$effective_mw[idx] <- mw_updates$new_mw[i]
    mw_supp$state_mw[idx] <- mw_updates$new_mw[i]
  }
}

# Combine original (2005-2020) + supplement (2021-2023)
mw_raw <- bind_rows(
  mw_raw %>% select(year, state, state_mw, federal_mw, effective_mw),
  mw_supp %>% select(year, state, state_mw, federal_mw, effective_mw)
) %>%
  arrange(state, year)

cat(sprintf("  MW panel: %s state-years, %d states, years %d-%d\n",
            format(nrow(mw_raw), big.mark = ","),
            length(unique(mw_raw$state)),
            min(mw_raw$year), max(mw_raw$year)))

# =============================================================================
# 5. State crosswalk (FIPS + abbreviations)
# =============================================================================
state_info <- tibble(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                                  24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                                  42,44,45,46,47,48,49,50,51,53,54,55,56)),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL",
                  "IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE",
                  "NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD",
                  "TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                  "Connecticut","Delaware","District of Columbia","Florida","Georgia",
                  "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
                  "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
                  "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
                  "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                  "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                  "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont",
                  "Virginia","Washington","West Virginia","Wisconsin","Wyoming")
)

# =============================================================================
# Save all raw data
# =============================================================================
saveRDS(qwi_state, paste0(data_dir, "qwi_state_race.rds"))
saveRDS(qwi_county, paste0(data_dir, "qwi_county_race.rds"))
saveRDS(qwi_industry, paste0(data_dir, "qwi_industry_race.rds"))
write_csv(mw_raw, paste0(data_dir, "mw_raw.csv"))
saveRDS(state_info, paste0(data_dir, "state_info.rds"))

cat("\n=== Data fetch complete ===\n")
cat("  State QWI:", nrow(qwi_state), "rows\n")
cat("  County QWI:", nrow(qwi_county), "rows\n")
cat("  Industry QWI:", nrow(qwi_industry), "rows\n")
cat("  MW data:", nrow(mw_raw), "rows\n")
