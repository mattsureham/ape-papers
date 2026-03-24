## 01_fetch_data.R — Fetch QWI and ACS data
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

# =============================================================================
# 1. QWI DATA — County-level by sex and industry
# =============================================================================
cat("Fetching QWI data...\n")
cat("Strategy: mining (21) + all-private industries, Q4 annual snapshot\n")

qwi_base <- "https://api.census.gov/data/timeseries/qwi/sa"

# Core states: 13 shale + 11 comparison
shale_states <- c("38", "48", "42", "54", "39", "40", "08", "56", "35", "22",
                  "30", "05", "20")
comparison_states <- c("27", "19", "46", "31", "55", "18", "21", "51", "29",
                       "01", "28")
all_states <- c(shale_states, comparison_states)

# Industries: mining (21) and total all private (A1 doesn't work; use 00 = total)
industries <- c("21")  # Mining; we also need total
years <- 2001:2022

fetch_qwi <- function(state_fips, yr, qtr, sx, ind) {
  url <- paste0(qwi_base,
    "?get=Emp,EarnS,HirA",
    "&for=county:*",
    "&in=state:", state_fips,
    "&year=", yr,
    "&quarter=", qtr,
    "&sex=", sx,
    "&industry=", ind,
    "&key=", census_key
  )

  tryCatch({
    r <- httr2::request(url) |>
      httr2::req_timeout(60) |>
      httr2::req_retry(max_tries = 2, backoff = ~3)
    resp <- httr2::req_perform(r)
    if (httr2::resp_status(resp) != 200) return(NULL)
    body <- httr2::resp_body_string(resp)
    if (nchar(body) < 30) return(NULL)
    parsed <- jsonlite::fromJSON(body)
    if (is.null(parsed) || !is.matrix(parsed) || nrow(parsed) < 2) return(NULL)
    df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    df
  }, error = function(e) NULL)
}

# Phase 1: Fetch mining (21) employment — Q4 each year, both sexes
cat("Phase 1: Mining employment...\n")
mining_all <- list()
for (st in all_states) {
  for (yr in years) {
    for (sx in c("1", "2")) {
      chunk <- fetch_qwi(st, yr, 4, sx, "21")
      if (!is.null(chunk) && nrow(chunk) > 0) {
        mining_all[[length(mining_all) + 1]] <- chunk
      }
      Sys.sleep(0.05)
    }
  }
  cat(sprintf("  Mining: state %s done\n", st))
}

cat(sprintf("Mining chunks: %d\n", length(mining_all)))
if (length(mining_all) == 0) stop("FATAL: No mining QWI data fetched.")

mining_df <- bind_rows(mining_all) |>
  mutate(
    Emp = as.numeric(Emp),
    EarnS = as.numeric(EarnS),
    HirA = as.numeric(HirA),
    fips = paste0(state, county),
    year = as.integer(year),
    quarter = as.integer(quarter),
    sex = as.integer(sex)
  ) |>
  filter(!is.na(Emp))

cat(sprintf("Mining data: %d rows, %d counties\n", nrow(mining_df), n_distinct(mining_df$fips)))

# Phase 2: Fetch healthcare (62), construction (23), retail (44-45), accommodation (72)
# These give us non-mining employment and industry-specific tests
cat("Phase 2: Non-mining industries...\n")
other_industries <- c("62", "23", "72")

other_all <- list()
for (st in all_states) {
  for (yr in years) {
    for (sx in c("1", "2")) {
      for (ind in other_industries) {
        chunk <- fetch_qwi(st, yr, 4, sx, ind)
        if (!is.null(chunk) && nrow(chunk) > 0) {
          other_all[[length(other_all) + 1]] <- chunk
        }
        Sys.sleep(0.05)
      }
    }
  }
  cat(sprintf("  Non-mining: state %s done\n", st))
}

cat(sprintf("Non-mining chunks: %d\n", length(other_all)))

other_df <- bind_rows(other_all) |>
  mutate(
    Emp = as.numeric(Emp),
    EarnS = as.numeric(EarnS),
    HirA = as.numeric(HirA),
    fips = paste0(state, county),
    year = as.integer(year),
    quarter = as.integer(quarter),
    sex = as.integer(sex)
  ) |>
  filter(!is.na(Emp))

# Combine all QWI
qwi_df <- bind_rows(mining_df, other_df)
cat(sprintf("Total QWI: %d rows, %d counties\n", nrow(qwi_df), n_distinct(qwi_df$fips)))

saveRDS(qwi_df, "../data/qwi_raw.rds")

# =============================================================================
# 2. ACS DATA — County demographics (sex ratios, population)
# =============================================================================
cat("\nFetching ACS data...\n")

acs_base <- "https://api.census.gov/data"

fetch_acs <- function(yr, state_fips) {
  url <- paste0(acs_base, "/", yr, "/acs/acs5",
    "?get=B01001_001E,B01001_002E,B01001_026E",
    "&for=county:*",
    "&in=state:", state_fips,
    "&key=", census_key
  )
  tryCatch({
    r <- httr2::request(url) |>
      httr2::req_timeout(60) |>
      httr2::req_retry(max_tries = 2, backoff = ~3) |>
      httr2::req_perform()
    if (httr2::resp_status(r) != 200) return(NULL)
    body <- httr2::resp_body_string(r)
    if (nchar(body) < 20) return(NULL)
    parsed <- jsonlite::fromJSON(body)
    if (is.null(parsed) || nrow(parsed) < 2) return(NULL)
    df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    df$year <- yr
    df
  }, error = function(e) NULL)
}

acs_all <- list()
for (yr in 2009:2022) {
  for (st in all_states) {
    chunk <- fetch_acs(yr, st)
    if (!is.null(chunk) && nrow(chunk) > 0) {
      acs_all[[length(acs_all) + 1]] <- chunk
    }
    Sys.sleep(0.03)
  }
  cat(sprintf("  ACS %d done\n", yr))
}

cat(sprintf("ACS chunks: %d\n", length(acs_all)))
if (length(acs_all) == 0) stop("FATAL: No ACS data fetched.")

acs_df <- bind_rows(acs_all) |>
  mutate(
    across(starts_with("B0"), as.numeric),
    fips = paste0(state, county),
    total_pop = B01001_001E,
    male_pop = B01001_002E,
    female_pop = B01001_026E,
    sex_ratio = male_pop / female_pop,
    year = as.integer(year)
  )

saveRDS(acs_df, "../data/acs_raw.rds")
cat(sprintf("Saved ACS: %d rows, %d counties\n", nrow(acs_df), n_distinct(acs_df$fips)))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("QWI: %d rows across %d counties\n", nrow(qwi_df), n_distinct(qwi_df$fips)))
cat(sprintf("ACS: %d rows across %d counties\n", nrow(acs_df), n_distinct(acs_df$fips)))
