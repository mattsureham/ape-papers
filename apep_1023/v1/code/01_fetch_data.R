## 01_fetch_data.R — Fetch ACS SNAP data and SNAP retailer database
## apep_1023: Redemption Deserts

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")
census_api_key(census_key, install = FALSE)

# State FIPS for all 50 states + DC (continental US)
state_fips <- c(sprintf("%02d", c(1,2,4:6,8:13,15:42,44:51,53:56)))

cat("=== Fetching ACS SNAP participation data (B22003) ===\n")

acs_years <- 2015:2022

acs_list <- list()
for (yr in acs_years) {
  cat(sprintf("  Fetching ACS %d (state by state)...\n", yr))

  yr_list <- list()
  for (st in state_fips) {
    tryCatch({
      d <- get_acs(
        geography = "tract",
        variables = c(
          total_hh = "B22003_001",
          snap_hh  = "B22003_002"
        ),
        year = yr,
        survey = "acs5",
        output = "wide",
        state = st
      )

      if (!is.null(d) && nrow(d) > 0) {
        yr_list[[st]] <- d
      }
    }, error = function(e) {
      cat(sprintf("    Skipping state %s year %d: %s\n", st, yr, e$message))
    })
  }

  d_yr <- bind_rows(yr_list) %>%
    mutate(year = yr) %>%
    select(GEOID, NAME, year,
           total_hh = total_hhE, snap_hh = snap_hhE,
           total_hh_moe = total_hhM, snap_hh_moe = snap_hhM)

  if (nrow(d_yr) == 0) stop(sprintf("FATAL: ACS %d returned no data across all states", yr))

  acs_list[[as.character(yr)]] <- d_yr
  cat(sprintf("    Got %d tracts for %d\n", nrow(d_yr), yr))
}

acs_panel <- bind_rows(acs_list)
cat(sprintf("ACS panel: %d rows, %d tracts, years %d-%d\n",
            nrow(acs_panel), n_distinct(acs_panel$GEOID),
            min(acs_panel$year), max(acs_panel$year)))

stopifnot(nrow(acs_panel) > 100000)

# Compute SNAP rate
acs_panel <- acs_panel %>%
  mutate(
    snap_rate = ifelse(total_hh > 0, snap_hh / total_hh, NA_real_)
  ) %>%
  filter(!is.na(snap_rate), total_hh >= 50)

cat(sprintf("After filtering: %d rows\n", nrow(acs_panel)))

saveRDS(acs_panel, "../data/acs_snap_panel.rds")
cat("Saved: data/acs_snap_panel.rds\n")

# === Fetch additional ACS variables for controls and mechanisms ===
cat("\n=== Fetching ACS controls (poverty, vehicle access) ===\n")

ctrl_vars <- c(
  pov_total     = "B17001_001",
  pov_below     = "B17001_002",
  veh_total     = "B08141_001",
  veh_none      = "B08141_002",
  pop_total     = "B01003_001",
  med_hh_inc    = "B19013_001",
  pct_black     = "B02001_003",
  pop_race_tot  = "B02001_001",
  pct_hisp      = "B03003_003",
  pop_hisp_tot  = "B03003_001"
)

ctrl_list <- list()
for (yr in acs_years) {
  cat(sprintf("  Fetching controls %d...\n", yr))

  yr_ctrl <- list()
  for (st in state_fips) {
    tryCatch({
      d <- get_acs(
        geography = "tract",
        variables = ctrl_vars,
        year = yr,
        survey = "acs5",
        output = "wide",
        state = st
      )

      if (!is.null(d) && nrow(d) > 0) {
        yr_ctrl[[st]] <- d
      }
    }, error = function(e) {
      # Skip silently for controls - non-fatal
    })
  }

  d_yr <- bind_rows(yr_ctrl) %>%
    mutate(year = yr) %>%
    select(GEOID, year,
           pov_total = pov_totalE, pov_below = pov_belowE,
           veh_total = veh_totalE, veh_none = veh_noneE,
           pop_total = pop_totalE, med_hh_inc = med_hh_incE,
           pop_black = pct_blackE, pop_race_tot = pop_race_totE,
           pop_hisp = pct_hispE, pop_hisp_tot = pop_hisp_totE)

  if (nrow(d_yr) == 0) stop(sprintf("FATAL: ACS controls %d returned no data", yr))

  ctrl_list[[as.character(yr)]] <- d_yr
  cat(sprintf("    Got %d tracts for controls %d\n", nrow(d_yr), yr))
}

ctrl_panel <- bind_rows(ctrl_list)
saveRDS(ctrl_panel, "../data/acs_controls_panel.rds")
cat(sprintf("Saved controls panel: %d rows\n", nrow(ctrl_panel)))

# === Fetch SNAP Retailer Historical Database ===
cat("\n=== Fetching SNAP Retailer Historical Database ===\n")

snap_zip <- "../data/snap_retailers.zip"
snap_file <- "../data/snap_retailers_raw.csv"

# USDA FNS official historical retailer data (ZIP containing CSV)
snap_url <- "https://fns-prod.azureedge.us/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
cat(sprintf("Downloading from: %s\n", snap_url))

downloaded <- FALSE
tryCatch({
  download.file(snap_url, snap_zip, mode = "wb", quiet = FALSE, timeout = 600)
  finfo <- file.info(snap_zip)
  if (!is.na(finfo$size) && finfo$size > 1000000) {
    # Unzip
    unzip(snap_zip, exdir = "../data/")
    # Find the CSV
    csv_files <- list.files("../data/", pattern = ".*SNAP.*\\.csv$|.*Historical.*\\.csv$|.*store.*\\.csv$",
                            full.names = TRUE, ignore.case = TRUE)
    if (length(csv_files) > 0) {
      file.rename(csv_files[1], snap_file)
      downloaded <- TRUE
      cat(sprintf("Downloaded and extracted: %.1f MB zip\n", finfo$size / 1e6))
    }
  }
}, error = function(e) {
  cat(sprintf("  Failed: %s\n", e$message))
})

if (!downloaded) {
  # Fallback URL
  snap_url2 <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
  cat(sprintf("Trying fallback: %s\n", snap_url2))
  tryCatch({
    download.file(snap_url2, snap_zip, mode = "wb", quiet = FALSE, timeout = 600)
    unzip(snap_zip, exdir = "../data/")
    csv_files <- list.files("../data/", pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
    csv_files <- csv_files[!grepl("snap_retailers_raw", csv_files)]
    if (length(csv_files) > 0) {
      file.rename(csv_files[1], snap_file)
      downloaded <- TRUE
    }
  }, error = function(e) {
    cat(sprintf("  Fallback failed: %s\n", e$message))
  })
}

if (!downloaded) {
  stop("FATAL: Cannot download SNAP retailer historical data from USDA")
}

snap_raw <- fread(snap_file)

if (is.null(snap_raw) || nrow(snap_raw) == 0) {
  stop("FATAL: SNAP retailer data is empty")
}

cat(sprintf("SNAP retailers: %d rows, %d columns\n", nrow(snap_raw), ncol(snap_raw)))
cat(sprintf("Columns: %s\n", paste(names(snap_raw), collapse = ", ")))

saveRDS(snap_raw, "../data/snap_retailers_raw.rds")
cat("Saved: data/snap_retailers_raw.rds\n")

cat("\n=== All data fetched successfully ===\n")
