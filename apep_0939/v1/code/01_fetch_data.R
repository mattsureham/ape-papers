## 01_fetch_data.R — Fetch all data from public APIs
## apep_0939: Employment Costs of Seismicity Regulation
##
## Data sources:
## 1. BLS QCEW (quarterly, county-level, by NAICS) — per-county API
## 2. USGS Earthquake Catalog (M3+ Oklahoma)
## 3. Treatment mapping from OCC directive documentation

library(tidyverse)
library(httr)
library(jsonlite)
library(data.table)

# ---- Configuration ----
out_dir <- "data"
if (!dir.exists(out_dir)) out_dir <- "../data"
stopifnot(dir.exists(out_dir))

# Oklahoma county FIPS codes (all 77 counties)
ok_county_fips <- sprintf("40%03d", c(
  1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35,
  37, 39, 41, 43, 45, 47, 49, 51, 53, 55, 57, 59, 61, 63, 65, 67, 69,
  71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, 95, 97, 99, 101, 103,
  105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125, 127, 129, 131,
  133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153
))

# ===========================================================================
# 1. BLS QCEW Data — County-Quarter Employment
# ===========================================================================
cat("=== Fetching BLS QCEW data ===\n")
cat(sprintf("Fetching %d counties × 9 years × 4 quarters\n",
            length(ok_county_fips)))

# Check for cached file first
qcew_cache <- file.path(out_dir, "qcew_oklahoma_raw.csv")
if (file.exists(qcew_cache) && file.size(qcew_cache) > 1000) {
  cat("Found cached QCEW data, loading...\n")
  qcew_all <- fread(qcew_cache)
  cat(sprintf("Loaded %d rows from cache.\n", nrow(qcew_all)))
} else {
  # Fetch county-by-county, quarter-by-quarter
  # API: https://data.bls.gov/cew/data/api/{year}/{qtr}/area/{county_fips}.csv
  qcew_list <- list()
  # Start from 2014 — BLS API unreliable for 2012-2013
  total_calls <- length(ok_county_fips) * 7 * 4
  call_num <- 0
  fail_count <- 0

  for (yr in 2014:2020) {
    for (qtr in 1:4) {
      for (fips in ok_county_fips) {
        call_num <- call_num + 1

        if (call_num %% 100 == 0) {
          cat(sprintf("  Progress: %d/%d (%.0f%%), failures: %d\n",
                      call_num, total_calls, 100 * call_num / total_calls, fail_count))
        }

        url <- sprintf("https://data.bls.gov/cew/data/api/%d/%d/area/%s.csv",
                        yr, qtr, fips)

        resp <- tryCatch(
          GET(url, timeout(30)),
          error = function(e) NULL
        )

        if (is.null(resp) || status_code(resp) != 200) {
          fail_count <- fail_count + 1
          next
        }

        txt <- content(resp, as = "text", encoding = "UTF-8")
        if (nchar(txt) < 100) next

        df <- tryCatch(
          fread(text = txt, showProgress = FALSE),
          error = function(e) NULL
        )

        if (!is.null(df) && nrow(df) > 0) {
          qcew_list[[length(qcew_list) + 1]] <- df
        }

        # Rate limit: ~100ms between calls
        Sys.sleep(0.1)
      }
    }
  }

  cat(sprintf("\nCompleted: %d calls, %d failures, %d successful chunks\n",
              call_num, fail_count, length(qcew_list)))

  if (length(qcew_list) == 0) {
    stop("FATAL: No QCEW data retrieved. Cannot proceed.")
  }

  qcew_all <- rbindlist(qcew_list, fill = TRUE)
  fwrite(qcew_all, qcew_cache)
  cat(sprintf("Saved %d rows to qcew_oklahoma_raw.csv\n", nrow(qcew_all)))
}

# Quick validation
n_counties <- length(unique(qcew_all$area_fips))
n_years <- length(unique(qcew_all$year))
cat(sprintf("QCEW: %d rows, %d counties, %d years\n",
            nrow(qcew_all), n_counties, n_years))
stopifnot(n_counties >= 50)  # Should have most of 77 counties
stopifnot(n_years >= 7)      # Should have most years


# ===========================================================================
# 2. USGS Earthquake Catalog — M3+ Oklahoma
# ===========================================================================
cat("\n=== Fetching USGS earthquake data ===\n")

