## 01_fetch_data.R — Data acquisition for apep_0963
## Fetches CPS Food Security Supplement microdata, ACS SNAP rates, and controls

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot("CENSUS_API_KEY not set" = nchar(census_key) > 0)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## =========================================================================
## Part 1: CPS Food Security Supplement microdata via Census API
## =========================================================================
cat("=== Fetching CPS Food Security Supplement data ===\n")

## CPS FSS variables
## HRFS12M1: 12-month food security status (1=High, 2=Marginal, 3=Low, 4=Very Low, -1=Not in universe)
## HESP1: SNAP receipt (1=Yes, 2=No)
## GESTFIPS: State FIPS code
## PRTAGE: Person age
## PEEDUCA: Education (31-46 scale)
## PTDTRACE: Race
## PEHSPNON: Hispanic origin (1=Hispanic, 2=Non-Hispanic)
## HEFAMINC: Family income category
## HRNUMHOU: Number of household members
## PRCHLD: Number of own children
## HWHHWGT: Household weight (implied decimal 4 places)
## PERRP: Relationship to reference person (40/41 = reference person)

cps_vars <- c("HRFS12M1", "HESP1", "GESTFIPS", "PRTAGE", "PEEDUCA",
              "PTDTRACE", "PEHSPNON", "HEFAMINC", "HRNUMHOU", "PRCHLD",
              "HWHHWGT", "PERRP", "HRHHID", "HRHHID2")

fetch_cps_fss <- function(year, api_key) {
  cat(sprintf("  Fetching CPS FSS for %d...\n", year))

  base_url <- sprintf("https://api.census.gov/data/%d/cps/foodsec/dec", year)

  ## First check what variables are available
  vars_url <- paste0(base_url, "/variables.json")
  vars_resp <- tryCatch(GET(vars_url, timeout(30)), error = function(e) NULL)

  if (is.null(vars_resp) || status_code(vars_resp) != 200) {
    cat(sprintf("    WARNING: CPS FSS API not available for %d\n", year))
    return(NULL)
  }

  ## Determine which requested vars are available
  vars_json <- content(vars_resp, "parsed")
  available_vars <- names(vars_json$variables)
  use_vars <- intersect(cps_vars, available_vars)

  if (!"HRFS12M1" %in% use_vars) {
    cat(sprintf("    WARNING: HRFS12M1 not available for %d, trying alternate names\n", year))
    ## Try alternate variable names
    if ("HRFS12MD" %in% available_vars) use_vars <- c(use_vars, "HRFS12MD")
    if ("HRFS12M1" %in% available_vars) use_vars <- c(use_vars, "HRFS12M1")
    use_vars <- unique(use_vars)
  }

  if (length(use_vars) < 3) {
    cat(sprintf("    WARNING: Too few variables available for %d\n", year))
    return(NULL)
  }

  ## Fetch data
  get_string <- paste(use_vars, collapse = ",")
  query_url <- sprintf("%s?get=%s&for=state:*&key=%s", base_url, get_string, api_key)

  resp <- tryCatch(
    GET(query_url, timeout(120)),
    error = function(e) {
      cat(sprintf("    ERROR fetching %d: %s\n", year, e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || status_code(resp) != 200) {
    cat(sprintf("    WARNING: API returned status %s for %d\n",
                ifelse(is.null(resp), "NULL", status_code(resp)), year))
    return(NULL)
  }

  raw <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)

  ## Convert to data frame (first row is header)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- parsed[1, ]

  ## Add year
  df$year <- year

  ## Convert numeric columns
  num_cols <- setdiff(colnames(df), c("state"))
  for (col in num_cols) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }

  cat(sprintf("    Fetched %d rows for %d\n", nrow(df), year))
  return(df)
}

## Fetch years: 2015-2019 (pre), 2020-2021 (transition), 2022-2023 (post)
years <- c(2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023)
cps_list <- list()

for (yr in years) {
  result <- fetch_cps_fss(yr, census_key)
  if (!is.null(result)) {
    cps_list[[as.character(yr)]] <- result
  }
}

if (length(cps_list) == 0) {
  stop("FATAL: Could not fetch CPS Food Security Supplement data from Census API for any year.")
}

## Combine all years
cps_raw <- bind_rows(cps_list)
cat(sprintf("Total CPS FSS observations: %d across %d years\n", nrow(cps_raw), length(cps_list)))

## Standardize variable names
if ("GESTFIPS" %in% names(cps_raw)) {
  cps_raw$statefip <- cps_raw$GESTFIPS
} else if ("state" %in% names(cps_raw)) {
  cps_raw$statefip <- as.numeric(cps_raw$state)
}

## =========================================================================
## Part 2: ACS 2019 State SNAP Participation Rates (treatment intensity)
## =========================================================================
cat("\n=== Fetching ACS 2019 SNAP participation rates ===\n")

census_api_key(census_key, install = FALSE)

## B22003: Receipt of Food Stamps/SNAP in the Past 12 Months by Poverty Status
## B22003_001: Total population (for whom SNAP determined)
## B22003_002: Received SNAP
snap_acs <- get_acs(
  geography = "state",
  variables = c(total = "B22003_001", snap_hh = "B22003_002"),
  year = 2019,
  survey = "acs1"
)

snap_rates <- snap_acs %>%
  select(GEOID, NAME, variable, estimate) %>%
  pivot_wider(names_from = variable, values_from = estimate) %>%
  mutate(
    statefip = as.numeric(GEOID),
    snap_rate = snap_hh / total,
    state_name = NAME
  ) %>%
  select(statefip, state_name, snap_rate, snap_hh, total)

cat(sprintf("SNAP rates: min=%.3f, max=%.3f, mean=%.3f, sd=%.3f\n",
            min(snap_rates$snap_rate), max(snap_rates$snap_rate),
            mean(snap_rates$snap_rate), sd(snap_rates$snap_rate)))

## =========================================================================
## Part 3: State unemployment rates from BLS LAUS
## =========================================================================
cat("\n=== Fetching state unemployment rates ===\n")

## Use BLS LAUS data via direct download
## Series ID format: LASST{FIPS}0000000000003 (unemployment rate)
## Alternative: use FRED API

fred_key <- Sys.getenv("FRED_API_KEY")

if (nchar(fred_key) > 0) {
  ## Fetch via FRED — state unemployment rates
  state_fips <- snap_rates$statefip
  unemp_list <- list()

  for (fips in state_fips) {
    ## FRED series: {STATE}UR for unemployment rate
    state_abbr <- state.abb[match(snap_rates$state_name[snap_rates$statefip == fips],
                                   state.name)]
    if (is.na(state_abbr)) {
      if (fips == 11) state_abbr <- "DC"
      else next
    }

    series_id <- paste0(state_abbr, "UR")
    url <- sprintf("https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2015-01-01&observation_end=2023-12-31&frequency=a",
                   series_id, fred_key)

    resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) {
      obs <- content(resp, "parsed")$observations
      if (length(obs) > 0) {
        for (ob in obs) {
          unemp_list[[length(unemp_list) + 1]] <- data.frame(
            statefip = fips,
            year = as.numeric(substr(ob$date, 1, 4)),
            unemp_rate = as.numeric(ob$value),
            stringsAsFactors = FALSE
          )
        }
      }
    }
    Sys.sleep(0.1)  # Rate limiting
  }

  if (length(unemp_list) > 0) {
    unemp_rates <- bind_rows(unemp_list)
    cat(sprintf("Fetched unemployment rates for %d state-years\n", nrow(unemp_rates)))
  } else {
    cat("WARNING: Could not fetch unemployment rates from FRED\n")
    unemp_rates <- data.frame(statefip = integer(), year = integer(), unemp_rate = numeric())
  }
} else {
  cat("WARNING: FRED_API_KEY not set, skipping unemployment rates\n")
  unemp_rates <- data.frame(statefip = integer(), year = integer(), unemp_rate = numeric())
}

