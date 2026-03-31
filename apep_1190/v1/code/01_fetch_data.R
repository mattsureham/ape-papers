## 01_fetch_data.R — Fetch grocery store and birth outcome data
## apep_1190: SNAP Retailer Exits and Birth Outcomes

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

# ============================================================================
# 1. COUNTY BUSINESS PATTERNS — GROCERY STORES (NAICS 4451)
# ============================================================================
# Annual establishment counts for Grocery Stores at county level.
# Treatment = decline in grocery store establishments.

cat("=== Fetching County Business Patterns (NAICS 4451) ===\n")

cbp_list <- list()

for (yr in 2012:2022) {
  cat(sprintf("  CBP %d...\n", yr))

  if (yr >= 2017) {
    naics_param <- "NAICS2017"
  } else {
    naics_param <- "NAICS2012"
  }

  url <- sprintf(
    "https://api.census.gov/data/%d/cbp?get=GEO_ID,%s,ESTAB,EMP,PAYANN&for=county:*&in=state:*&%s=4451&key=%s",
    yr, naics_param, naics_param, census_key
  )

  resp <- tryCatch(httr::GET(url, httr::timeout(45)), error = function(e) {
    warning(sprintf("CBP %d failed: %s", yr, e$message))
    NULL
  })

  if (is.null(resp) || httr::status_code(resp) != 200) {
    warning(sprintf("CBP %d: HTTP %s, skipping", yr,
                    ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
    next
  }

  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df$year <- yr
  cbp_list[[as.character(yr)]] <- df
  cat(sprintf("    %d counties\n", nrow(df)))
  Sys.sleep(0.5)  # rate limit
}

stopifnot("No CBP data retrieved" = length(cbp_list) > 0)

cbp <- bind_rows(cbp_list)
cbp <- cbp %>%
  mutate(
    fips = paste0(state, county),
    estab = as.integer(ESTAB),
    emp = as.integer(EMP),
    payann = as.integer(PAYANN),
    year = as.integer(year)
  ) %>%
  select(fips, year, estab, emp, payann)

write_csv(cbp, file.path(data_dir, "cbp_grocery_4451.csv"))
cat(sprintf("CBP grocery panel: %d county-years, %d unique counties\n",
            nrow(cbp), n_distinct(cbp$fips)))

# ============================================================================
# 2. CDC NATALITY — COUNTY-LEVEL BIRTH OUTCOMES
# ============================================================================
# CDC publishes natality public-use microdata via NBER.
# Each file is ~200MB compressed. We download and aggregate to county-year.
# Only counties with ≥100K pop have identified FIPS codes.

cat("\n=== Fetching CDC Natality Microdata from NBER ===\n")

nat_years <- 2016:2022
nat_county_list <- list()

for (yr in nat_years) {
  cat(sprintf("  Natality %d: ", yr))

  zip_file <- file.path(data_dir, sprintf("natl%d.csv.zip", yr))
  csv_file <- file.path(data_dir, sprintf("natl%d.csv", yr))

  # Skip if already processed
  agg_file <- file.path(data_dir, sprintf("natl%d_county.csv", yr))
  if (file.exists(agg_file)) {
    cat("already aggregated, loading...\n")
    nat_county_list[[as.character(yr)]] <- read_csv(agg_file, show_col_types = FALSE)
    next
  }

  # Download from NBER
  if (!file.exists(zip_file) && !file.exists(csv_file)) {
    nber_url <- sprintf("https://data.nber.org/natality/%d/natl%d.csv.zip", yr, yr)
    cat(sprintf("downloading from %s...\n", nber_url))

    resp <- tryCatch({
      httr::GET(nber_url, httr::timeout(600),
                httr::write_disk(zip_file, overwrite = TRUE),
                httr::progress())
    }, error = function(e) {
      warning(sprintf("Download failed for %d: %s", yr, e$message))
      NULL
    })

    if (is.null(resp) || httr::status_code(resp) != 200) {
      warning(sprintf("Natality %d download failed, skipping", yr))
      if (file.exists(zip_file)) file.remove(zip_file)
      next
    }
    cat("  downloaded. ")
  }

  # Unzip if needed
  if (file.exists(zip_file) && !file.exists(csv_file)) {
    cat("unzipping... ")
    unzip(zip_file, exdir = data_dir)
    # Find the actual CSV name (may vary)
    csv_candidates <- list.files(data_dir, pattern = sprintf("natl%d", yr),
                                 ignore.case = TRUE, full.names = TRUE)
    csv_candidates <- csv_candidates[grepl("\\.csv$", csv_candidates, ignore.case = TRUE)]
    if (length(csv_candidates) > 0) {
      csv_file <- csv_candidates[1]
    }
  }

  if (!file.exists(csv_file)) {
    # Try alternate name patterns
    alt_names <- list.files(data_dir, pattern = sprintf("(?i)nat.*%d.*\\.csv", yr),
                            full.names = TRUE)
    if (length(alt_names) > 0) {
      csv_file <- alt_names[1]
    } else {
      warning(sprintf("No CSV found for %d", yr))
      next
    }
  }

  cat("reading & aggregating... ")

  # Read in chunks using data.table for speed
  # Key columns: dob_yy (year), ocntyfips (county FIPS), mrcnty (mother residence county),
  # dbwt (birth weight grams), gestrec3/gestrec10 (gestational age),
  # pay_rec (payment source: 1=Medicaid, 2=Private, 3=Self-pay, ...),
  # dmeth_rec (delivery method: 1=vaginal, 2=C-section)

  dt <- fread(csv_file, select = c("dob_yy", "mrcnty", "mrstfip",
                                     "dbwt", "gestrec3", "gestrec10",
                                     "pay_rec", "dmeth_rec"),
              showProgress = FALSE)

  # Standardize column names (lowercase)
  setnames(dt, tolower(names(dt)))

  # Construct 5-digit FIPS
  dt[, fips := sprintf("%02d%03d", as.integer(mrstfip), as.integer(mrcnty))]

  # Filter: identified counties only (mrcnty > 0)
  dt <- dt[as.integer(mrcnty) > 0 & !is.na(dbwt)]

  # Compute county-year aggregates
  county_yr <- dt[, .(
    births = .N,
    mean_bwt = mean(dbwt, na.rm = TRUE),
    lbw_count = sum(dbwt < 2500, na.rm = TRUE),
    preterm_count = sum(gestrec3 == 2, na.rm = TRUE),  # gestrec3: 1=37+ wks, 2=<37 wks
    csection_count = sum(dmeth_rec == 2, na.rm = TRUE),
    medicaid_births = sum(pay_rec == 1, na.rm = TRUE),
    private_births = sum(pay_rec == 2, na.rm = TRUE)
  ), by = .(fips, year = dob_yy)]

  county_yr[, `:=`(
    lbw_rate = lbw_count / births,
    preterm_rate = preterm_count / births,
    csection_rate = csection_count / births,
    medicaid_share = medicaid_births / births
  )]

  write_csv(county_yr, agg_file)
  nat_county_list[[as.character(yr)]] <- county_yr
  cat(sprintf("%d counties, %s births\n", n_distinct(county_yr$fips),
              format(sum(county_yr$births), big.mark = ",")))

  # Clean up large files to save disk space
  rm(dt)
  gc()
  if (file.exists(csv_file)) file.remove(csv_file)
  if (file.exists(zip_file)) file.remove(zip_file)
}

stopifnot("No natality data retrieved" = length(nat_county_list) > 0)

natality <- bind_rows(nat_county_list)
write_csv(natality, file.path(data_dir, "natality_county_panel.csv"))
cat(sprintf("\nNatality panel: %d county-years, %d unique counties, %s total births\n",
            nrow(natality), n_distinct(natality$fips),
            format(sum(natality$births), big.mark = ",")))

# ============================================================================
# 3. ACS COUNTY DEMOGRAPHICS (CONTROLS)
# ============================================================================
cat("\n=== Fetching ACS county demographics ===\n")

acs_years <- c(2015, 2017, 2019, 2021)
acs_list <- list()

for (yr in acs_years) {
  cat(sprintf("  ACS 5-year %d...\n", yr))

  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B19013_001E,B17001_002E,B01003_001E,NAME&for=county:*&in=state:*&key=%s",
    yr, census_key
  )

  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
    names(df) <- raw[1, ]
    df$acs_year <- yr
    acs_list[[as.character(yr)]] <- df
    cat(sprintf("    %d counties\n", nrow(df)))
  }
  Sys.sleep(0.3)
}

if (length(acs_list) > 0) {
  acs <- bind_rows(acs_list)
  acs <- acs %>%
    mutate(
      fips = paste0(state, county),
      med_income = as.numeric(B19013_001E),
      poverty_n = as.numeric(B17001_002E),
      total_pop = as.numeric(B01003_001E)
    ) %>%
    filter(!is.na(total_pop) & total_pop > 0) %>%
    mutate(poverty_rate = poverty_n / total_pop) %>%
    select(fips, acs_year, med_income, poverty_rate, total_pop)

  write_csv(acs, file.path(data_dir, "acs_county_demographics.csv"))
  cat(sprintf("ACS panel: %d county-years\n", nrow(acs)))
} else {
  stop("No ACS data retrieved")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Files in data directory:\n  %s\n",
            paste(list.files(data_dir), collapse = "\n  ")))
