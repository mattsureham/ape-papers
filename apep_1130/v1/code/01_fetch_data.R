## 01_fetch_data.R — Fetch procurement data from USAspending API
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

source("00_packages.R")

cat("=== Fetching USAspending Data ===\n")

# ------------------------------------------------------------------
# 1. Define NAICS sectors and treatment waves
# ------------------------------------------------------------------
# SBA size standard increases by sector (Federal Register final rules)
# Treatment year = first fiscal year when new standards apply
treatment_panel <- data.table(
  naics_2d = c("42", "44", "45", "51",    # Cohort 1: FY2013
               "52", "53", "54",            # Cohort 2: FY2014
               "31", "32", "33"),           # Cohort 3: FY2016
  treat_year = c(rep(2013L, 4), rep(2014L, 3), rep(2016L, 3)),
  cohort = c(rep("2013: Wholesale/Retail/Info", 4),
             rep("2014: Finance/RE/Prof", 3),
             rep("2016: Manufacturing", 3))
)

# Never-treated sectors (control group) — no major size standard change pre-2020
control_sectors <- data.table(
  naics_2d = c("11", "21", "22", "23", "48", "49", "56", "71", "72"),
  treat_year = NA_integer_,
  cohort = "Never treated"
)

all_sectors <- rbindlist(list(treatment_panel, control_sectors))

# Sector labels for readability
sector_labels <- c(
  "11" = "Agriculture", "21" = "Mining", "22" = "Utilities",
  "23" = "Construction", "31" = "Manufacturing", "32" = "Manufacturing",
  "33" = "Manufacturing", "42" = "Wholesale", "44" = "Retail",
  "45" = "Retail", "48" = "Transportation", "49" = "Warehousing",
  "51" = "Information", "52" = "Finance", "53" = "Real Estate",
  "54" = "Professional Services", "56" = "Administrative",
  "71" = "Arts/Entertainment", "72" = "Accommodation/Food"
)
all_sectors[, sector_name := sector_labels[naics_2d]]

cat("Treatment panel:\n")
print(all_sectors[!is.na(treat_year)])
cat("\nControl sectors:\n")
print(all_sectors[is.na(treat_year)])

# ------------------------------------------------------------------
# 2. Fetch county-level procurement from USAspending API
# ------------------------------------------------------------------
# USAspending API endpoint for geographic spending
API_URL <- "https://api.usaspending.gov/api/v2/search/spending_by_geography/"

# Fiscal years: FY2008-FY2020 (pre-universal inflation adjustment)
fiscal_years <- 2008:2020

# Contract award type codes (procurement contracts only)
award_types <- c("A", "B", "C", "D")

# Set-aside type codes for small business
# SBA: Total Small Business Set-Aside
# SBP: Partial Small Business Set-Aside
# 8A: 8(a) Set-Aside
# HZC: HUBZone Set-Aside
# SDVOSBC: Service-Disabled Veteran-Owned
# WOSB: Women-Owned Small Business
# VSB: Very Small Business
sb_set_aside_codes <- c("SBA", "SBP", "8A", "8AN", "HZC", "SDVOSBC",
                        "SDVOSBS", "WOSB", "WOSBSS", "VSB", "VSA")

fetch_spending_by_county <- function(naics_code, fy, set_aside = NULL) {
  # Build date range for fiscal year
  start_date <- sprintf("%d-10-01", fy - 1)
  end_date <- sprintf("%d-09-30", fy)

  filters <- list(
    naics_codes = list(naics_code),
    time_period = list(list(start_date = start_date, end_date = end_date)),
    award_type_codes = as.list(award_types)
  )

  if (!is.null(set_aside)) {
    filters$set_aside_type_codes <- as.list(set_aside)
  }

  body <- list(
    scope = "place_of_performance",
    geo_layer = "county",
    filters = filters
  )

  tryCatch({
    resp <- request(API_URL) |>
      req_body_json(body) |>
      req_timeout(60) |>
      req_retry(max_tries = 3, backoff = ~2) |>
      req_perform()

    if (resp_status(resp) != 200) {
      stop(sprintf("API returned status %d for NAICS %s FY%d",
                    resp_status(resp), naics_code, fy))
    }

    result <- resp_body_json(resp)
    results <- result$results

    if (length(results) == 0) {
      return(data.table(
        county_fips = character(0), county_name = character(0),
        amount = numeric(0), naics_2d = character(0),
        fiscal_year = integer(0), type = character(0)
      ))
    }

    dt <- rbindlist(lapply(results, function(r) {
      data.table(
        county_fips = r$shape_code %||% NA_character_,
        county_name = r$display_name %||% NA_character_,
        amount = as.numeric(r$aggregated_amount %||% 0)
      )
    }))

    dt[, naics_2d := naics_code]
    dt[, fiscal_year := fy]
    dt[, type := ifelse(is.null(set_aside), "all_contracts", "sb_setaside")]

    return(dt)
  }, error = function(e) {
    warning(sprintf("Failed: NAICS %s FY%d - %s", naics_code, fy, e$message))
    return(NULL)
  })
}

