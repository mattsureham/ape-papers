## 01_fetch_data.R — Fetch CBP and BDS data for apep_0898
## Grocery exit cascades: anchor store hypothesis

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. County Business Patterns (CBP) via Census API
## ============================================================
## Fetch establishment counts for key NAICS sectors at county level
## Years: 2005-2022; NAICS codes of interest:
##   445 = Food and beverage stores (grocery — our treatment sector)
##   44-45 = Retail trade (broad outcome)
##   722 = Food services and drinking places
##   446 = Health and personal care stores
##   812 = Personal and laundry services

fetch_cbp_year <- function(year, naics_code, key) {
  # CBP changed NAICS variable names over time
  # 2017+ uses NAICS2017, 2012-2016 uses NAICS2012, 2008-2011 uses NAICS2007
  if (year >= 2017) {
    naics_var <- "NAICS2017"
  } else if (year >= 2012) {
    naics_var <- "NAICS2012"
  } else if (year >= 2008) {
    naics_var <- "NAICS2007"
  } else {
    naics_var <- "NAICS2002"
  }

  # Build URL — get establishment count and employment
  base_url <- sprintf(
    "https://api.census.gov/data/%d/cbp?get=ESTAB,EMP&for=county:*&%s=%s&key=%s",
    year, naics_var, naics_code, key
  )

  resp <- tryCatch(
    {
      r <- GET(base_url, timeout(60))
      if (status_code(r) != 200) {
        warning(sprintf("CBP %d NAICS %s: HTTP %d", year, naics_code, status_code(r)))
        return(NULL)
      }
      content(r, "text", encoding = "UTF-8")
    },
    error = function(e) {
      warning(sprintf("CBP %d NAICS %s: %s", year, naics_code, e$message))
      return(NULL)
    }
  )

  if (is.null(resp)) return(NULL)

  parsed <- fromJSON(resp)
  if (is.null(parsed) || nrow(parsed) < 2) {
    warning(sprintf("CBP %d NAICS %s: empty response", year, naics_code))
    return(NULL)
  }

  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]

  df$year <- year
  df$naics <- naics_code
  df$fips <- paste0(df$state, df$county)
  df$estab <- as.integer(df$ESTAB)
  df$emp <- as.integer(df$EMP)

  df[, c("fips", "state", "county", "year", "naics", "estab", "emp")]
}

## Fetch all years and NAICS codes
naics_codes <- c("445", "4451", "722", "446", "812")
years <- 2005:2022

cat("Fetching County Business Patterns data...\n")
cbp_list <- list()
idx <- 1

for (yr in years) {
  for (nc in naics_codes) {
    cat(sprintf("  CBP %d NAICS %s... ", yr, nc))
    result <- fetch_cbp_year(yr, nc, census_key)
    if (!is.null(result) && nrow(result) > 0) {
      cbp_list[[idx]] <- result
      idx <- idx + 1
      cat(sprintf("OK (%d counties)\n", nrow(result)))
    } else {
      cat("FAILED\n")
    }
    Sys.sleep(0.3)  # Rate limiting
  }
}

cbp_raw <- bind_rows(cbp_list)
cat(sprintf("\nCBP total: %d rows across %d county-year-NAICS cells\n",
            nrow(cbp_raw), n_distinct(paste(cbp_raw$fips, cbp_raw$year, cbp_raw$naics))))

if (nrow(cbp_raw) == 0) stop("FATAL: No CBP data retrieved. Cannot proceed.")

## Validate: check we have reasonable coverage
counties_per_year <- cbp_raw %>%
  filter(naics == "445") %>%
  group_by(year) %>%
  summarise(n_counties = n_distinct(fips), .groups = "drop")
cat("\nGrocery (NAICS 445) county coverage by year:\n")
print(counties_per_year, n = 20)

if (min(counties_per_year$n_counties) < 1000) {
  warning("Fewer than 1000 counties in some years for NAICS 445")
}

saveRDS(cbp_raw, file.path(data_dir, "cbp_raw.rds"))
cat("Saved cbp_raw.rds\n")


## ============================================================
## 2. Business Dynamics Statistics (BDS) — County-level
## ============================================================
## Download county-level firm entry/exit data

bds_url <- "https://data.census.gov/api/access/table/download?name=BDSTIMESERIES.BDSFIRMS&vintage=2022&g=0100000US%240500000&d=Business+Dynamics+Statistics"

cat("\nFetching BDS county-level data...\n")
bds_file <- file.path(data_dir, "bds_county.csv")

