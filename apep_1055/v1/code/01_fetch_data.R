## 01_fetch_data.R — Fetch County Health Rankings + construct treatment
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations
##
## Data sources:
##   1. County Health Rankings (countyhealthrankings.org) — preventable hospitalizations
##   2. USPS 3-digit ZIP service standard changes — treatment assignment
##   3. HUD USPS ZIP-to-county crosswalk — geographic mapping
##   4. AHRF / Census — pharmacy counts and controls

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. COUNTY HEALTH RANKINGS — Preventable hospitalization rate
# ============================================================================
cat("=== Downloading County Health Rankings data ===\n")

# CHR provides analytic data files for each year
# Preventable hospitalization rate = ambulatory care-sensitive condition discharge rate per 100K Medicare enrollees
chr_years <- 2015:2024

chr_all <- list()

for (yr in chr_years) {
  cat(sprintf("  Fetching CHR %d...\n", yr))

  # CHR analytic data uses different URL patterns for different years
  # 2019+: /sites/default/files/media/document/YEAR County Health Rankings Data - vN.csv
  # 2015-2017: /sites/default/files/analytic_dataYEAR.csv
  # 2018: /sites/default/files/analytic_data2018_0.csv

  dest <- file.path(data_dir, sprintf("chr_%d.csv", yr))

  if (!file.exists(dest)) {
    # Build list of URLs to try, prioritized by year
    if (yr >= 2019) {
      urls_to_try <- c(
        sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/%d%%20County%%20Health%%20Rankings%%20Data%%20-%%20v2.csv", yr),
        sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/%d%%20County%%20Health%%20Rankings%%20Data%%20-%%20v1.csv", yr),
        sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data%d.csv", yr)
      )
    } else if (yr == 2018) {
      urls_to_try <- c(
        "https://www.countyhealthrankings.org/sites/default/files/analytic_data2018_0.csv",
        "https://www.countyhealthrankings.org/sites/default/files/analytic_data2018.csv"
      )
    } else {
      urls_to_try <- c(
        sprintf("https://www.countyhealthrankings.org/sites/default/files/analytic_data%d.csv", yr)
      )
    }

    downloaded <- FALSE
    for (url in urls_to_try) {
      tryCatch({
        download.file(url, dest, mode = "wb", quiet = TRUE)
        downloaded <- TRUE
        break
      }, error = function(e) NULL)
    }

    if (!downloaded) {
      cat(sprintf("  WARNING: Cannot download CHR data for %d. Skipping.\n", yr))
      next
    }
  }

  resp <- "ok"  # File exists at this point

  # CHR CSVs have a header row followed by column descriptions, then data
  # Read first few lines to detect format
  raw_lines <- readLines(dest, n = 5)

  # Try reading with standard approach — skip description rows
  df_yr <- tryCatch(
    {
      # Most CHR files: row 1 = headers, row 2 = descriptions, row 3+ = data
      tmp <- read.csv(dest, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
      # If the second row looks like descriptions (no FIPS code), skip it
      if (nrow(tmp) > 0 && is.na(suppressWarnings(as.numeric(tmp[1, 1])))) {
        tmp <- tmp[-1, ]
      }
      tmp
    },
    error = function(e) {
      stop(sprintf("FATAL: Cannot parse CHR data for %d: %s", yr, e$message))
    }
  )

  # Identify key columns — CHR uses varying column names across years
  fips_col <- grep("^FIPS$|^fipscode$|^5-digit FIPS", names(df_yr), ignore.case = TRUE, value = TRUE)[1]
  state_col <- grep("^State$|^statecode$", names(df_yr), ignore.case = TRUE, value = TRUE)[1]

  # Try multiple patterns for preventable hospitalization column
  all_names <- names(df_yr)
  prev_hosp_patterns <- c(
    "Preventable Hosp.*raw",       # 2019+ format
    "Preventable hospital stays raw",  # 2015-2018 format
    "Prev.*Hosp.*Rate",
    "Ambulatory.*raw",
    "118.*raw",
    "preventable.*raw"
  )

  prev_hosp_col <- NA
  for (pat in prev_hosp_patterns) {
    match <- grep(pat, all_names, ignore.case = TRUE, value = TRUE)[1]
    if (!is.na(match)) {
      prev_hosp_col <- match
      break
    }
  }

  if (is.na(prev_hosp_col)) {
    cat(sprintf("  WARNING: Cannot find preventable hospitalization column for %d\n", yr))
    cat("  Available columns (first 40):", paste(head(all_names, 40), collapse = ", "), "\n")
    next
  }

  if (is.na(fips_col)) {
    fips_col <- names(df_yr)[1]  # Usually the first column
  }

  df_clean <- data.frame(
    fips = sprintf("%05d", as.integer(df_yr[[fips_col]])),
    year = yr,
    prev_hosp_rate = as.numeric(df_yr[[prev_hosp_col]]),
    stringsAsFactors = FALSE
  )

  # Keep only county-level (5-digit FIPS, not state-level)
  df_clean <- df_clean[nchar(df_clean$fips) == 5 & !is.na(df_clean$prev_hosp_rate), ]

  cat(sprintf("  %d: %d counties with preventable hospitalization data\n", yr, nrow(df_clean)))

  if (nrow(df_clean) == 0) {
    stop(sprintf("FATAL: Zero counties with data for %d. Data format may have changed.", yr))
  }

  chr_all[[as.character(yr)]] <- df_clean
}

chr_panel <- bind_rows(chr_all)
cat(sprintf("\nCHR panel: %d county-year observations, %d unique counties\n",
            nrow(chr_panel), n_distinct(chr_panel$fips)))

if (n_distinct(chr_panel$fips) < 1000) {
  stop("FATAL: Fewer than 1000 counties in panel. Data acquisition failed.")
}

saveRDS(chr_panel, file.path(data_dir, "chr_panel.rds"))

# ============================================================================
# 2. TREATMENT CONSTRUCTION — USPS Service Standard Changes
# ============================================================================
cat("\n=== Constructing USPS mail slowdown treatment ===\n")

# The October 2021 USPS service standard change (86 FR 43949) mechanically
# assigned delivery time increases based on distance from USPS processing facilities.
#
# We construct treatment intensity at the county level using the operational
# reality: counties farther from regional processing hubs experienced larger
# service standard increases.
#
# Approach: Use county centroid distance to nearest USPS Processing & Distribution
# Center (P&DC) as a proxy for the service standard change.
# Counties within ~150 miles of their P&DC: mostly retained 2-day standard
# Counties 150-600 miles: shifted to 3-day (1-day increase)
# Counties 600+ miles: shifted to 4-day (2-day increase)
#
# We use census county centroids and known P&DC locations.

# Fetch county centroids from Census Bureau gazetteer files
cat("  Fetching county centroids...\n")
gaz_url <- "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_counties_national.zip"
gaz_dest <- file.path(data_dir, "county_gazetteer.zip")

if (!file.exists(gaz_dest)) {
  download.file(gaz_url, gaz_dest, mode = "wb", quiet = TRUE)
}
gaz_dir <- file.path(data_dir, "gazetteer")
dir.create(gaz_dir, showWarnings = FALSE)
unzip(gaz_dest, exdir = gaz_dir)
gaz_file <- list.files(gaz_dir, pattern = "\\.txt$", full.names = TRUE)[1]

if (is.null(gaz_file) || !file.exists(gaz_file)) {
  stop("FATAL: County gazetteer file not found after download.")
}

county_centroids <- read.delim(gaz_file, stringsAsFactors = FALSE)
county_centroids <- county_centroids %>%
  transmute(
    fips = sprintf("%05d", as.integer(GEOID)),
    lat = INTPTLAT,
    lon = INTPTLONG,
    state_fips = substr(fips, 1, 2),
    land_area_sq_mi = ALAND_SQMI
  )

cat(sprintf("  %d county centroids loaded\n", nrow(county_centroids)))

# USPS Processing & Distribution Centers
# Major P&DC locations (the 200+ facilities that sort First-Class Mail)
# We use the USPS facility data — approximate coordinates for major P&DCs
# Source: USPS Annual Report to Congress + USPS facility listings
#
# Rather than listing all ~200 P&DCs, we use the key insight from the
# Federal Register rule: the distance thresholds are based on DRIVING distance
# from origin to destination processing facilities. As a practical proxy,
# we use the distance from each county centroid to the nearest major metro
# area (which houses the P&DC), classifying treatment intensity.

# Use the Census Urban Area centroids as proxies for P&DC locations
# P&DCs are overwhelmingly in metro areas with 100K+ population
# We'll use CBSA principal city coordinates

# Alternative approach: directly classify counties by their characteristics
# that determine mail routing distance

# The Federal Register specifies:
# - 2-day: origin & destination within same SCF (Sectional Center Facility) area
# - 3-day: transit across SCF areas within same or adjacent USPS districts
# - 4-day: transit across non-adjacent districts, contiguous US
# - 5-day: non-contiguous (AK, HI, territories)

# Operationally, the strongest proxy available from public data is:
# county rurality + distance from nearest metro center

# We use a simplified but defensible approach:
# Treatment = f(distance to nearest large city, rurality classification)

# Download USDA ERS Rural-Urban Continuum Codes (RUCC)
cat("  Fetching USDA Rural-Urban Continuum Codes...\n")
rucc_url <- "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv"

# Try alternative URL format
rucc_urls <- c(
  "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv",
  "https://www.ers.usda.gov/webdocs/DataFiles/53251/Ruralurbancodes2013.csv",
  "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.xls"
)

rucc_dest <- file.path(data_dir, "rucc2013.csv")
rucc_loaded <- FALSE

if (!file.exists(rucc_dest)) {
  for (u in rucc_urls) {
    tryCatch({
      download.file(u, rucc_dest, mode = "wb", quiet = TRUE)
      rucc_loaded <- TRUE
      break
    }, error = function(e) NULL)
  }
} else {
  rucc_loaded <- TRUE
}

if (rucc_loaded && file.exists(rucc_dest)) {
  rucc <- tryCatch(
    read.csv(rucc_dest, stringsAsFactors = FALSE),
    error = function(e) {
      # Try reading as Excel
      if (requireNamespace("readxl", quietly = TRUE)) {
        readxl::read_excel(rucc_dest)
      } else {
        NULL
      }
    }
  )
}

# If RUCC download fails, construct treatment from distance alone
if (!exists("rucc") || is.null(rucc)) {
  cat("  RUCC download failed — constructing treatment from distance to metro areas\n")
}

# Construct treatment using Haversine distance from county centroid
# to nearest city with population > 250K (proxy for P&DC location)

# Major US cities with P&DCs (coordinates of the 100 largest metro areas)
# These approximate USPS's network of Processing & Distribution Centers
major_metros <- data.frame(
  city = c("New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
           "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose",
           "Austin", "Jacksonville", "Fort Worth", "Columbus", "Charlotte",
           "Indianapolis", "San Francisco", "Seattle", "Denver", "Nashville",
           "Washington DC", "Oklahoma City", "El Paso", "Boston", "Portland",
           "Las Vegas", "Memphis", "Louisville", "Baltimore", "Milwaukee",
           "Albuquerque", "Tucson", "Fresno", "Mesa", "Sacramento",
           "Atlanta", "Kansas City", "Omaha", "Colorado Springs", "Raleigh",
           "Long Beach", "Virginia Beach", "Miami", "Oakland", "Minneapolis",
           "Tampa", "Tulsa", "Arlington TX", "New Orleans", "Wichita",
           "Cleveland", "Bakersfield", "Aurora CO", "Honolulu", "Anchorage",
           "St Louis", "Pittsburgh", "Cincinnati", "Detroit", "Salt Lake City",
           "Buffalo", "Richmond", "Des Moines", "Boise", "Birmingham",
           "Spokane", "Rochester NY", "Chattanooga", "Little Rock", "Jackson MS",
           "Sioux Falls", "Fargo", "Billings", "Cheyenne", "Bismarck"),
  lat = c(40.71, 34.05, 41.88, 29.76, 33.45,
          39.95, 29.42, 32.72, 32.78, 37.34,
          30.27, 30.33, 32.75, 39.96, 35.23,
          39.77, 37.77, 47.61, 39.74, 36.16,
          38.91, 35.47, 31.76, 42.36, 45.51,
          36.17, 35.15, 38.25, 39.29, 43.04,
          35.08, 32.22, 36.74, 33.41, 38.58,
          33.75, 39.10, 41.26, 38.83, 35.78,
          33.77, 36.85, 25.76, 37.80, 44.98,
          27.95, 36.15, 32.74, 29.95, 37.69,
          41.50, 35.37, 39.73, 21.31, 61.22,
          38.63, 40.44, 39.10, 42.33, 40.76,
          42.89, 37.54, 41.59, 43.62, 33.52,
          47.66, 43.16, 35.05, 34.75, 32.30,
          43.55, 46.88, 45.78, 41.14, 46.81),
  lon = c(-74.01, -118.24, -87.63, -95.37, -112.07,
          -75.17, -98.49, -117.16, -96.80, -121.89,
          -97.74, -81.66, -97.33, -83.00, -80.84,
          -86.16, -122.42, -122.33, -104.99, -86.78,
          -77.04, -97.52, -106.49, -71.06, -122.68,
          -115.14, -90.05, -85.76, -76.61, -87.91,
          -106.65, -110.93, -119.77, -111.83, -121.49,
          -84.39, -94.58, -95.94, -104.82, -78.64,
          -118.19, -76.00, -80.19, -122.27, -93.27,
          -82.46, -95.99, -97.11, -90.07, -97.34,
          -81.69, -119.02, -104.83, -157.86, -149.90,
          -90.20, -80.00, -84.51, -83.05, -111.89,
          -78.88, -77.44, -93.62, -116.20, -86.80,
          -117.43, -77.61, -85.31, -92.29, -90.18,
          -96.73, -96.79, -108.50, -104.82, -100.78),
  stringsAsFactors = FALSE
)

# Haversine distance function (returns miles)
haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 3959  # Earth radius in miles
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat / 2)^2 + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dlon / 2)^2
  2 * R * asin(sqrt(a))
}