## =========================================================================
## Part 4: Emergency Allotment end dates by state
## =========================================================================
cat("\n=== Setting Emergency Allotment end dates ===\n")

## Emergency Allotments ended at different times across states
## Source: CBPP, USDA FNS
## Categorized by when they ended relative to TFP revision (Oct 2021)
## "early" = ended before Oct 2021; "late" = ended Oct 2021 or after
ea_dates <- tribble(
  ~state_abbr, ~ea_end_month, ~ea_end_year, ~ea_end_category,
  "AL", 6, 2021, "early",
  "AK", 3, 2021, "early",
  "AR", 6, 2021, "early",
  "FL", 6, 2021, "early",
  "GA", 6, 2021, "early",
  "ID", 7, 2021, "early",
  "IN", 6, 2021, "early",
  "IA", 6, 2021, "early",
  "MS", 6, 2021, "early",
  "MO", 7, 2021, "early",
  "MT", 7, 2021, "early",
  "NE", 7, 2021, "early",
  "ND", 9, 2021, "early",
  "SD", 7, 2021, "early",
  "TN", 7, 2021, "early",
  "TX", 6, 2021, "early",
  "UT", 6, 2021, "early",
  "WY", 6, 2021, "early",
  ## Late enders (continued EA past Oct 2021, ended 2022-2023)
  "AZ", 5, 2022, "late",
  "CA", 3, 2023, "late",
  "CO", 3, 2023, "late",
  "CT", 3, 2023, "late",
  "DE", 3, 2023, "late",
  "DC", 3, 2023, "late",
  "HI", 3, 2023, "late",
  "IL", 3, 2023, "late",
  "KS", 2, 2022, "late",
  "KY", 3, 2023, "late",
  "LA", 3, 2023, "late",
  "ME", 3, 2023, "late",
  "MD", 3, 2023, "late",
  "MA", 3, 2023, "late",
  "MI", 3, 2023, "late",
  "MN", 3, 2023, "late",
  "NV", 3, 2023, "late",
  "NH", 5, 2022, "late",
  "NJ", 3, 2023, "late",
  "NM", 3, 2023, "late",
  "NY", 3, 2023, "late",
  "NC", 3, 2023, "late",
  "OH", 3, 2023, "late",
  "OK", 4, 2022, "late",
  "OR", 3, 2023, "late",
  "PA", 3, 2023, "late",
  "RI", 3, 2023, "late",
  "SC", 3, 2023, "late",
  "VT", 3, 2023, "late",
  "VA", 3, 2023, "late",
  "WA", 3, 2023, "late",
  "WV", 6, 2022, "late",
  "WI", 3, 2023, "late"
)

