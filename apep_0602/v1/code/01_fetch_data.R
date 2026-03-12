## 01_fetch_data.R — Fetch CDR data from College Scorecard and merge with IPEDS
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)
library(httr)
library(jsonlite)
library(duckdb)
library(DBI)

set.seed(20260312)

# --- Configuration ---
api_key <- Sys.getenv("COLLEGE_SCORECARD_API_KEY")
if (nchar(api_key) == 0) {
  # Try loading from .env (search up from working directory)
  env_candidates <- c("../../../../.env", "../../../.env", "../../.env", "../.env", ".env")
  env_file <- NULL
  for (ef in env_candidates) {
    if (file.exists(ef)) { env_file <- ef; break }
  }
  if (is.null(env_file)) stop("Cannot find .env file")
  cat(sprintf("Loading .env from: %s\n", env_file))
  if (file.exists(env_file)) {
    lines <- readLines(env_file, warn = FALSE)
    for (line in lines) {
      if (grepl("^COLLEGE_SCORECARD_API_KEY=", line)) {
        api_key <- sub("^COLLEGE_SCORECARD_API_KEY=", "", line)
        api_key <- gsub("^['\"]|['\"]$", "", api_key)
      }
    }
  }
}
stopifnot("COLLEGE_SCORECARD_API_KEY not found" = nchar(api_key) > 0)
cat("API key loaded.\n")

# --- Step 1: Fetch CDR data from College Scorecard ---
# We need 3-year CDR for all for-profit institutions, multiple years