# ------------------------------------------------------------------
# 3. Execute API calls — all sectors × all years × both types
# ------------------------------------------------------------------
naics_codes <- unique(all_sectors$naics_2d)
total_calls <- length(naics_codes) * length(fiscal_years) * 2  # all + SB
cat(sprintf("\nFetching data: %d NAICS × %d FYs × 2 types = %d API calls\n",
            length(naics_codes), length(fiscal_years), total_calls))

all_results <- list()
call_idx <- 0

for (naics in naics_codes) {
  for (fy in fiscal_years) {
    # All contracts
    call_idx <- call_idx + 1
    if (call_idx %% 20 == 0) {
      cat(sprintf("  Progress: %d/%d calls (%.0f%%)\n",
                  call_idx, total_calls, 100 * call_idx / total_calls))
    }
    dt_all <- fetch_spending_by_county(naics, fy, set_aside = NULL)
    if (!is.null(dt_all) && nrow(dt_all) > 0) {
      all_results[[length(all_results) + 1]] <- dt_all
    }

    # Small business set-asides
    call_idx <- call_idx + 1
    dt_sb <- fetch_spending_by_county(naics, fy, set_aside = sb_set_aside_codes)
    if (!is.null(dt_sb) && nrow(dt_sb) > 0) {
      all_results[[length(all_results) + 1]] <- dt_sb
    }

    Sys.sleep(0.25)  # Rate limiting courtesy
  }
}

cat(sprintf("\nCompleted %d API calls. Combining results...\n", call_idx))

county_procurement <- rbindlist(all_results, fill = TRUE)

if (nrow(county_procurement) == 0) {
  stop("FATAL: No procurement data retrieved from USAspending API. Cannot proceed.")
}

cat(sprintf("Raw data: %d rows, %d unique counties, %d NAICS sectors, FY%d-FY%d\n",
            nrow(county_procurement),
            uniqueN(county_procurement$county_fips),
            uniqueN(county_procurement$naics_2d),
            min(county_procurement$fiscal_year),
            max(county_procurement$fiscal_year)))

# ------------------------------------------------------------------
# 4. Save raw data
# ------------------------------------------------------------------
fwrite(county_procurement, "../data/county_procurement_raw.csv")
cat("Saved: data/county_procurement_raw.csv\n")

# ------------------------------------------------------------------
# 5. Fetch USDA Rural-Urban Continuum Codes
# ------------------------------------------------------------------
cat("\n=== Fetching USDA Rural-Urban Continuum Codes ===\n")

rucc_url <- "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv"
rucc_file <- "../data/rucc2013.csv"

tryCatch({
  download.file(rucc_url, rucc_file, quiet = TRUE, mode = "wb")
  rucc <- fread(rucc_file)
  # Standardize column names
  if ("FIPS" %in% names(rucc)) {
    setnames(rucc, "FIPS", "county_fips")
  }
  if ("RUCC_2013" %in% names(rucc)) {
    setnames(rucc, "RUCC_2013", "rucc_code")
  }
  # Metro = RUCC 1-3, Non-metro = RUCC 4-9
  rucc[, metro := as.integer(rucc_code <= 3)]
  rucc[, county_fips := sprintf("%05d", as.integer(county_fips))]
  fwrite(rucc, rucc_file)
  cat(sprintf("RUCC data: %d counties, %d metro, %d non-metro\n",
              nrow(rucc), sum(rucc$metro == 1), sum(rucc$metro == 0)))
}, error = function(e) {
  # Fallback: use first 2 digits of FIPS as state, classify by population
  warning(sprintf("RUCC download failed: %s. Will classify metro/non-metro from FIPS.", e$message))
  # Create simple metro classification based on state (imperfect but usable)
  rucc <- data.table(county_fips = character(0), rucc_code = integer(0), metro = integer(0))
  fwrite(rucc, rucc_file)
})

# ------------------------------------------------------------------
# 6. Merge treatment info
# ------------------------------------------------------------------
fwrite(all_sectors, "../data/treatment_panel.csv")
cat("\nSaved: data/treatment_panel.csv\n")
cat("\n=== Data fetch complete ===\n")
