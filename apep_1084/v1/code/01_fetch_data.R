# =============================================================================
# 01_fetch_data.R — Load GE scores (XLS) + query IPEDS from local DuckDB
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

source("00_packages.R")

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}
library(readxl)
library(duckdb)

# --- 1. Load GE D/E Rates ---
cat("=== Loading Gainful Employment D/E rates ===\n")

ge_file <- "../data/ge_dmyr2015_final_rates.xls"
stopifnot("GE data file not found" = file.exists(ge_file))

ge_raw <- read_xls(ge_file)
cat("GE raw records:", nrow(ge_raw), "\n")
cat("GE columns:", paste(names(ge_raw), collapse = ", "), "\n\n")

# Print first few rows to understand structure
cat("=== GE sample ===\n")
print(head(ge_raw, 3))

saveRDS(ge_raw, "../data/ge_raw.rds")

# --- 2. Query IPEDS from local DuckDB ---
cat("\n=== Querying IPEDS from local DuckDB ===\n")

ipeds_db <- "../../../../data/ipeds/ipeds.duckdb"
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_db))

con <- dbConnect(duckdb(), dbdir = ipeds_db, read_only = TRUE)

# 2a. Completions by CIP code, race, and year (c_a table)
cat("Querying IPEDS completions (c_a)...\n")
completions <- dbGetQuery(con, "
  SELECT unitid, year, cipcode, award_level,
         ctotalm, ctotalw, ctotalt,
         cbkaat, chispt, cwhitt, cnhpit, caiant,
         c2mort, cunknt, casiat, cnralt
  FROM c_a
  WHERE year BETWEEN 2012 AND 2021
")
cat("Completions rows:", nrow(completions), "\n")

# 2b. Institution metadata (hd table)
cat("Querying IPEDS institution directory (hd)...\n")
inst <- dbGetQuery(con, "
  SELECT unitid, year, institution_name, control, deathyr,
         state AS stabbr, region, opeid, level AS iclevel
  FROM hd
  WHERE year BETWEEN 2012 AND 2021
")
cat("Institution records:", nrow(inst), "\n")

# 2c. 12-month enrollment (effy table) — institution-level total
cat("Querying IPEDS enrollment (effy)...\n")
enrollment <- dbGetQuery(con, "
  SELECT unitid, year, efytotlt, efytotlm, efytotlw
  FROM effy
  WHERE year BETWEEN 2012 AND 2021
")
cat("Enrollment records:", nrow(enrollment), "\n")

dbDisconnect(con, shutdown = TRUE)

# --- 3. Save all IPEDS data ---
saveRDS(completions, "../data/ipeds_completions.rds")
saveRDS(inst, "../data/ipeds_institutions.rds")
saveRDS(enrollment, "../data/ipeds_enrollment.rds")

cat("\n=== Data fetch complete ===\n")
cat("GE programs:", nrow(ge_raw), "\n")
cat("IPEDS completions:", nrow(completions), "\n")
cat("IPEDS institutions:", nrow(inst), "\n")
cat("IPEDS enrollment:", nrow(enrollment), "\n")
