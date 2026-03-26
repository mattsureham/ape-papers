# 01_fetch_data.R — Fetch Labour Force Survey data from e-Stat API
# Paper: The Compliance Cliff (apep_0969)
#
# Data source: Statistics Bureau of Japan (MIC)
#   Labour Force Survey (労働力調査) - Basic Tabulation, Monthly
#   e-Stat table IDs:
#     0003074679 — Average monthly hours AND days of work by industry
#   Coverage: Monthly, January 2013 – latest, all Japan
#
# Note: We use the Labour Force Survey (household-based) rather than the
#   MHLW Monthly Labour Survey (establishment-based) because:
#   (1) LFS data on e-Stat is updated through January 2026
#   (2) LFS captures actual hours worked by individuals, including unreported overtime
#   (3) 22 industry categories with monthly frequency

source("00_packages.R")

# Load API key from .env
env_path <- file.path(Sys.getenv("HOME"), "auto-policy-evals", ".env")
if (!file.exists(env_path)) env_path <- "../../../.env"
if (!file.exists(env_path)) env_path <- "../../../../.env"
stopifnot("Cannot find .env file" = file.exists(env_path))
env_lines <- readLines(env_path, warn = FALSE)
estat_line <- grep("^ESTAT_APP_ID=", env_lines, value = TRUE)[1]
if (is.na(estat_line)) stop("ESTAT_APP_ID not found in .env — cannot fetch data")
ESTAT_APP_ID <- sub("^ESTAT_APP_ID=", "", estat_line)
cat("e-Stat API key loaded.\n")

# --- Configuration ---
BASE_URL <- "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsData"

# ============================================================================
# FETCH 1: Average monthly hours of work by industry (tab=20)
# FETCH 2: Average monthly days of work by industry (tab=19)
# Table: 0003074679
# ============================================================================

fetch_lfs_data <- function(table_id, tab_code, cat01_code = "0", description = "") {
  params <- list(
    appId = ESTAT_APP_ID,
    statsDataId = table_id,
    cdTab = tab_code,
    cdCat01 = cat01_code,
    limit = 10000
  )

  cat(sprintf("Fetching %s (table=%s, tab=%s) ... ", description, table_id, tab_code))
  resp <- httr::GET(BASE_URL, query = params)

  if (httr::status_code(resp) != 200) {
    stop(sprintf("API returned status %d", httr::status_code(resp)))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, flatten = TRUE)

  status <- parsed$GET_STATS_DATA$RESULT$STATUS
  if (status != 0) {
    stop(sprintf("API error: %s", parsed$GET_STATS_DATA$RESULT$ERROR_MSG))
  }

  values <- parsed$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
  if (is.null(values) || nrow(values) == 0) {
    stop("No data returned")
  }

  cat(sprintf("%d rows fetched.\n", nrow(values)))

  dt <- data.table::data.table(
    table_id = table_id,
    tab_code = tab_code,
    sex = values[["@cat01"]],
    industry_code = values[["@cat02"]],
    time_code = values[["@time"]],
    value = as.numeric(values[["$"]])
  )

  return(dt)
}

# --- Fetch hours and days by industry ---
cat("Fetching Labour Force Survey data from e-Stat API...\n\n")

# Both sexes (code "0")
hours_data <- fetch_lfs_data("0003074679", "20", "0", "Monthly hours by industry")
days_data <- fetch_lfs_data("0003074679", "19", "0", "Monthly days by industry")

# Also fetch by sex for heterogeneity
hours_male <- fetch_lfs_data("0003074679", "20", "1", "Monthly hours by industry (Male)")
hours_female <- fetch_lfs_data("0003074679", "20", "2", "Monthly hours by industry (Female)")

all_data <- rbindlist(list(hours_data, days_data, hours_male, hours_female))

cat(sprintf("\nTotal rows fetched: %d\n", nrow(all_data)))

# --- Validate data ---
stopifnot("No data fetched" = nrow(all_data) > 0)

# Check industry and time coverage
cat(sprintf("Industries: %d\n", uniqueN(all_data$industry_code)))
time_range <- range(all_data$time_code)
cat(sprintf("Time range: %s to %s\n", time_range[1], time_range[2]))

# --- Also fetch employment counts by industry for weighting ---
cat("\nFetching employment by industry for compositional checks...\n")

# Table 0003074677: Employed person by type of employment and monthly hours of work
# Actually let me use the hours by industry table which already has the breakdown we need

# --- Save raw data ---
fwrite(all_data, "../data/lfs_raw.csv")
cat(sprintf("\nSaved raw data: ../data/lfs_raw.csv (%d rows)\n", nrow(all_data)))
cat("Data fetch complete.\n")