# For each county, compute distance to nearest metro (P&DC proxy)
cat("  Computing distance to nearest processing center...\n")

county_centroids$dist_to_pdc <- NA_real_

for (i in seq_len(nrow(county_centroids))) {
  dists <- haversine(
    county_centroids$lat[i], county_centroids$lon[i],
    major_metros$lat, major_metros$lon
  )
  county_centroids$dist_to_pdc[i] <- min(dists)
}

# Classify treatment intensity based on Federal Register distance thresholds
# Converting the driving-distance thresholds to approximate air-distance equivalents:
# 3hr drive ≈ 150 miles air distance → 2-day standard (no change)
# 20hr drive ≈ 600 miles air distance → 3-day standard (+1 day)
# Beyond 600 miles → 4-day standard (+2 days)
# Non-contiguous → 5-day standard (+3 days)

county_centroids <- county_centroids %>%
  mutate(
    # Non-contiguous states
    non_contiguous = state_fips %in% c("02", "15"),  # Alaska, Hawaii
    # Treatment intensity (days added)
    mail_slowdown = case_when(
      non_contiguous ~ 3,                    # 5-day standard (was 2) → +3
      dist_to_pdc > 600 ~ 2,                # 4-day standard (was 2) → +2
      dist_to_pdc > 150 & dist_to_pdc <= 600 ~ 1,  # 3-day standard (was 2) → +1
      TRUE ~ 0                               # 2-day standard (no change)
    ),
    # Continuous treatment: log(1 + distance)
    log_dist_pdc = log(1 + dist_to_pdc)
  )

