# =============================================================================
# 01_fetch_data.R — Fetch QWI race × 3-digit NAICS data from Azure
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

source("00_packages.R")

# Connect to Azure directly (azure_data.R has connection string quoting issues)
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")

# Read connection string from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING", env_lines, value = TRUE)
cs <- sub("^[^=]+=", "", cs_line)
cs <- gsub("^[\"']|[\"']$", "", cs)
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", cs))
cat("Connected to Azure.\n")

# ---------------------------------------------------------------------------
# Treatment states and their repeal dates
# ---------------------------------------------------------------------------
treatment_info <- tribble(
  ~state_abbr, ~repeal_quarter, ~repeal_year_q,
  "in", "2015Q3", 2015.75,
  "wv", "2016Q1", 2016.00,
  "ky", "2017Q1", 2017.00,
  "ar", "2017Q1", 2017.00,
  "wi", "2017Q4", 2017.75,
  "mi", "2018Q2", 2018.25
)

# Control states: 28 states that maintained prevailing wage laws throughout
# States WITH prevailing wage laws as of 2023 (excluding the 6 repealing states)
pw_states <- c(
  "ca", "ct", "de", "hi", "il", "ma", "md", "me", "mn", "mo",
  "mt", "ne", "nj", "nm", "nv", "ny", "oh", "or", "pa", "ri",
  "tn", "tx", "wa", "wy", "ak", "co", "dc", "ia"
)

# All states to fetch (treated + control)
all_states <- c(treatment_info$state_abbr, pw_states)

cat("Fetching QWI data for", length(all_states), "states...\n")

# ---------------------------------------------------------------------------
# Fetch from Azure: race × 3-digit NAICS (rh/n3)
# ---------------------------------------------------------------------------
# Construction NAICS: 236 (Building), 237 (Heavy/Civil), 238 (Specialty Trades)
# Manufacturing NAICS 31-33 for placebo
construction_codes <- c(236, 237, 238)
# Manufacturing: use 3-digit NAICS (311-339 is the full range)
# Pick 3 large subsectors as placebo: 311 (Food), 332 (Fabricated Metal), 336 (Transport Equip)
mfg_codes <- c(311, 332, 336)
target_codes <- c(construction_codes, mfg_codes)

all_data <- list()

for (st in all_states) {
  cat("  Fetching:", st, "... ")

  query <- sprintf("
    SELECT *
    FROM read_parquet('az://derived/qwi/rh/n3/%s.parquet')
    WHERE CAST(industry AS INTEGER) IN (%s)
      AND sex = 0
      AND race IN ('A1', 'A2')
      AND year >= 2010
      AND year <= 2023
  ", st, paste(target_codes, collapse = ","))

  tryCatch({
    result <- dbGetQuery(con, query)
    if (nrow(result) == 0) stop("No rows returned")
    result$state_abbr <- st
    all_data[[st]] <- result
    cat(nrow(result), "rows\n")
  }, error = function(e) {
    stop(paste("FATAL: Failed to fetch data for state", st, ":", e$message))
  })
}

dbDisconnect(con, shutdown = TRUE)

# ---------------------------------------------------------------------------
# Combine and validate
# ---------------------------------------------------------------------------
df_raw <- bind_rows(all_data)
cat("\nTotal rows:", nrow(df_raw), "\n")
cat("States:", n_distinct(df_raw$state_abbr), "\n")
cat("Year range:", min(df_raw$year), "-", max(df_raw$year), "\n")

# Basic assertions
stopifnot(
  "Missing states" = n_distinct(df_raw$state_abbr) >= 30,
  "Too few rows" = nrow(df_raw) > 10000,
  "Missing race codes" = all(c("A1", "A2") %in% unique(df_raw$race))
)

# Save raw data
saveRDS(df_raw, "../data/qwi_raw.rds")
cat("Saved:", nrow(df_raw), "rows to data/qwi_raw.rds\n")
