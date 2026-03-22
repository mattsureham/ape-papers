## 01_fetch_data.R — Fetch CBP + ACS data
source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot("CENSUS_API_KEY not set" = nzchar(census_key))

# ---- County Business Patterns (2010-2021) ----
# NAICS 445110 = Supermarkets; 445120 = Convenience retailers
fetch_cbp_year <- function(yr, naics_code) {
  # Choose correct NAICS variable name by vintage
  naics_var <- if (yr <= 2011) "NAICS2007" else if (yr <= 2016) "NAICS2012" else "NAICS2017"

  url <- paste0("https://api.census.gov/data/", yr, "/cbp")
  resp <- GET(url, query = setNames(
    list(paste0("ESTAB,EMP,", naics_var), naics_code, "*", "*", census_key),
    c("get", naics_var, "for", "in", "key")
  ))
  # Fix: 'for' and 'in' are reserved; use the list correctly
  resp <- GET(url, query = list(
    get   = paste0("ESTAB,EMP,", naics_var),
    `for` = "county:*",
    `in`  = "state:*",
    key   = census_key
  ))
  # Add NAICS filter
  resp <- GET(url, query = stats::setNames(
    list(paste0("ESTAB,EMP,", naics_var), naics_code, "county:*", "state:*", census_key),
    c("get", naics_var, "for", "in", "key")
  ))

  if (resp$status_code != 200) {
    warning(sprintf("CBP %d NAICS %s: HTTP %d", yr, naics_code, resp$status_code))
    return(NULL)
  }
  raw <- content(resp, as = "text", encoding = "UTF-8")
  mat <- fromJSON(raw)
  df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
  names(df) <- mat[1, ]
  df$year <- yr
  df$naics <- naics_code
  df$ESTAB <- suppressWarnings(as.integer(df$ESTAB))
  df$EMP   <- suppressWarnings(as.integer(df$EMP))
  df$fips  <- paste0(df$state, df$county)
  df
}

cat("Fetching CBP data (2010-2021)...\n")
cbp_list <- list()
for (yr in 2010:2021) {
  for (nc in c("445110", "445120")) {
    key <- paste(yr, nc, sep = "_")
    cat(sprintf("  %s...\n", key))
    res <- tryCatch(fetch_cbp_year(yr, nc), error = function(e) {
      warning(sprintf("Failed %s: %s", key, e$message))
      NULL
    })
    if (!is.null(res) && nrow(res) > 0) {
      cbp_list[[key]] <- res
    } else {
      stop(sprintf("FATAL: No data returned for CBP %s. Cannot proceed with simulated data.", key))
    }
    Sys.sleep(0.5)
  }
}
cbp_raw <- bind_rows(cbp_list)
cat(sprintf("CBP: %d rows fetched across %d year-NAICS combos.\n", nrow(cbp_raw), length(cbp_list)))
stopifnot("CBP data is empty — data fetch failed" = nrow(cbp_raw) > 0)

saveRDS(cbp_raw, "../data/cbp_raw.rds")

# ---- ACS 5-year demographics (2015, 2021) ----
cat("Fetching ACS demographics...\n")
census_api_key(census_key, install = FALSE, overwrite = TRUE)

fetch_acs_vars <- function(yr) {
  acs <- get_acs(
    geography = "county",
    variables = c(
      total_pop   = "B01003_001",
      poverty_pop = "B17001_002",
      no_vehicle  = "B08201_002",
      total_hh    = "B08201_001"
    ),
    year    = yr,
    survey  = "acs5",
    output  = "wide"
  )
  acs <- acs %>%
    transmute(
      fips       = GEOID,
      year       = yr,
      total_pop  = total_popE,
      poverty_rate = poverty_popE / total_popE,
      no_veh_share = no_vehicleE / total_hhE
    )
  acs
}

acs_2015 <- fetch_acs_vars(2015)
acs_2021 <- fetch_acs_vars(2021)
acs_all  <- bind_rows(acs_2015, acs_2021)
cat(sprintf("ACS: %d county-year observations.\n", nrow(acs_all)))
stopifnot("ACS data is empty" = nrow(acs_all) > 0)

saveRDS(acs_all, "../data/acs_raw.rds")

# ---- Rural/Urban Classification from ACS ----
# Derive rural/urban from population: counties < 50,000 population = rural
# This approximates USDA RUCC codes 4-9 (nonmetro)
cat("Deriving rural/urban classification from ACS population data...\n")
acs_2015_loaded <- readRDS("../data/acs_raw.rds") %>% filter(year == 2015)
rucc <- acs_2015_loaded %>%
  transmute(
    fips  = fips,
    rural = as.integer(total_pop < 50000)
  )
saveRDS(rucc, "../data/rucc.rds")
cat(sprintf("Rural classification: %d counties (%d rural, %d urban).\n",
            nrow(rucc), sum(rucc$rural, na.rm = TRUE), sum(!rucc$rural, na.rm = TRUE)))

cat("Data fetch complete.\n")
