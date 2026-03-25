# ============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for RTF paper
# ============================================================================

source("00_packages.R")

# --- Azure connection with correct secret setup ---
library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

# Read connection string from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING", env_lines, value = TRUE)
cs <- sub("^AZURE_STORAGE_CONNECTION_STRING=[\"']*", "", cs_line)
cs <- sub("[\"']*$", "", cs)

DBI::dbExecute(con, sprintf(
  "CREATE SECRET az_secret (TYPE azure, CONNECTION_STRING '%s');",
  cs
))
cat("Azure connection established.\n")

# --- Define states (lowercase abbreviations match Azure file names) ---
treated_abbrs <- c("nd", "nc", "mo", "ia", "ga", "tx")
control_abbrs <- c("ks", "ne", "wi", "tn", "va", "sd", "ky", "mt")
all_abbrs <- c(treated_abbrs, control_abbrs)

# --- Fetch QWI SA (sex/age) NAICS 3-digit ---
cat("Fetching QWI SA data...\n")

sa_files <- paste0("'az://derived/qwi/sa/n3/", all_abbrs, ".parquet'")
sa_query <- sprintf(
  "SELECT * FROM read_parquet([%s]) WHERE industry IN ('112', '111') AND sex = '0' AND agegrp = 'A00'",
  paste(sa_files, collapse = ", ")
)

qwi_sa <- DBI::dbGetQuery(con, sa_query)
cat(sprintf("QWI SA rows fetched: %d\n", nrow(qwi_sa)))
stopifnot("No QWI SA data returned" = nrow(qwi_sa) > 0)

# --- Fetch QWI RH (race/ethnicity/Hispanic origin) NAICS 3-digit ---
cat("Fetching QWI RH data...\n")

rh_files <- paste0("'az://derived/qwi/rh/n3/", all_abbrs, ".parquet'")
rh_query <- sprintf(
  "SELECT * FROM read_parquet([%s]) WHERE industry = '112'",
  paste(rh_files, collapse = ", ")
)

qwi_rh <- DBI::dbGetQuery(con, rh_query)
cat(sprintf("QWI RH rows fetched: %d\n", nrow(qwi_rh)))
stopifnot("No QWI RH data returned" = nrow(qwi_rh) > 0)

DBI::dbDisconnect(con, shutdown = TRUE)

# --- Inspect column names ---
cat("\nQWI SA columns:\n")
cat(paste(names(qwi_sa), collapse = ", "), "\n")
cat("\nQWI RH columns:\n")
cat(paste(names(qwi_rh), collapse = ", "), "\n")

# --- Save raw data ---
saveRDS(qwi_sa, "../data/qwi_sa_raw.rds")
saveRDS(qwi_rh, "../data/qwi_rh_raw.rds")

cat("\nData fetch complete.\n")
cat(sprintf("  QWI SA: %d rows, %d columns\n", nrow(qwi_sa), ncol(qwi_sa)))
cat(sprintf("  QWI RH: %d rows, %d columns\n", nrow(qwi_rh), ncol(qwi_rh)))
