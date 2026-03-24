# =============================================================================
# 01_fetch_data.R — Fetch IPEDS data from local DuckDB (downloaded from Azure)
# =============================================================================

source("00_packages.R")

# --- Connect to local IPEDS DuckDB (downloaded from Azure) ---
db_path <- "../data/ipeds.duckdb"
stopifnot(file.exists(db_path))
con <- dbConnect(duckdb(), db_path, read_only = TRUE)

# --- 1. IPEDS Completions (c_a) ---
cat("Fetching IPEDS completions (c_a)...\n")
completions <- dbGetQuery(con, "
  SELECT
    unitid,
    CAST(cipcode AS VARCHAR) AS cipcode,
    award_level,
    major_number,
    ctotalt AS total_completions,
    ctotalm AS male_completions,
    ctotalw AS female_completions,
    year
  FROM c_a
  WHERE year >= 2008 AND year <= 2023
    AND major_number = 1
    AND cipcode != 99
")
cat(sprintf("  Completions: %s rows\n", format(nrow(completions), big.mark = ",")))
stopifnot(nrow(completions) > 500000)

# --- 2. IPEDS Fall Enrollment at institution level ---
cat("Fetching IPEDS enrollment (ef_a)...\n")
enrollment <- dbGetQuery(con, "
  SELECT
    unitid,
    eftotlt AS total_enrollment,
    year
  FROM ef_a
  WHERE year >= 2008 AND year <= 2023
    AND efalevel = 1
    AND section = 1
    AND lstudy = 1
")
cat(sprintf("  Enrollment: %s rows\n", format(nrow(enrollment), big.mark = ",")))

# --- 3. IPEDS Institution Directory (hd) ---
cat("Fetching IPEDS institution directory (hd)...\n")
institutions <- dbGetQuery(con, "
  SELECT
    unitid,
    institution_name AS inst_name,
    sector,
    control,
    region,
    state,
    fips_state AS state_fips,
    latitude,
    longitude,
    year
  FROM hd
  WHERE year >= 2008 AND year <= 2023
")
cat(sprintf("  Institutions: %s rows\n", format(nrow(institutions), big.mark = ",")))
stopifnot(nrow(institutions) > 10000)

dbDisconnect(con, shutdown = TRUE)

# --- 4. Get CIP-level median earnings from College Scorecard ---
# Use the Scorecard's field-of-study data to construct GE risk scores
cat("Fetching College Scorecard earnings by field of study...\n")

api_key <- Sys.getenv("COLLEGE_SCORECARD_API_KEY")
stopifnot(nchar(api_key) > 0)

# Get median earnings by CIP-2 digit for for-profit institutions
# We'll sample a few pages to build CIP-level earnings
earnings_by_cip <- data.frame()
base_url <- "https://api.data.gov/ed/collegescorecard/v1/schools.json"

for (page in 0:9) {
  url <- sprintf(
    "%s?api_key=%s&school.ownership=3&fields=id,latest.programs.cip_4_digit&per_page=100&page=%d",
    base_url, api_key, page
  )
  resp <- tryCatch(jsonlite::fromJSON(url, flatten = TRUE), error = function(e) NULL)
  if (is.null(resp) || length(resp$results) == 0) break

  for (i in seq_len(nrow(resp$results))) {
    progs <- resp$results$latest.programs.cip_4_digit[[i]]
    if (!is.null(progs) && is.data.frame(progs) && nrow(progs) > 0) {
      if ("code" %in% names(progs) && "credential.level" %in% names(progs)) {
        # Extract what's available
        prog_df <- data.frame(
          unitid = resp$results$id[i],
          cipcode = progs$code,
          credential_level = progs$credential.level,
          stringsAsFactors = FALSE
        )
        # Check for earnings column
        earn_col <- grep("median_earnings", names(progs), value = TRUE)
        if (length(earn_col) > 0) {
          prog_df$median_earnings <- progs[[earn_col[1]]]
        }
        earnings_by_cip <- bind_rows(earnings_by_cip, prog_df)
      }
    }
  }
  cat(sprintf("  Page %d: %d schools\n", page, nrow(resp$results)))
  Sys.sleep(0.5)
}

cat(sprintf("  Scorecard program data: %s rows\n", format(nrow(earnings_by_cip), big.mark = ",")))

# --- Save all raw data ---
saveRDS(completions, "../data/ipeds_completions.rds")
saveRDS(enrollment, "../data/ipeds_enrollment.rds")
saveRDS(institutions, "../data/ipeds_institutions.rds")
if (nrow(earnings_by_cip) > 0) {
  saveRDS(earnings_by_cip, "../data/scorecard_earnings.rds")
}

cat("\n=== Data Fetch Complete ===\n")
cat(sprintf("  Completions: %s rows (%d-%d)\n",
            format(nrow(completions), big.mark = ","),
            min(completions$year), max(completions$year)))
cat(sprintf("  Enrollment: %s rows\n", format(nrow(enrollment), big.mark = ",")))
cat(sprintf("  Institutions: %s rows\n", format(nrow(institutions), big.mark = ",")))
