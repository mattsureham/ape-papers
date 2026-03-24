# =============================================================================
# 01_fetch_data.R — Fetch QWI race/ethnicity data via Census API
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not found in .env")

# ---------------------------------------------------------------------------
# 1. QWI race/ethnicity data via Census API
# ---------------------------------------------------------------------------
# API: https://api.census.gov/data/timeseries/qwi/rh
# Must loop per state and per industry (multi-industry returns HTTP 204)

# We need a focused set of states relevant to our design
# Treated states + never-treated states (skip unclassified)
treated_fips <- c("53","41","06","25","50","09","17","32","08","44",
                   "36","34","10","26","27","12","11","24","15","02",
                   "04","05","46","31","54","29","23","51")
never_treated_fips <- c("01","13","16","18","19","20","21",
                         "22","28","33","37","38","39","40",
                         "42","45","47","48","49","55","56")
states <- unique(c(treated_fips, never_treated_fips))

industries <- c("72", "44-45", "62", "52", "54")
races <- c("A1", "A2")  # White, Black — must fetch separately

vars <- "Emp,EarnS,HirN,Sep"
year_chunks <- list(
  "2001,2002,2003,2004",
  "2005,2006,2007,2008,2009",
  "2010,2011,2012,2013,2014",
  "2015,2016,2017,2018,2019",
  "2020,2021,2022,2023,2024"
)

fetch_qwi_rh <- function(state, industry, race_code, years_str) {
  url <- paste0(
    "https://api.census.gov/data/timeseries/qwi/rh",
    "?get=", vars,
    "&for=county:*",
    "&in=state:", state,
    "&industry=", industry,
    "&ownercode=A05",
    "&periodicity=Q",
    "&seasonadj=U",
    "&race=", race_code,
    "&ethnicity=A0",
    "&year=", years_str,
    "&quarter=1,2,3,4",
    "&key=", census_key
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(120)),
    error = function(e) NULL
  )
  if (is.null(resp)) return(NULL)
  status <- httr::status_code(resp)

  if (status == 204 || status != 200) return(NULL)

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  if (nchar(content) < 10) return(NULL)

  parsed <- tryCatch(
    jsonlite::fromJSON(content),
    error = function(e) NULL
  )

  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df
}

cache_path <- file.path(data_dir, "qwi_raw.rds")

if (file.exists(cache_path)) {
  cat("Loading cached QWI data...\n")
  qwi_all <- readRDS(cache_path)
  cat(sprintf("  Loaded %s rows\n", format(nrow(qwi_all), big.mark = ",")))
} else {
  total_calls <- length(states) * length(industries) * length(races) * length(year_chunks)
  cat(sprintf("Fetching QWI data: %d API calls...\n", total_calls))

  all_data <- list()
  idx <- 1
  call_num <- 0
  fail_count <- 0

  for (st in states) {
    for (ind in industries) {
      for (rc in races) {
        for (yrs in year_chunks) {
          call_num <- call_num + 1
          if (call_num %% 100 == 0) {
            cat(sprintf("  Progress: %d/%d (%.0f%%), chunks=%d, fails=%d\n",
                        call_num, total_calls, 100 * call_num / total_calls,
                        idx - 1, fail_count))
          }

          result <- fetch_qwi_rh(st, ind, rc, yrs)
          if (!is.null(result) && nrow(result) > 0) {
            all_data[[idx]] <- result
            idx <- idx + 1
          } else {
            fail_count <- fail_count + 1
          }

          Sys.sleep(0.05)
        }
      }
    }
  }

  cat(sprintf("  Fetched %d chunks (%d failed)\n", idx - 1, fail_count))
  stopifnot("No data fetched from Census API" = length(all_data) > 0)

  qwi_all <- bind_rows(all_data)
  cat(sprintf("  Total rows: %s\n", format(nrow(qwi_all), big.mark = ",")))

  for (col in c("Emp", "EarnS", "HirN", "Sep")) {
    qwi_all[[col]] <- as.numeric(qwi_all[[col]])
  }
  qwi_all$year <- as.integer(qwi_all$year)
  qwi_all$quarter <- as.integer(qwi_all$quarter)

  qwi_all <- qwi_all %>%
    mutate(
      county_fips = paste0(
        formatC(as.integer(state), width = 2, flag = "0"),
        formatC(as.integer(county), width = 3, flag = "0")
      ),
      state_fips = formatC(as.integer(state), width = 2, flag = "0")
    )

  saveRDS(qwi_all, cache_path)
  cat("  Saved to cache.\n")
}

