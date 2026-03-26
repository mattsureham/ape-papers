# 01_fetch_data.R — Fetch QWI county×race panel from Azure
# Ban the Box and the Black Employment Gap (apep_1012)

source("00_packages.R")

# --- Read Azure connection string directly from .env ---
# Shell export truncates at semicolons, so we parse .env ourselves
env_file <- "../../../../.env"
stopifnot(".env not found" = file.exists(env_file))

env_lines <- readLines(env_file, warn = FALSE)
conn_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
stopifnot("AZURE_STORAGE_CONNECTION_STRING not found in .env" = length(conn_line) > 0)
azure_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", conn_line[1])
azure_conn <- gsub('^["\']|["\']$', '', azure_conn)  # strip quotes if any

message(sprintf("Azure connection string length: %d", nchar(azure_conn)))
stopifnot("Connection string looks truncated" = nchar(azure_conn) > 100)

# --- Connect via DuckDB ---
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET (TYPE azure, CONNECTION_STRING '%s');", azure_conn))

# --- Check available columns first ---
message("Checking QWI schema...")
schema <- dbGetQuery(con, "SELECT * FROM 'az://derived/qwi/rh/ns/*.parquet' LIMIT 5")
message("Columns available: ", paste(names(schema), collapse = ", "))

# --- Fetch QWI race panel ---
message("Fetching QWI county×race panel from Azure...")

qwi <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    race,
    ethnicity,
    year,
    quarter,
    Emp,
    HirA,
    HirN,
    EmpS,
    EarnS
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year >= 2005
    AND year <= 2023
")

message(sprintf("Fetched %s rows from QWI", format(nrow(qwi), big.mark = ",")))
dbDisconnect(con, shutdown = TRUE)

# --- Validate data ---
stopifnot("Data is empty" = nrow(qwi) > 0)
stopifnot("Missing required columns" = all(c("county_fips", "race", "year", "quarter", "Emp") %in% names(qwi)))

qwi <- as.data.table(qwi)

# Create state FIPS from county FIPS (first 2 digits for 5-digit FIPS)
qwi[, state_fips := as.integer(substr(sprintf("%05d", as.integer(county_fips)), 1, 2))]

# Create time variable (year-quarter)
qwi[, yq := year + (quarter - 1) / 4]
qwi[, time_id := (year - 2005) * 4 + quarter]

# --- Summary statistics ---
message(sprintf("Counties: %d", uniqueN(qwi$county_fips)))
message(sprintf("States: %d", uniqueN(qwi$state_fips)))
message(sprintf("Time range: %d Q%d to %d Q%d",
                min(qwi$year), min(qwi[year == min(year)]$quarter),
                max(qwi$year), max(qwi[year == max(year)]$quarter)))
message(sprintf("Race A1 (White) rows: %s", format(nrow(qwi[race == "A1"]), big.mark = ",")))
message(sprintf("Race A2 (Black) rows: %s", format(nrow(qwi[race == "A2"]), big.mark = ",")))

# --- Save ---
fwrite(qwi, "../data/qwi_county_race.csv")
message("Saved to data/qwi_county_race.csv")
