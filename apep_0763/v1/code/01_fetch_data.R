# 01_fetch_data.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Fetch QWI data from Azure Blob Storage, FRED unemployment, and build EA timing

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------
# 1. EA Termination Timing
# ------------------------------------------------------------------
# States that terminated SNAP Emergency Allotments early (pre-Feb 2023)
# Time index: 2019Q1=1, ..., 2023Q4=20
# Quarter: year*4 + (quarter - 1) - (2019*4 - 1) = (year - 2019)*4 + quarter

quarter_to_index <- function(yr, qtr) {
  (yr - 2019) * 4 + qtr
}

# Build EA termination data frame
# State FIPS codes (numeric geography field in QWI)
# Source: USDA FNS and state press releases
ea_timing_raw <- tribble(
  ~state_abbr, ~state_fips, ~ea_end_year, ~ea_end_quarter,
  # Early terminators
  "id", "16", 2021, 2,   # Idaho
  "fl", "12", 2021, 3,   # Florida
  "ga", "13", 2021, 3,   # Georgia
  "mt", "30", 2021, 3,   # Montana
  "sd", "46", 2021, 2,   # South Dakota
  "nd", "38", 2021, 3,   # North Dakota
  "wy", "56", 2021, 3,   # Wyoming
  "ar", "05", 2021, 3,   # Arkansas
  "in", "18", 2021, 3,   # Indiana
  "ia", "19", 2021, 3,   # Iowa
  "mo", "29", 2021, 3,   # Missouri
  "ms", "28", 2021, 3,   # Mississippi
  "ne", "31", 2021, 3,   # Nebraska
  "sc", "45", 2021, 3,   # South Carolina
  "tn", "47", 2021, 3,   # Tennessee
  "az", "04", 2021, 3,   # Arizona
  "ky", "21", 2022, 1,   # Kentucky
  "ak", "02", 2022, 2    # Alaska
)

ea_timing <- ea_timing_raw %>%
  mutate(
    first_treat = quarter_to_index(ea_end_year, ea_end_quarter),
    treated = 1L
  ) %>%
  select(state_abbr, state_fips, first_treat, treated)

# All state FIPS (including DC and never-treated)
all_states <- tribble(
  ~state_abbr, ~state_fips,
  "ak", "02", "al", "01", "ar", "05", "az", "04",
  "ca", "06", "co", "08", "ct", "09", "dc", "11",
  "de", "10", "fl", "12", "ga", "13", "hi", "15",
  "ia", "19", "id", "16", "il", "17", "in", "18",
  "ks", "20", "ky", "21", "la", "22", "ma", "25",
  "md", "24", "me", "23", "mi", "26", "mn", "27",
  "mo", "29", "ms", "28", "mt", "30", "nc", "37",
  "nd", "38", "ne", "31", "nh", "33", "nj", "34",
  "nm", "35", "nv", "32", "ny", "36", "oh", "39",
  "ok", "40", "or", "41", "pa", "42", "ri", "44",
  "sc", "45", "sd", "46", "tn", "47", "tx", "48",
  "ut", "49", "va", "51", "vt", "50", "wa", "53",
  "wi", "55", "wv", "54", "wy", "56"
)

ea_timing_full <- all_states %>%
  left_join(ea_timing, by = c("state_abbr", "state_fips")) %>%
  mutate(
    first_treat = if_else(is.na(first_treat), 0L, as.integer(first_treat)),
    treated = if_else(is.na(treated), 0L, treated)
  )

cat("EA timing constructed:\n")
cat("  Treated states:", sum(ea_timing_full$treated), "\n")
cat("  Never-treated:", sum(ea_timing_full$treated == 0), "\n")
print(ea_timing_full %>% filter(treated == 1) %>% arrange(first_treat))

saveRDS(ea_timing_full, file.path(data_dir, "ea_timing.rds"))
cat("Saved ea_timing.rds\n")

# ------------------------------------------------------------------
# 2. QWI Data from Azure Blob Storage via DuckDB
# ------------------------------------------------------------------
azure_cs <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
if (nchar(azure_cs) == 0) {
  stop("AZURE_STORAGE_CONNECTION_STRING not set. Run: bash scripts/azure_setup.sh")
}

# State abbreviations for QWI file paths (all 50 states + DC)
qwi_states <- c(
  "ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de",
  "fl", "ga", "hi", "ia", "id", "il", "in", "ks", "ky",
  "la", "ma", "md", "me", "mi", "mn", "mo", "ms", "mt",
  "nc", "nd", "ne", "nh", "nj", "nm", "nv", "ny", "oh",
  "ok", "or", "pa", "ri", "sc", "sd", "tn", "tx", "ut",
  "va", "vt", "wa", "wi", "wv", "wy"
)