stopifnot("QWI data must not be empty" = nrow(qwi_all) > 0)

# ---------------------------------------------------------------------------
# 2. State minimum wage treatment timing
# ---------------------------------------------------------------------------
cat("Constructing state minimum wage panel...\n")

# Treatment: first year state effective MW >= $7.98 (110% of federal $7.25)
# Based on DOL records, Vaghul-Zipperer database, state legislative records
# Federal MW = $7.25 since July 2009

mw_treatment <- tribble(
  ~state_fips, ~first_treat_year,
  "53", 2009L, # Washington ($8.55 in 2009, indexed)
  "41", 2009L, # Oregon ($8.40 in 2009, indexed)
  "06", 2008L, # California ($8.00 in 2008)
  "25", 2008L, # Massachusetts ($8.00 in 2008)
  "50", 2009L, # Vermont ($8.06 in 2009, indexed)
  "09", 2010L, # Connecticut ($8.25 in 2010)
  "17", 2010L, # Illinois ($8.00 in 2010)
  "32", 2010L, # Nevada ($8.25 in 2010, indexed)
  "08", 2013L, # Colorado (hit $8.00 by 2013)
  "44", 2013L, # Rhode Island ($8.00 in 2013)
  "36", 2014L, # New York ($8.00 in 2014)
  "34", 2014L, # New Jersey ($8.25 in 2014)
  "10", 2014L, # Delaware ($8.25 in 2014)
  "26", 2014L, # Michigan ($8.15 in 2014)
  "27", 2014L, # Minnesota ($8.00 in 2014)
  "12", 2014L, # Florida (indexed, crossed $8 in 2014)
  "11", 2014L, # DC ($9.50 in 2014)
  "24", 2015L, # Maryland ($8.00 in 2015)
  "15", 2015L, # Hawaii ($8.50 in 2015)
  "02", 2015L, # Alaska ($8.75 in 2015)
  "04", 2015L, # Arizona ($8.05 in 2015)
  "05", 2015L, # Arkansas ($8.00 in 2015)
  "46", 2015L, # South Dakota ($8.50 in 2015)
  "31", 2015L, # Nebraska ($8.00 in 2015)
  "54", 2015L, # West Virginia ($8.00 in 2015)
  "29", 2015L, # Missouri (crossed $8 ~2015)
  "23", 2016L, # Maine ($9.00 in 2017, but crossed $8 by 2016)
  "51", 2016L, # Virginia ($8.00 by local adoption 2016)
)

# Never-treated states: MW = federal $7.25 or no state MW through 2024
never_treated <- c("01", "13", "16", "18", "19", "20", "21",
                    "22", "28", "33", "37", "38", "39", "40",
                    "42", "45", "47", "48", "49", "55", "56")

mw_panel <- tibble(state_fips = unique(qwi_all$state_fips)) %>%
  left_join(mw_treatment, by = "state_fips") %>%
  mutate(
    first_treat_year = case_when(
      state_fips %in% never_treated ~ 0L,
      !is.na(first_treat_year) ~ first_treat_year,
      TRUE ~ NA_integer_
    )
  ) %>%
  filter(!is.na(first_treat_year))

cat(sprintf("  Treated states: %d\n", sum(mw_panel$first_treat_year > 0)))
cat(sprintf("  Never-treated states: %d\n", sum(mw_panel$first_treat_year == 0)))

saveRDS(mw_panel, file.path(data_dir, "mw_panel.rds"))
cat("Data fetch complete.\n")