## Map state abbreviations to FIPS
state_lookup <- data.frame(
  state_abbr = c(state.abb, "DC"),
  state_name = c(state.name, "District of Columbia"),
  statefip = c(fips_codes %>%
                 filter(state %in% c(state.abb, "DC")) %>%
                 distinct(state, state_code) %>%
                 arrange(match(state, c(state.abb, "DC"))) %>%
                 pull(state_code) %>%
                 as.numeric()),
  stringsAsFactors = FALSE
)

## Simpler FIPS lookup
state_fips_map <- c(
  AL=1, AK=2, AZ=4, AR=5, CA=6, CO=8, CT=9, DE=10, DC=11, FL=12,
  GA=13, HI=15, ID=16, IL=17, IN=18, IA=19, KS=20, KY=21, LA=22,
  ME=23, MD=24, MA=25, MI=26, MN=27, MS=28, MO=29, MT=30, NE=31,
  NV=32, NH=33, NJ=34, NM=35, NY=36, NC=37, ND=38, OH=39, OK=40,
  OR=41, PA=42, RI=44, SC=45, SD=46, TN=47, TX=48, UT=49, VT=50,
  VA=51, WA=53, WV=54, WI=55, WY=56
)

ea_dates$statefip <- state_fips_map[ea_dates$state_abbr]

## Create EA active indicator for each state-year (December of each year)
ea_status <- expand.grid(
  statefip = unique(c(ea_dates$statefip, snap_rates$statefip)),
  year = 2015:2023
) %>%
  left_join(ea_dates %>% select(statefip, ea_end_year, ea_end_month, ea_end_category),
            by = "statefip") %>%
  mutate(
    ## EA started March 2020 for all states
    ea_active = case_when(
      year < 2020 ~ 0,  # Pre-COVID: no EA
      year == 2020 ~ 1, # 2020: all states had EA
      year >= ea_end_year & (year > ea_end_year | 12 >= ea_end_month) ~ 0, # After EA ended in that state
      year == ea_end_year & 12 < ea_end_month ~ 1, # December before EA end month
      TRUE ~ 1  # Default: EA still active
    ),
    ## Fix: if EA ended before December of that year, ea_active = 0
    ea_active = case_when(
      year < 2020 ~ 0,
      is.na(ea_end_year) ~ 0,  # States without EA data
      year > ea_end_year ~ 0,
      year == ea_end_year & ea_end_month <= 12 ~ 0,  # Ended before or during December
      TRUE ~ 1
    ),
    early_ea_end = ifelse(!is.na(ea_end_category) & ea_end_category == "early", 1, 0)
  ) %>%
  select(statefip, year, ea_active, early_ea_end) %>%
  distinct()

cat(sprintf("EA status panel: %d state-years\n", nrow(ea_status)))
cat(sprintf("Early EA end states: %d\n", sum(ea_dates$ea_end_category == "early")))

## =========================================================================
## Save all data
## =========================================================================
cat("\n=== Saving data ===\n")

saveRDS(cps_raw, file.path(data_dir, "cps_fss_raw.rds"))
saveRDS(snap_rates, file.path(data_dir, "snap_rates_2019.rds"))
saveRDS(unemp_rates, file.path(data_dir, "unemp_rates.rds"))
saveRDS(ea_status, file.path(data_dir, "ea_status.rds"))

cat("Data saved successfully.\n")
cat(sprintf("CPS FSS: %d observations, %d years\n", nrow(cps_raw), length(unique(cps_raw$year))))
cat(sprintf("SNAP rates: %d states\n", nrow(snap_rates)))
cat(sprintf("Unemployment: %d state-years\n", nrow(unemp_rates)))