# Try direct download of BDS county data
bds_direct_url <- "https://www2.census.gov/programs-surveys/bds/tables/time-series/bds2022_cty.csv"
tryCatch({
  download.file(bds_direct_url, bds_file, mode = "wb", quiet = FALSE)
  cat("BDS download complete.\n")
}, error = function(e) {
  warning(sprintf("BDS download failed: %s", e$message))
  # Try alternative URL
  alt_url <- "https://www2.census.gov/programs-surveys/bds/tables/time-series/bds2021_cty.csv"
  tryCatch({
    download.file(alt_url, bds_file, mode = "wb", quiet = FALSE)
    cat("BDS (2021 vintage) download complete.\n")
  }, error = function(e2) {
    warning(sprintf("BDS alternative download also failed: %s", e2$message))
  })
})

if (file.exists(bds_file) && file.size(bds_file) > 1000) {
  bds_raw <- fread(bds_file)
  cat(sprintf("BDS county data: %d rows, %d columns\n", nrow(bds_raw), ncol(bds_raw)))
  cat(sprintf("BDS columns: %s\n", paste(names(bds_raw), collapse = ", ")))
  saveRDS(bds_raw, file.path(data_dir, "bds_raw.rds"))
} else {
  cat("BDS county file not available. Will proceed with CBP data only.\n")
  bds_raw <- NULL
}


## ============================================================
## 3. Chain Bankruptcy Events (compiled from public records)
## ============================================================
## These are major US grocery chain bankruptcies with staggered timing

chain_bankruptcies <- tribble(
  ~chain, ~bankruptcy_year, ~states, ~approx_stores,

  "Winn-Dixie", 2005,
  "FL,GA,AL,LA,MS,SC,NC,VA,TN,IN,OH,TX", 920,

  "A&P (1st)", 2010,
  "NY,NJ,CT,PA,MD,DE,VA,DC", 395,

  "A&P (2nd)", 2015,
  "NY,NJ,CT,PA,MD,DE", 300,

  "Haggen", 2015,
  "WA,OR,CA,AZ,NV", 164,

  "Marsh", 2017,
  "IN", 44,

  "Tops Markets", 2018,
  "NY,PA,VT", 169,

  "Southeastern Grocers", 2018,
  "FL,GA,AL,LA,MS,SC,NC", 582,

  "Earth Fare", 2020,
  "NC,SC,VA,GA,FL,TN,OH,IN,MI,KY", 50,

  "Luckys Market", 2020,
  "FL,CO,IN,KY,MI,MO,MT,OH", 39,

  "Fairway Market", 2020,
  "NY,NJ,CT", 14
)

## Expand to state-level exposure
state_fips_lookup <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "43","46","47","48","49","50","51","53","54","55","56")
)

## Create state × bankruptcy event exposure matrix
bankruptcy_exposure <- chain_bankruptcies %>%
  mutate(state_list = str_split(states, ",")) %>%
  unnest(state_list) %>%
  mutate(state_list = trimws(state_list)) %>%
  left_join(state_fips_lookup, by = c("state_list" = "state_abbr")) %>%
  filter(!is.na(state_fips)) %>%
  select(chain, bankruptcy_year, state_fips, approx_stores)

cat(sprintf("\nBankruptcy exposure: %d state-chain combinations\n", nrow(bankruptcy_exposure)))
cat(sprintf("Unique states exposed: %d\n", n_distinct(bankruptcy_exposure$state_fips)))
cat(sprintf("Bankruptcy years: %s\n", paste(sort(unique(bankruptcy_exposure$bankruptcy_year)), collapse = ", ")))

saveRDS(chain_bankruptcies, file.path(data_dir, "chain_bankruptcies.rds"))
saveRDS(bankruptcy_exposure, file.path(data_dir, "bankruptcy_exposure.rds"))


## ============================================================
## 4. Summary validation
## ============================================================
cat("\n========== DATA FETCH SUMMARY ==========\n")
cat(sprintf("CBP: %d rows, %d counties, years %d-%d\n",
            nrow(cbp_raw), n_distinct(cbp_raw$fips),
            min(cbp_raw$year), max(cbp_raw$year)))
cat(sprintf("NAICS codes: %s\n", paste(unique(cbp_raw$naics), collapse = ", ")))
if (!is.null(bds_raw)) {
  cat(sprintf("BDS: %d rows\n", nrow(bds_raw)))
}
cat(sprintf("Bankruptcy events: %d chains, %d state exposures\n",
            nrow(chain_bankruptcies), nrow(bankruptcy_exposure)))
cat("=========================================\n")

cat("\nData fetch complete.\n")