# Connect to DuckDB and configure Azure
conn <- dbConnect(duckdb())
dbExecute(conn, "INSTALL httpfs; LOAD httpfs;")
dbExecute(conn, "INSTALL azure; LOAD azure;")
dbExecute(conn, paste0("SET azure_storage_connection_string='", azure_cs, "';"))

cat("DuckDB connected, Azure configured.\n")
cat("Fetching QWI data for", length(qwi_states), "states...\n")

# Fetch each state's QWI parquet file
qwi_list <- vector("list", length(qwi_states))
names(qwi_list) <- qwi_states

for (i in seq_along(qwi_states)) {
  st <- qwi_states[i]
  blob_path <- paste0("azure://derived/qwi/rh/n3/", st, ".parquet")

  cat(sprintf("  [%02d/%02d] Reading %s...", i, length(qwi_states), st))

  result <- tryCatch({
    query <- sprintf(
      "SELECT geography, year, quarter, race, Emp, HirN, EarnS
       FROM read_parquet('%s')
       WHERE geo_level = 'S'
         AND year BETWEEN 2019 AND 2023
         AND race IN ('A0', 'A2')",
      blob_path
    )
    dbGetQuery(conn, query)
  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", conditionMessage(e)))
    NULL
  })

  if (!is.null(result) && nrow(result) > 0) {
    qwi_list[[st]] <- result
    cat(sprintf(" %d rows\n", nrow(result)))
  } else {
    cat(" No data returned\n")
  }
}

dbDisconnect(conn)

# Bind all states
qwi_nonempty <- Filter(Negate(is.null), qwi_list)
if (length(qwi_nonempty) == 0) {
  stop("No QWI data retrieved from Azure. Check connection string and blob paths.")
}

qwi_data <- bind_rows(qwi_nonempty, .id = "state_abbr")

cat("\nQWI data fetched:\n")
cat("  Total rows:", nrow(qwi_data), "\n")
cat("  States with data:", length(qwi_nonempty), "/", length(qwi_states), "\n")
cat("  Years:", paste(sort(unique(qwi_data$year)), collapse = ", "), "\n")
cat("  Races:", paste(unique(qwi_data$race), collapse = ", "), "\n")

# Verify no simulated data: check for actual variation
stopifnot(
  "QWI data has no rows" = nrow(qwi_data) > 0,
  "QWI data missing Emp column" = "Emp" %in% names(qwi_data),
  "QWI data missing HirN column" = "HirN" %in% names(qwi_data),
  "QWI Emp has zero variance (simulated?)" = var(qwi_data$Emp, na.rm = TRUE) > 0,
  "QWI HirN has zero variance (simulated?)" = var(qwi_data$HirN, na.rm = TRUE) > 0
)

saveRDS(qwi_data, file.path(data_dir, "qwi_data.rds"))
cat("Saved qwi_data.rds\n")

# ------------------------------------------------------------------
# 3. FRED State Unemployment Rates
# ------------------------------------------------------------------
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) {
  stop("FRED_API_KEY not set in .env")
}
fredr_set_key(fred_key)

# FRED series IDs for quarterly state unemployment rates
# Series pattern: {STATE}UR (e.g., AKUR for Alaska, DCUR for DC)
state_abbr_upper <- toupper(qwi_states)

# FRED uses 2-letter state postal codes + "UR"
# DC is "DCUR", others follow standard postal codes
fred_series <- paste0(state_abbr_upper, "UR")

cat("Fetching FRED unemployment rates for", length(fred_series), "states...\n")

fred_list <- vector("list", length(fred_series))
names(fred_list) <- tolower(state_abbr_upper)

for (i in seq_along(fred_series)) {
  series_id <- fred_series[i]
  st <- tolower(state_abbr_upper[i])

  result <- tryCatch({
    fredr(
      series_id = series_id,
      observation_start = as.Date("2019-01-01"),
      observation_end = as.Date("2023-12-31"),
      frequency = "q"
    )
  }, error = function(e) {
    cat(sprintf("  WARNING: Could not fetch %s: %s\n", series_id, conditionMessage(e)))
    NULL
  })

  if (!is.null(result)) {
    fred_list[[st]] <- result %>%
      mutate(
        state_abbr = st,
        year = year(date),
        quarter = quarter(date),
        unemp_rate = value
      ) %>%
      select(state_abbr, year, quarter, unemp_rate)
  }
}

fred_data <- bind_rows(Filter(Negate(is.null), fred_list))

cat("FRED data fetched:\n")
cat("  States:", n_distinct(fred_data$state_abbr), "\n")
cat("  Rows:", nrow(fred_data), "\n")

saveRDS(fred_data, file.path(data_dir, "fred_ur.rds"))
cat("Saved fred_ur.rds\n")

cat("\n01_fetch_data.R complete.\n")