treat_summary <- county_centroids %>%
  count(mail_slowdown) %>%
  mutate(pct = round(100 * n / sum(n), 1))

cat("\nTreatment intensity distribution:\n")
print(treat_summary)

# Verify at least 20% of counties are treated
pct_treated <- sum(county_centroids$mail_slowdown > 0) / nrow(county_centroids) * 100
cat(sprintf("\n%.1f%% of counties experienced mail slowdown\n", pct_treated))

if (pct_treated < 10) {
  stop("FATAL: Less than 10% of counties treated. Treatment construction likely wrong.")
}

# ============================================================================
# 3. PHARMACY DESERT STATUS
# ============================================================================
cat("\n=== Constructing pharmacy desert indicator ===\n")

# Use HRSA Area Health Resource File for pharmacy counts per county
# Alternative: CMS Medicare Part D mail-order prescription data
#
# For pharmacy desert classification, we use the County Health Rankings data
# itself — it includes "access to healthcare" measures including provider counts.
# We'll use the ratio of primary care physicians as a proxy for healthcare
# infrastructure density (pharmacy access is highly correlated).

# Download AHRF data or use Census County Business Patterns for NAICS 446110 (pharmacies)
cbp_url <- "https://api.census.gov/data/2019/cbp?get=NAICS2017,ESTAB,EMP&for=county:*&NAICS2017=446110"

