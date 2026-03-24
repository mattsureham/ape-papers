## 01_fetch_data.R — Fetch BLS QCEW and Census population data for Florida counties
## apep_0865: Last Call for Competition

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. BLS QCEW: County-level employment for NAICS 7224 & 7225
# ============================================================
cat("=== Fetching BLS QCEW data ===\n")

bls_key <- Sys.getenv("BLS_API_KEY")

# QCEW uses the open data files (no API key needed for CSV downloads)
# URL pattern: https://data.bls.gov/cew/data/files/{year}/csv/{year}_qtrly_by_industry.zip
# But these are huge. Instead, use the QCEW Data API.
# QCEW API: https://data.bls.gov/cew/data/api/{year}/{qtr}/industry/{naics}.csv

fetch_qcew <- function(year, qtr, naics) {
  url <- sprintf(
    "https://data.bls.gov/cew/data/api/%d/%d/industry/%s.csv",
    year, qtr, naics
  )
  cat(sprintf("  Fetching QCEW %d Q%d NAICS %s...\n", year, qtr, naics))
  resp <- tryCatch(
    {
      r <- httr::GET(url, httr::timeout(60))
      if (httr::status_code(r) != 200) {
        stop(sprintf("HTTP %d for %s", httr::status_code(r), url))
      }
      content(r, as = "text", encoding = "UTF-8")
    },
    error = function(e) {
      stop(sprintf("QCEW fetch failed for %d Q%d NAICS %s: %s", year, qtr, naics, e$message))
    }
  )

  dt <- fread(text = resp)
  # Filter to Florida (FIPS state 12), county level (area_fips 5-digit starting with 12)
  dt <- dt[substr(area_fips, 1, 2) == "12" & own_code == 5]  # Private ownership
  dt$year <- year
  dt$qtr <- qtr
  return(dt)
}

# Fetch NAICS 7224 (Drinking Places) and 7225 (Restaurants) for 2010-2024
naics_codes <- c("7224", "7225")
years <- 2010:2024
quarters <- 1:4

all_qcew <- list()
idx <- 1
for (naics in naics_codes) {
  for (yr in years) {
    for (q in quarters) {
      # Skip future quarters
      if (yr == 2024 && q > 3) next
      result <- tryCatch(
        fetch_qcew(yr, q, naics),
        error = function(e) {
          cat(sprintf("  WARNING: %s\n", e$message))
          NULL
        }
      )
      if (!is.null(result) && nrow(result) > 0) {
        all_qcew[[idx]] <- result
        idx <- idx + 1
      }
    }
  }
}

if (length(all_qcew) == 0) {
  stop("FATAL: No QCEW data retrieved. Cannot proceed without real data.")
}

qcew <- rbindlist(all_qcew, fill = TRUE)
cat(sprintf("QCEW: %d rows, %d unique counties, years %d-%d\n",
            nrow(qcew), length(unique(qcew$area_fips)),
            min(qcew$year), max(qcew$year)))

# Validate we have real data
stopifnot(nrow(qcew) > 100)
stopifnot("annual_avg_emplvl" %in% names(qcew) | "month1_emplvl" %in% names(qcew))

fwrite(qcew, file.path(data_dir, "qcew_fl_drinking_restaurants.csv"))
cat("Saved QCEW data.\n")

# ============================================================
# 2. Census Population Estimates for Florida Counties
# ============================================================
cat("\n=== Fetching Census population data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("FATAL: CENSUS_API_KEY not set")

# Fetch population estimates from Census PEP API
# 2010-2019 vintage
fetch_census_pop <- function(vintage, year_range, key) {
  if (vintage == 2019) {
    # 2010-2019 intercensal estimates
    url <- sprintf(
      "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=county:*&in=state:12&key=%s",
      vintage, key
    )
  } else if (vintage == 2023) {
    # 2020-2023 estimates
    url <- sprintf(
      "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=county:*&in=state:12&key=%s",
      vintage, key
    )
  }

  cat(sprintf("  Fetching Census PEP vintage %d...\n", vintage))
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("Census API returned HTTP %d", httr::status_code(resp)))
  }

  json <- jsonlite::fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  df <- as.data.frame(json[-1, ], stringsAsFactors = FALSE)
  names(df) <- json[1, ]
  df$POP <- as.numeric(df$POP)
  df$vintage <- vintage
  return(df)
}

# Try multiple Census endpoints for population time series
# Approach: use the Decennial Census + PEP estimates

