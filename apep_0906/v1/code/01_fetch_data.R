## 01_fetch_data.R — Fetch QWI and port data
## apep_0906: Panama Canal Expansion and Port Labor Markets
##
## Data: Census QWI API for county-level quarterly employment by NAICS

library(tidyverse)
library(httr)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  # Try loading from .env
  env_file <- file.path(dirname(dirname(dirname(dirname(getwd())))), ".env")
  if (file.exists(env_file)) {
    env_lines <- readLines(env_file)
    key_line <- grep("^CENSUS_API_KEY=", env_lines, value = TRUE)
    if (length(key_line) > 0) {
      census_key <- sub("^CENSUS_API_KEY=", "", key_line[1])
      census_key <- gsub("[\"\' ]", "", census_key)
    }
  }
}

if (nchar(census_key) == 0) {
  stop("FATAL: CENSUS_API_KEY not found in environment or .env")
}

cat("Census API key loaded\n")

# ============================================================
# 1. DEFINE PORT COUNTIES
# ============================================================

# Major US container ports and their FIPS county codes
# East/Gulf Coast (TREATMENT — gained Neo-Panamax access June 2016)
east_gulf_ports <- tribble(
  ~port_name, ~state_fips, ~county_fips, ~region,
  "Savannah, GA",       "13", "051",  "East",     # Chatham County
  "Charleston, SC",     "45", "019",  "East",     # Charleston County
  "Norfolk/Hampton Roads, VA", "51", "710", "East", # Norfolk city (independent)
  "Baltimore, MD",      "24", "510",  "East",     # Baltimore city
  "Port Everglades, FL","12", "011",  "East",     # Broward County
  "Miami, FL",          "12", "086",  "East",     # Miami-Dade County
  "Jacksonville, FL",   "12", "031",  "East",     # Duval County
  "New York/Newark, NJ","34", "017",  "East",     # Hudson County, NJ
  "Philadelphia, PA",   "42", "101",  "East",     # Philadelphia County
  "Houston, TX",        "48", "201",  "Gulf",     # Harris County
  "New Orleans, LA",    "22", "071",  "Gulf",     # Orleans Parish
  "Mobile, AL",         "01", "097",  "Gulf",     # Mobile County
  "Gulfport, MS",       "28", "047",  "Gulf",     # Harrison County
  "Tampa, FL",          "12", "057",  "Gulf",     # Hillsborough County
  "Port Arthur, TX",    "48", "245",  "Gulf",     # Jefferson County
  "Brunswick, GA",      "13", "127",  "East",     # Glynn County
  "Port Canaveral, FL", "12", "009",  "East",     # Brevard County
  "Manatee/Port Manatee, FL", "12", "081", "Gulf", # Manatee County
  "Pascagoula, MS",     "28", "059",  "Gulf",     # Jackson County
  "Freeport, TX",       "48", "039",  "Gulf",     # Brazoria County
  "Corpus Christi, TX", "48", "355",  "Gulf",     # Nueces County
  "Lake Charles, LA",   "22", "019",  "Gulf"      # Calcasieu Parish
)

# West Coast (CONTROL — already had mega-ship access)
west_coast_ports <- tribble(
  ~port_name, ~state_fips, ~county_fips, ~region,
  "Los Angeles, CA",    "06", "037",  "West",     # Los Angeles County
  "Long Beach, CA",     "06", "037",  "West",     # Same county as LA
  "Oakland, CA",        "06", "001",  "West",     # Alameda County
  "Seattle, WA",        "53", "033",  "West",     # King County
  "Tacoma, WA",         "53", "053",  "West"      # Pierce County
)

all_ports <- bind_rows(east_gulf_ports, west_coast_ports) %>%
  distinct(state_fips, county_fips, .keep_all = TRUE)

cat("Port counties defined:", nrow(all_ports), "unique counties\n")
cat("  East Coast:", sum(all_ports$region == "East"), "\n")
cat("  Gulf Coast:", sum(all_ports$region == "Gulf"), "\n")
cat("  West Coast:", sum(all_ports$region == "West"), "\n")

# ============================================================
# 2. FETCH QWI DATA FROM CENSUS API
# ============================================================

cat("\n=== Fetching QWI data from Census API ===\n")

# QWI API endpoint
# Variables: Emp (employment), EmpEnd, EarnBeg, HirN (new hires), Sep (separations)
# NAICS: 48-49 (Transportation and Warehousing), 42 (Wholesale Trade)
# Geography: county level

qwi_base <- "https://api.census.gov/data/timeseries/qwi/sa"