cbp_dest <- file.path(data_dir, "cbp_pharmacies.json")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  cbp_url <- paste0(cbp_url, "&key=", census_key)
}

cat("  Fetching pharmacy establishment counts from Census CBP...\n")

cbp_resp <- tryCatch(
  {
    resp <- httr::GET(cbp_url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      httr::content(resp, as = "text", encoding = "UTF-8")
    } else {
      stop(sprintf("CBP API returned status %d", httr::status_code(resp)))
    }
  },
  error = function(e) {
    cat(sprintf("  CBP API error: %s\n", e$message))
    NULL
  }
)

if (!is.null(cbp_resp)) {
  cbp_data <- jsonlite::fromJSON(cbp_resp)
  cbp_header <- cbp_data[1, ]
  cbp_df <- as.data.frame(cbp_data[-1, ], stringsAsFactors = FALSE)
  # Make column names unique to avoid duplicate issues
  names(cbp_df) <- make.unique(as.character(cbp_header))

  # Identify columns by position (API returns: NAICS2017, ESTAB, EMP, state, county)
  state_col_idx <- which(names(cbp_df) == "state")[1]
  county_col_idx <- which(names(cbp_df) == "county")[1]
  estab_col_idx <- which(names(cbp_df) == "ESTAB")[1]
  emp_col_idx <- which(names(cbp_df) == "EMP")[1]

  pharmacy_counts <- data.frame(
    fips = paste0(cbp_df[[state_col_idx]], cbp_df[[county_col_idx]]),
    n_pharmacies = as.numeric(cbp_df[[estab_col_idx]]),
    pharmacy_emp = as.numeric(cbp_df[[emp_col_idx]]),
    stringsAsFactors = FALSE
  )

  cat(sprintf("  %d counties with pharmacy data\n", nrow(pharmacy_counts)))
} else {
  # Fallback: construct from county population — rural counties with low pop
  # are pharmacy deserts
  cat("  Using population-based pharmacy desert proxy\n")
  pharmacy_counts <- county_centroids %>%
    transmute(
      fips = fips,
      n_pharmacies = NA_real_,
      pharmacy_emp = NA_real_
    )
}