fetch_scorecard_page <- function(page, year_prefix, api_key) {
  fields <- paste0(
    "id,school.name,school.state,school.ownership,school.degrees_awarded.predominant,",
    year_prefix, ".repayment.3_yr_default_rate,",
    year_prefix, ".repayment.3_yr_default_rate_denom"
  )
  url <- paste0(
    "https://api.data.gov/ed/collegescorecard/v1/schools.json?",
    "school.ownership=3&",  # For-profit only
    "fields=", fields, "&",
    "per_page=100&",
    "page=", page, "&",
    "api_key=", api_key
  )
  resp <- GET(url, timeout(30))
  if (status_code(resp) != 200) {
    warning(paste("API returned status", status_code(resp), "for page", page, "year", year_prefix))
    return(NULL)
  }
  parsed <- fromJSON(content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
  list(
    results = parsed$results,
    total = parsed$metadata$total,
    page = parsed$metadata$page
  )
}

# Fetch CDR data for fiscal years 2010-2019 (reported as academic years in Scorecard)
# Scorecard uses the field {year}.repayment.3_yr_default_rate
# Available years: 2009-2021 in the API

all_cdr <- list()

for (yr in 2009:2020) {
  cat(sprintf("Fetching CDR data for year %d...\n", yr))
  year_prefix <- as.character(yr)

  # Get first page to learn total count
  first_page <- fetch_scorecard_page(0, year_prefix, api_key)
  if (is.null(first_page)) {
    cat(sprintf("  Skipping year %d (API error)\n", yr))
    next
  }

  total <- first_page$total
  n_pages <- ceiling(total / 100)
  cat(sprintf("  Total for-profit institutions: %d (%d pages)\n", total, n_pages))

  year_results <- list(first_page$results)

  for (pg in seq_len(n_pages - 1)) {
    Sys.sleep(0.3)  # Rate limiting
    page_data <- fetch_scorecard_page(pg, year_prefix, api_key)
    if (!is.null(page_data)) {
      year_results[[length(year_results) + 1]] <- page_data$results
    }
  }

  yr_df <- bind_rows(year_results)

  # Rename CDR columns to standard names
  cdr_col <- paste0(year_prefix, ".repayment.3_yr_default_rate")
  denom_col <- paste0(year_prefix, ".repayment.3_yr_default_rate_denom")

  if (cdr_col %in% names(yr_df)) {
    yr_df <- yr_df %>%
      rename(
        unitid = id,
        inst_name = school.name,
        state = school.state,
        ownership = school.ownership,
        predominant_degree = school.degrees_awarded.predominant
      ) %>%
      mutate(
        cdr3 = as.numeric(.data[[cdr_col]]),
        cdr3_denom = as.numeric(.data[[denom_col]]),
        year = yr
      ) %>%
      select(unitid, inst_name, state, ownership, predominant_degree, year, cdr3, cdr3_denom)

    all_cdr[[length(all_cdr) + 1]] <- yr_df
  }
}

cdr_panel <- bind_rows(all_cdr)
cat(sprintf("CDR panel: %d institution-year observations\n", nrow(cdr_panel)))
cat(sprintf("  Non-missing CDR: %d\n", sum(!is.na(cdr_panel$cdr3))))
cat(sprintf("  Unique institutions: %d\n", n_distinct(cdr_panel$unitid)))

# Validate: CDR should be between 0 and 1
stopifnot("CDR values out of range" = all(cdr_panel$cdr3[!is.na(cdr_panel$cdr3)] >= 0 &
                                            cdr_panel$cdr3[!is.na(cdr_panel$cdr3)] <= 1))

# --- Step 2: Connect to IPEDS DuckDB ---
ipeds_candidates <- c("../../../data/ipeds/ipeds.duckdb", "../../../../data/ipeds/ipeds.duckdb")
ipeds_path <- NULL
for (ip in ipeds_candidates) {
  if (file.exists(ip)) { ipeds_path <- ip; break }
}
stopifnot("IPEDS database not found" = !is.null(ipeds_path))
cat(sprintf("IPEDS database found at: %s\n", ipeds_path))

con <- dbConnect(duckdb(), ipeds_path, read_only = TRUE)

# Get enrollment data (EFFY table)
cat("Fetching IPEDS enrollment data...\n")
enroll <- dbGetQuery(con, "
  SELECT unitid, year, efytotlt AS total_enrollment,
         efytotlm AS male_enrollment, efytotlw AS female_enrollment
  FROM effy
  WHERE lstudy = 999  -- All students
  AND unitid IN (SELECT DISTINCT unitid FROM hd WHERE control = 3)
")
cat(sprintf("  Enrollment: %d rows\n", nrow(enroll)))

# Get completion data (C_A table)
cat("Fetching IPEDS completion data...\n")
completions <- dbGetQuery(con, "
  SELECT unitid, year,
         SUM(ctotalt) AS total_completions
  FROM c_a
  WHERE major_number = 1
  AND cipcode = '99'
  AND award_level IN (3, 5, 6, 7, 8, 17, 18, 19)
  AND unitid IN (SELECT DISTINCT unitid FROM hd WHERE control = 3)
  GROUP BY unitid, year
")
cat(sprintf("  Completions: %d rows\n", nrow(completions)))

# Get institution characteristics and closure info (HD table)
cat("Fetching IPEDS institution characteristics...\n")
inst_chars <- dbGetQuery(con, "
  SELECT unitid, year, control, deathyr,
         currently_active,
         CASE WHEN currently_active = 3 THEN 1 ELSE 0 END AS closed_in_year,
         c18basic AS carnegie,
         longitude, latitude,
         opeflag, sector
  FROM hd
  WHERE control = 3
")
cat(sprintf("  Institution characteristics: %d rows\n", nrow(inst_chars)))

# Get financial aid data (SFA table)
cat("Fetching IPEDS financial aid data...\n")
fin_aid <- dbGetQuery(con, "
  SELECT unitid, year,
         scfa2 AS pell_recipients,
         scfa11n AS total_aid_recipients,
         anyaidn AS any_aid_n,
         anyaidp AS pct_any_aid
  FROM sfa
  WHERE unitid IN (SELECT DISTINCT unitid FROM hd WHERE control = 3)
")
cat(sprintf("  Financial aid: %d rows\n", nrow(fin_aid)))

# Get graduation rate data (GR table — 150% time)
cat("Fetching IPEDS graduation rate data...\n")
grad_rates <- dbGetQuery(con, "
  SELECT unitid, year,
         grtotlt AS grad_cohort_total,
         grtotlm AS grad_cohort_male,
         grtotlw AS grad_cohort_female
  FROM gr
  WHERE unitid IN (SELECT DISTINCT unitid FROM hd WHERE control = 3)
")
cat(sprintf("  Graduation rates: %d rows\n", nrow(grad_rates)))

dbDisconnect(con, shutdown = TRUE)

# --- Step 3: Save intermediate data ---
saveRDS(cdr_panel, "data/cdr_panel_raw.rds")
saveRDS(enroll, "data/ipeds_enrollment.rds")
saveRDS(completions, "data/ipeds_completions.rds")
saveRDS(inst_chars, "data/ipeds_inst_chars.rds")
saveRDS(fin_aid, "data/ipeds_fin_aid.rds")
saveRDS(grad_rates, "data/ipeds_grad_rates.rds")

cat("\n=== Data Fetch Complete ===\n")
cat(sprintf("CDR panel: %d obs, %d institutions, years %d-%d\n",
            nrow(cdr_panel), n_distinct(cdr_panel$unitid),
            min(cdr_panel$year), max(cdr_panel$year)))
cat(sprintf("IPEDS enrollment: %d obs\n", nrow(enroll)))
cat(sprintf("IPEDS completions: %d obs\n", nrow(completions)))
cat(sprintf("IPEDS inst chars: %d obs\n", nrow(inst_chars)))
cat(sprintf("IPEDS financial aid: %d obs\n", nrow(fin_aid)))