eq_cache <- file.path(out_dir, "usgs_earthquakes_ok.csv")
if (file.exists(eq_cache) && file.size(eq_cache) > 1000) {
  cat("Loading cached earthquake data...\n")
  eq_df <- read_csv(eq_cache, show_col_types = FALSE)
} else {
  eq_url <- paste0(
    "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
    "&starttime=2010-01-01&endtime=2023-12-31",
    "&minlatitude=33.6&maxlatitude=37.0",
    "&minlongitude=-103.0&maxlongitude=-94.4",
    "&minmagnitude=3.0"
  )

  eq_resp <- GET(eq_url, timeout(120))
  stopifnot(status_code(eq_resp) == 200)

  eq_json <- content(eq_resp, as = "text", encoding = "UTF-8")
  eq_data <- fromJSON(eq_json)

  coords <- eq_data$features$geometry$coordinates
  if (is.list(coords)) {
    coords_mat <- do.call(rbind, coords)
  } else {
    coords_mat <- coords
  }

  eq_df <- tibble(
    time = as.POSIXct(eq_data$features$properties$time / 1000,
                       origin = "1970-01-01", tz = "UTC"),
    mag = eq_data$features$properties$mag,
    place = eq_data$features$properties$place,
    lon = coords_mat[, 1],
    lat = coords_mat[, 2],
    depth = coords_mat[, 3]
  ) %>%
    mutate(
      date = as.Date(time),
      year = year(date),
      quarter = quarter(date),
      yearqtr = year + (quarter - 1) / 4
    )

  write_csv(eq_df, eq_cache)
}

cat(sprintf("Earthquakes: %d events (M3+), %d-%d\n",
            nrow(eq_df), min(eq_df$year), max(eq_df$year)))

# Quarterly counts
eq_quarterly <- eq_df %>%
  count(year, quarter, name = "n_earthquakes") %>%
  mutate(yearqtr = year + (quarter - 1) / 4)
write_csv(eq_quarterly, file.path(out_dir, "usgs_earthquakes_quarterly.csv"))


# ===========================================================================
# 3. Treatment Mapping — OCC Directive Counties
# ===========================================================================
cat("\n=== Building treatment mapping ===\n")

# Counties with Arbuckle formation disposal wells subject to OCC volume caps.
# The OCC targeted wells in two main waves:
#   OWRA (Nov 2015): Western Oklahoma counties
#   OCRA (Feb-Mar 2016): Central Oklahoma counties
treatment_map <- tribble(
  ~county_fips, ~county_name,     ~directive_area, ~treatment_date,
  "40019",      "Carter",         "OWRA",          "2015-11-01",
  "40031",      "Comanche",       "OWRA",          "2015-11-01",
  "40051",      "Grady",          "OWRA",          "2015-11-01",
  "40137",      "Stephens",       "OWRA",          "2015-11-01",
  "40015",      "Caddo",          "OWRA",          "2015-11-01",
  "40017",      "Canadian",       "OWRA",          "2015-11-01",
  "40009",      "Blaine",         "OWRA",          "2015-11-01",
  "40039",      "Custer",         "OWRA",          "2015-11-01",
  "40043",      "Dewey",          "OWRA",          "2015-11-01",
  "40149",      "Washita",        "OWRA",          "2015-11-01",
  "40109",      "Oklahoma",       "OCRA",          "2016-03-01",
  "40081",      "Lincoln",        "OCRA",          "2016-03-01",
  "40083",      "Logan",          "OCRA",          "2016-03-01",
  "40119",      "Payne",          "OCRA",          "2016-03-01",
  "40037",      "Creek",          "OCRA",          "2016-03-01",
  "40117",      "Pawnee",         "OCRA",          "2016-03-01",
  "40073",      "Kingfisher",     "OCRA",          "2016-03-01",
  "40047",      "Garfield",       "OCRA",          "2016-03-01",
  "40103",      "Noble",          "OCRA",          "2016-03-01",
  "40071",      "Kay",            "OCRA",          "2016-03-01"
) %>%
  mutate(treatment_date = as.Date(treatment_date))

write_csv(treatment_map, file.path(out_dir, "treatment_mapping.csv"))
cat(sprintf("Treatment counties: %d (%d OWRA, %d OCRA)\n",
            nrow(treatment_map),
            sum(treatment_map$directive_area == "OWRA"),
            sum(treatment_map$directive_area == "OCRA")))


# ===========================================================================
# Summary
# ===========================================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("QCEW:        %d rows, %d counties\n", nrow(qcew_all), n_counties))
cat(sprintf("Earthquakes: %d events\n", nrow(eq_df)))
cat(sprintf("Treatment:   %d counties\n", nrow(treatment_map)))
cat("Data fetch complete.\n")