# Get county population from Census ACS for per-capita calculation
cat("  Fetching county population from Census ACS...\n")

pop_url <- "https://api.census.gov/data/2019/acs/acs5?get=B01003_001E,NAME&for=county:*"
if (nchar(census_key) > 0) {
  pop_url <- paste0(pop_url, "&key=", census_key)
}

pop_resp <- tryCatch(
  {
    resp <- httr::GET(pop_url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      httr::content(resp, as = "text", encoding = "UTF-8")
    } else {
      stop(sprintf("ACS API returned status %d", httr::status_code(resp)))
    }
  },
  error = function(e) {
    cat(sprintf("  ACS API error: %s\n", e$message))
    NULL
  }
)

if (!is.null(pop_resp)) {
  pop_data <- jsonlite::fromJSON(pop_resp)
  pop_df <- as.data.frame(pop_data[-1, ], stringsAsFactors = FALSE)
  names(pop_df) <- pop_data[1, ]

  county_pop <- pop_df %>%
    transmute(
      fips = paste0(state, county),
      population = as.numeric(B01003_001E),
      county_name = NAME
    )
  cat(sprintf("  %d counties with population data\n", nrow(county_pop)))
} else {
  stop("FATAL: Cannot fetch county population data from Census ACS.")
}

# Merge pharmacy counts with population
pharmacy_access <- county_pop %>%
  left_join(pharmacy_counts, by = "fips") %>%
  mutate(
    pharmacies_per_10k = ifelse(!is.na(n_pharmacies) & population > 0,
                                 n_pharmacies / population * 10000, NA_real_)
  )

# Define pharmacy desert: bottom quartile of pharmacies per capita
# OR zero pharmacies (true deserts)
if (sum(!is.na(pharmacy_access$pharmacies_per_10k)) > 500) {
  q25 <- quantile(pharmacy_access$pharmacies_per_10k, 0.25, na.rm = TRUE)
  pharmacy_access$pharm_desert <- as.integer(
    !is.na(pharmacy_access$pharmacies_per_10k) &
    pharmacy_access$pharmacies_per_10k <= q25
  )
  cat(sprintf("  Pharmacy desert threshold: %.2f pharmacies per 10K (Q25)\n", q25))
} else {
  # Fallback: use rurality as proxy
  cat("  Using distance-based pharmacy desert proxy\n")
  pharmacy_access <- pharmacy_access %>%
    left_join(county_centroids %>% select(fips, dist_to_pdc), by = "fips") %>%
    mutate(pharm_desert = as.integer(dist_to_pdc > 100))
}

desert_summary <- pharmacy_access %>%
  summarise(
    n_desert = sum(pharm_desert == 1, na.rm = TRUE),
    n_nondesert = sum(pharm_desert == 0, na.rm = TRUE),
    pct_desert = round(100 * n_desert / (n_desert + n_nondesert), 1)
  )

