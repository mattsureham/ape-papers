# 01_fetch_data.R — Fetch Census CBP, county adjacency, and ACS data
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

source("00_packages.R")

# Load API key from .env
census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") {
  dotenv_path <- file.path(dirname(dirname(dirname(dirname(getwd())))), ".env")
  if (file.exists(dotenv_path)) {
    envs <- readLines(dotenv_path, warn = FALSE)
    for (line in envs) {
      if (grepl("^CENSUS_API_KEY=", line)) {
        census_key <- sub("^CENSUS_API_KEY=", "", line)
        census_key <- gsub("['\"]", "", census_key)
      }
    }
  }
}
stopifnot("CENSUS_API_KEY not found" = census_key != "")
cat("Census API key loaded.\n")

# Helper: fetch CBP for one NAICS code, one year
fetch_cbp_year <- function(yr, naics_code) {
  # Determine NAICS parameter name by year
  naics_param <- if (yr >= 2017) "NAICS2017" else if (yr >= 2012) "NAICS2012" else "NAICS2007"

  url <- sprintf(
    "https://api.census.gov/data/%d/cbp?get=ESTAB,EMP,PAYANN&for=county:*&%s=%s&key=%s",
    yr, naics_param, naics_code, census_key
  )

  resp <- GET(url, timeout(120))

  if (status_code(resp) != 200) {
    # Fallback: try NAICS2017 regardless of year
    url2 <- sprintf(
      "https://api.census.gov/data/%d/cbp?get=ESTAB,EMP,PAYANN&for=county:*&NAICS2017=%s&key=%s",
      yr, naics_code, census_key
    )
    resp <- GET(url2, timeout(120))
  }

  if (status_code(resp) != 200) return(NULL)

  raw <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$year <- yr
  df$fips <- paste0(df$state, df$county)

  for (col in c("ESTAB", "EMP", "PAYANN")) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }

  return(df)
}

# ─── 1. Funeral Homes (NAICS 812210) ───
cbp_all <- list()
for (yr in 2017:2022) {
  cat(sprintf("Fetching CBP funeral homes %d...\n", yr))
  df <- fetch_cbp_year(yr, "812210")
  if (!is.null(df)) {
    cbp_all[[as.character(yr)]] <- df
    cat(sprintf("  Got %d counties\n", nrow(df)))
  }
  Sys.sleep(0.5)
}

cbp <- bind_rows(cbp_all)
stopifnot("CBP funeral home data is empty" = nrow(cbp) > 0)
cat(sprintf("CBP funeral homes total: %d county-year obs\n", nrow(cbp)))
write_csv(cbp, "../data/cbp_funeral_homes.csv")

# ─── 2. Cemeteries/Crematories (NAICS 812220) ───
cbp_crem_all <- list()
for (yr in 2017:2022) {
  cat(sprintf("Fetching CBP crematories %d...\n", yr))
  df <- fetch_cbp_year(yr, "812220")
  if (!is.null(df)) {
    cbp_crem_all[[as.character(yr)]] <- df
    cat(sprintf("  Got %d counties\n", nrow(df)))
  }
  Sys.sleep(0.5)
}

if (length(cbp_crem_all) > 0) {
  cbp_crem <- bind_rows(cbp_crem_all)
  write_csv(cbp_crem, "../data/cbp_cemeteries_crematories.csv")
  cat(sprintf("Saved crematories: %d obs\n", nrow(cbp_crem)))
}

# ─── 3. County Adjacency ───
# Build border pairs from Census adjacency file
cat("Fetching county adjacency file...\n")

# The adjacency file is tab-delimited with merged cells
adj_url <- "https://www2.census.gov/programs-surveys/geography/relatednotes/county-adjacency24.txt"
resp <- GET(adj_url, timeout(120))

if (status_code(resp) != 200) {
  adj_url2 <- "https://www2.census.gov/programs-surveys/geography/relatednotes/county-adjacency.txt"
  resp <- GET(adj_url2, timeout(120))
}

if (status_code(resp) == 200) {
  adj_raw <- content(resp, as = "text", encoding = "UTF-8")
  writeLines(adj_raw, "../data/county_adjacency_raw.txt")
  cat("Saved county adjacency file.\n")
} else {
  cat(sprintf("Adjacency file returned %d. Will construct pairs from FIPS.\n", status_code(resp)))
  # Create a manual adjacency approach in 02_clean_data.R
  writeLines("MANUAL", "../data/county_adjacency_raw.txt")
}

# ─── 4. ACS County Demographics (2021 5-year) ───
cat("Fetching ACS demographics...\n")

acs_url <- sprintf(
  "https://api.census.gov/data/2021/acs/acs5?get=B01003_001E,B19013_001E,B01001_020E,B01001_021E,B01001_022E,B01001_023E,B01001_024E,B01001_025E,B01001_044E,B01001_045E,B01001_046E,B01001_047E,B01001_048E,B01001_049E,NAME&for=county:*&key=%s",
  census_key
)

resp <- GET(acs_url, timeout(120))
stopifnot("ACS fetch failed" = status_code(resp) == 200)

raw <- content(resp, as = "text", encoding = "UTF-8")
parsed <- fromJSON(raw)
acs <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
names(acs) <- parsed[1, ]
acs$fips <- paste0(acs$state, acs$county)

for (col in setdiff(names(acs), c("NAME", "state", "county", "fips"))) {
  acs[[col]] <- suppressWarnings(as.numeric(acs[[col]]))
}

acs <- acs %>%
  mutate(
    total_pop = B01003_001E,
    median_income = B19013_001E,
    pop_65plus = B01001_020E + B01001_021E + B01001_022E +
                 B01001_023E + B01001_024E + B01001_025E +
                 B01001_044E + B01001_045E + B01001_046E +
                 B01001_047E + B01001_048E + B01001_049E,
    pct_65plus = pop_65plus / total_pop * 100
  ) %>%
  select(fips, NAME, state_fips = state, total_pop, median_income, pop_65plus, pct_65plus)

write_csv(acs, "../data/acs_demographics.csv")
cat(sprintf("Saved ACS: %d counties\n", nrow(acs)))

# ─── 5. Urbanization codes from USDA ───
cat("Fetching USDA rural-urban codes...\n")
ruca_url <- "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv"
resp <- GET(ruca_url, timeout(60))

if (status_code(resp) == 200) {
  ruca_raw <- content(resp, as = "text", encoding = "UTF-8")
  writeLines(ruca_raw, "../data/rucc2013.csv")
  cat("Saved rural-urban codes.\n")
} else {
  cat("RUCC download failed. Will use population as urbanization proxy.\n")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Files: %s\n", paste(list.files("../data/"), collapse = ", ")))