# Function to fetch QWI for one state-year
fetch_qwi <- function(state_fips, year, quarter, naics_codes = c("48-49", "42"),
                       api_key = census_key) {
  results <- list()

  for (naics in naics_codes) {
    url <- paste0(
      qwi_base,
      "?get=Emp,EmpEnd,EmpS,EarnBeg,EarnS,HirN,Sep",
      "&for=county:*",
      "&in=state:", state_fips,
      "&year=", year,
      "&quarter=", quarter,
      "&industry=", naics,
      "&ownercode=A05",
      "&sex=0",
      "&agegrp=A00",
      "&race=A0",
      "&ethnicity=A0",
      "&education=E0",
      "&key=", api_key
    )

    resp <- GET(url, timeout(30))

    if (status_code(resp) == 200) {
      txt <- content(resp, "text", encoding = "UTF-8")
      if (nchar(txt) > 50 && !grepl("error", txt, ignore.case = TRUE)) {
        json_data <- fromJSON(txt)
        if (is.matrix(json_data) && nrow(json_data) > 1) {
          df <- as.data.frame(json_data[-1, , drop = FALSE], stringsAsFactors = FALSE)
          names(df) <- json_data[1, ]
          df$industry <- naics
          results[[length(results) + 1]] <- df
        }
      }
    }

    Sys.sleep(0.3)  # Rate limiting
  }

  if (length(results) > 0) {
    return(bind_rows(results))
  } else {
    return(NULL)
  }
}

# Fetch for all port county states, 2010-2023
port_states <- unique(all_ports$state_fips)
all_qwi <- list()
counter <- 0

for (st in port_states) {
  for (yr in 2010:2023) {
    for (qtr in 1:4) {
      df <- fetch_qwi(st, yr, qtr)
      if (!is.null(df) && nrow(df) > 0) {
        all_qwi[[length(all_qwi) + 1]] <- df
        counter <- counter + nrow(df)
      }

      # Progress every 20 calls
      if (length(all_qwi) %% 20 == 0) {
        cat("  Fetched", length(all_qwi), "chunks,", counter, "total rows\n")
      }
    }
  }
  cat("  Completed state:", st, "\n")
}

if (length(all_qwi) == 0) {
  stop("FATAL: No QWI data fetched. Check Census API key and connectivity.")
}

qwi_raw <- bind_rows(all_qwi)

cat("\nQWI data fetched:", nrow(qwi_raw), "rows\n")
cat("States:", n_distinct(qwi_raw$state), "\n")
cat("Counties:", n_distinct(paste0(qwi_raw$state, qwi_raw$county)), "\n")

# Filter to port counties only
qwi_ports <- qwi_raw %>%
  inner_join(all_ports, by = c("state" = "state_fips", "county" = "county_fips"))

cat("Port county QWI rows:", nrow(qwi_ports), "\n")

# Convert numeric columns
numeric_cols <- c("Emp", "EmpEnd", "EmpS", "EarnBeg", "EarnS", "HirN", "Sep")
qwi_ports <- qwi_ports %>%
  mutate(across(all_of(numeric_cols), as.numeric),
         year = as.integer(year),
         quarter = as.integer(quarter))

# ============================================================
# 3. ALSO FETCH PLACEBO INDUSTRIES
# ============================================================
cat("\n=== Fetching placebo industry data ===\n")

# NAICS 62 (Healthcare), 54 (Professional Services) — no canal exposure
placebo_qwi <- list()

for (st in port_states) {
  for (yr in c(2013:2019)) {  # Narrower window for placebos
    for (qtr in 1:4) {
      df <- fetch_qwi(st, yr, qtr, naics_codes = c("62", "54"))
      if (!is.null(df) && nrow(df) > 0) {
        placebo_qwi[[length(placebo_qwi) + 1]] <- df
      }
    }
  }
  cat("  Placebo completed state:", st, "\n")
}

if (length(placebo_qwi) > 0) {
  placebo_raw <- bind_rows(placebo_qwi)
  placebo_ports <- placebo_raw %>%
    inner_join(all_ports, by = c("state" = "state_fips", "county" = "county_fips")) %>%
    mutate(across(all_of(numeric_cols), as.numeric),
           year = as.integer(year),
           quarter = as.integer(quarter))
  cat("Placebo port county rows:", nrow(placebo_ports), "\n")
  saveRDS(placebo_ports, file.path(data_dir, "qwi_placebo.rds"))
}

# ============================================================
# 4. SAVE
# ============================================================

saveRDS(qwi_ports, file.path(data_dir, "qwi_ports.rds"))
saveRDS(all_ports, file.path(data_dir, "port_counties.rds"))

cat("\n=== DATA FETCH SUMMARY ===\n")
cat("QWI port data:", nrow(qwi_ports), "rows\n")
cat("Port counties:", nrow(all_ports), "\n")
cat("Years:", min(qwi_ports$year, na.rm = TRUE), "-", max(qwi_ports$year, na.rm = TRUE), "\n")
cat("Industries: 48-49 (Transport), 42 (Wholesale)\n")

# Quick validation
cat("\nSavannah (13051) transport employment:\n")
qwi_ports %>%
  filter(state == "13", county == "051", industry == "48-49", quarter == 1) %>%
  select(year, Emp, HirN) %>%
  arrange(year) %>%
  print(n = 20)

cat("\nData fetch complete.\n")