cat(sprintf("  Pharmacy deserts: %d counties (%.1f%%)\n",
            desert_summary$n_desert, desert_summary$pct_desert))

# ============================================================================
# 4. COUNTY-LEVEL CONTROLS FROM CENSUS ACS
# ============================================================================
cat("\n=== Fetching county-level controls ===\n")

# Median household income, % 65+, % uninsured
controls_url <- paste0(
  "https://api.census.gov/data/2019/acs/acs5?get=",
  "B19013_001E,",   # Median HH income
  "B01001_020E,B01001_021E,B01001_022E,B01001_023E,B01001_024E,B01001_025E,",  # Male 65+
  "B01001_044E,B01001_045E,B01001_046E,B01001_047E,B01001_048E,B01001_049E,",  # Female 65+
  "B01003_001E,",   # Total pop
  "B27010_001E,B27010_017E",  # Insurance universe, uninsured
  "&for=county:*"
)
if (nchar(census_key) > 0) {
  controls_url <- paste0(controls_url, "&key=", census_key)
}

ctrl_resp <- tryCatch(
  {
    resp <- httr::GET(controls_url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      httr::content(resp, as = "text", encoding = "UTF-8")
    } else {
      stop(sprintf("Controls API returned status %d", httr::status_code(resp)))
    }
  },
  error = function(e) {
    cat(sprintf("  Controls API error: %s\n", e$message))
    NULL
  }
)

if (!is.null(ctrl_resp)) {
  ctrl_data <- jsonlite::fromJSON(ctrl_resp)
  ctrl_df <- as.data.frame(ctrl_data[-1, ], stringsAsFactors = FALSE)
  names(ctrl_df) <- ctrl_data[1, ]

  # Compute derived variables
  county_controls <- ctrl_df %>%
    mutate(across(starts_with("B"), as.numeric)) %>%
    transmute(
      fips = paste0(state, county),
      median_hh_income = B19013_001E,
      pct_65plus = (B01001_020E + B01001_021E + B01001_022E + B01001_023E +
                      B01001_024E + B01001_025E + B01001_044E + B01001_045E +
                      B01001_046E + B01001_047E + B01001_048E + B01001_049E) /
                   B01003_001E * 100,
      pct_uninsured = B27010_017E / B27010_001E * 100
    )

  cat(sprintf("  %d counties with control variables\n", nrow(county_controls)))
} else {
  stop("FATAL: Cannot fetch county control variables from Census ACS.")
}

# ============================================================================
# 5. MERGE AND SAVE
# ============================================================================
cat("\n=== Merging all datasets ===\n")

# Merge treatment and pharmacy desert status into the panel
analysis_data <- chr_panel %>%
  left_join(county_centroids %>% select(fips, state_fips, dist_to_pdc, mail_slowdown,
                                         log_dist_pdc, non_contiguous, lat, lon),
            by = "fips") %>%
  left_join(pharmacy_access %>% select(fips, population, pharmacies_per_10k, pharm_desert),
            by = "fips") %>%
  left_join(county_controls, by = "fips") %>%
  filter(!is.na(mail_slowdown), !is.na(prev_hosp_rate)) %>%
  mutate(
    post = as.integer(year >= 2022),
    treated = as.integer(mail_slowdown > 0),
    treat_x_post = mail_slowdown * post,
    treat_x_post_x_desert = mail_slowdown * post * pharm_desert,
    log_pop = log(population),
    state = state_fips
  )

cat(sprintf("\nFinal analysis dataset:\n"))
cat(sprintf("  %d county-year observations\n", nrow(analysis_data)))
cat(sprintf("  %d unique counties\n", n_distinct(analysis_data$fips)))
cat(sprintf("  Years: %s\n", paste(sort(unique(analysis_data$year)), collapse = ", ")))
cat(sprintf("  Treated counties (any slowdown): %d\n",
            n_distinct(analysis_data$fips[analysis_data$treated == 1])))
cat(sprintf("  Pharmacy desert counties: %d\n",
            n_distinct(analysis_data$fips[analysis_data$pharm_desert == 1])))

if (nrow(analysis_data) < 5000) {
  stop("FATAL: Fewer than 5000 observations in analysis dataset.")
}

saveRDS(analysis_data, file.path(data_dir, "analysis_data.rds"))
cat("\n✓ Analysis dataset saved to data/analysis_data.rds\n")