# 2000 Decennial (baseline for threshold calculation)
cat("  Fetching 2000 Decennial Census...\n")
url_2000 <- sprintf(
  "https://api.census.gov/data/2000/dec/sf1?get=P001001,NAME&for=county:*&in=state:12&key=%s",
  census_key
)
resp_2000 <- httr::GET(url_2000, httr::timeout(60))
if (httr::status_code(resp_2000) != 200) {
  stop(sprintf("Census 2000 API failed: HTTP %d", httr::status_code(resp_2000)))
}
json_2000 <- jsonlite::fromJSON(content(resp_2000, as = "text", encoding = "UTF-8"))
pop_2000 <- as.data.frame(json_2000[-1, ], stringsAsFactors = FALSE)
names(pop_2000) <- json_2000[1, ]
pop_2000$POP <- as.numeric(pop_2000$P001001)
pop_2000$year <- 2000
pop_2000$fips <- paste0(pop_2000$state, pop_2000$county)
cat(sprintf("  2000 Census: %d FL counties, total pop = %s\n",
            nrow(pop_2000), format(sum(pop_2000$POP), big.mark = ",")))

# Annual estimates 2010-2019
cat("  Fetching 2010-2019 PEP estimates...\n")
pop_series <- list()
for (yr in 2010:2019) {
  url_yr <- sprintf(
    "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=county:*&in=state:12&DATE_CODE=%d&key=%s",
    2019, yr - 2010 + 3, census_key  # DATE_CODE 3=2010, 4=2011, ... 12=2019
  )
  resp_yr <- httr::GET(url_yr, httr::timeout(60))
  if (httr::status_code(resp_yr) == 200) {
    json_yr <- jsonlite::fromJSON(content(resp_yr, as = "text", encoding = "UTF-8"))
    df_yr <- as.data.frame(json_yr[-1, ], stringsAsFactors = FALSE)
    names(df_yr) <- json_yr[1, ]
    df_yr$POP <- as.numeric(df_yr$POP)
    df_yr$year <- yr
    df_yr$fips <- paste0(df_yr$state, df_yr$county)
    pop_series[[length(pop_series) + 1]] <- df_yr[, c("fips", "NAME", "POP", "year")]
    cat(sprintf("    %d: %d counties\n", yr, nrow(df_yr)))
  } else {
    cat(sprintf("    WARNING: %d failed (HTTP %d)\n", yr, httr::status_code(resp_yr)))
  }
}

# 2020-2023 estimates
cat("  Fetching 2020-2023 PEP estimates...\n")
for (yr in 2020:2023) {
  url_yr <- sprintf(
    "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=county:*&in=state:12&DATE_CODE=%d&key=%s",
    2023, yr - 2020 + 3, census_key  # DATE_CODE 3=2020, 4=2021, 5=2022, 6=2023
  )
  resp_yr <- httr::GET(url_yr, httr::timeout(60))
  if (httr::status_code(resp_yr) == 200) {
    json_yr <- jsonlite::fromJSON(content(resp_yr, as = "text", encoding = "UTF-8"))
    df_yr <- as.data.frame(json_yr[-1, ], stringsAsFactors = FALSE)
    names(df_yr) <- json_yr[1, ]
    df_yr$POP <- as.numeric(df_yr$POP)
    df_yr$year <- yr
    df_yr$fips <- paste0(df_yr$state, df_yr$county)
    pop_series[[length(pop_series) + 1]] <- df_yr[, c("fips", "NAME", "POP", "year")]
    cat(sprintf("    %d: %d counties\n", yr, nrow(df_yr)))
  } else {
    cat(sprintf("    WARNING: %d failed (HTTP %d)\n", yr, httr::status_code(resp_yr)))
  }
}

if (length(pop_series) == 0) {
  stop("FATAL: No population data retrieved. Cannot proceed.")
}

pop_annual <- rbindlist(pop_series, fill = TRUE)
pop_2000_slim <- pop_2000[, c("fips", "NAME", "POP")]
names(pop_2000_slim)[3] <- "pop_2000"

# Merge baseline
pop_panel <- merge(pop_annual, pop_2000_slim[, c("fips", "pop_2000")], by = "fips", all.x = TRUE)

cat(sprintf("\nPopulation panel: %d county-years, %d counties, years %d-%d\n",
            nrow(pop_panel), length(unique(pop_panel$fips)),
            min(pop_panel$year), max(pop_panel$year)))

stopifnot(nrow(pop_panel) > 200)

fwrite(pop_panel, file.path(data_dir, "census_pop_fl_counties.csv"))
fwrite(pop_2000_slim, file.path(data_dir, "census_pop_fl_2000_baseline.csv"))
cat("Saved Census population data.\n")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("QCEW: %d rows\n", nrow(qcew)))
cat(sprintf("Population: %d county-years\n", nrow(pop_panel)))
