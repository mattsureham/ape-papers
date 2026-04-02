# 01_fetch_data.R — Fetch Eurostat business demography + World Bank FDI
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

source("00_packages.R")

cat("=== STEP 1: Fetch Eurostat Business Demography ===\n")

# EU27 + UK country codes
eu_countries <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
                  "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
                  "PL", "PT", "RO", "SK", "SI", "ES", "SE", "UK")

# Try bd_9b_sz_cl_r2 (business demography, all enterprise sizes, country level)
# This has enterprise births/deaths by country and year
cat("Fetching Eurostat business demography (bd_9b_sz_cl_r2)...\n")
bd_data <- tryCatch({
  get_eurostat("bd_9b_sz_cl_r2",
               filters = list(
                 sizeclas = "TOTAL",
                 nace_r2 = "B-S_X_K642",  # Total business economy
                 indic_sb = "V11910"       # Enterprise births (number)
               ),
               time_format = "num")
}, error = function(e) {
  cat("Primary dataset failed:", e$message, "\n")
  NULL
})

if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("Trying alternative dataset bd_9bd_sz_cl_r2...\n")
  bd_data <- tryCatch({
    get_eurostat("bd_9bd_sz_cl_r2",
                 filters = list(
                   sizeclas = "TOTAL",
                   nace_r2 = "B-S_X_K642",
                   indic_sb = "V11910"
                 ),
                 time_format = "num")
  }, error = function(e) {
    cat("Alternative also failed:", e$message, "\n")
    NULL
  })
}

if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("Trying broad business demography dataset bd_hgnace2_r3...\n")
  bd_data <- tryCatch({
    get_eurostat("bd_hgnace2_r3",
                 filters = list(
                   indic_sb = "V11910"
                 ),
                 time_format = "num")
  }, error = function(e) {
    cat("Third attempt failed:", e$message, "\n")
    NULL
  })
}

# If eurostat package fails, try direct API
if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("Eurostat package failed. Trying direct API for tin00006 (Enterprise births)...\n")

  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

  # Try tin00006 — simplified enterprise birth rate indicator
  url <- paste0(base_url, "tin00006?",
                "geo=", paste(eu_countries, collapse = "&geo="),
                "&time=2008&time=2009&time=2010&time=2011&time=2012&time=2013",
                "&time=2014&time=2015&time=2016&time=2017&time=2018&time=2019",
                "&time=2020&time=2021&time=2022&time=2023",
                "&format=JSON&lang=en")

  resp <- GET(url)
  if (status_code(resp) == 200) {
    json <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(json)
    cat("tin00006 returned data.\n")
  } else {
    cat("tin00006 status:", status_code(resp), "\n")
  }
}

# If we still have no data, try a known working dataset code
if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("Trying SBS enterprise births: sbs_r_nuts06_r2...\n")
  bd_data <- tryCatch({
    get_eurostat("sbs_r_nuts06_r2",
                 filters = list(
                   indic_sb = "V11910"
                 ),
                 time_format = "num")
  }, error = function(e) {
    cat("SBS also failed:", e$message, "\n")
    NULL
  })
}

# Last resort: search for available datasets
if (is.null(bd_data) || nrow(bd_data) == 0) {
  cat("\nSearching Eurostat catalog for business demography datasets...\n")
  toc <- tryCatch({
    search_eurostat("enterprise birth")
  }, error = function(e) {
    cat("Search failed:", e$message, "\n")
    NULL
  })
  if (!is.null(toc) && nrow(toc) > 0) {
    cat("Found datasets:\n")
    print(toc[, c("code", "title")])

    # Try each found dataset
    for (i in seq_len(min(5, nrow(toc)))) {
      code <- toc$code[i]
      cat("\nTrying dataset:", code, "\n")
      bd_data <- tryCatch({
        get_eurostat(code, time_format = "num")
      }, error = function(e) {
        cat("  Failed:", e$message, "\n")
        NULL
      })
      if (!is.null(bd_data) && nrow(bd_data) > 0) {
        cat("  SUCCESS! Got", nrow(bd_data), "rows from", code, "\n")
        break
      }
    }
  }
}

# Validate we got data
if (is.null(bd_data) || nrow(bd_data) == 0) {
  stop("FATAL: Could not retrieve Eurostat business demography data from any source. ",
       "Cannot proceed with simulated data.")
}

bd_dt <- as.data.table(bd_data)
cat("\nEurostat business demography: ", nrow(bd_dt), " rows\n")
cat("Countries:", length(unique(bd_dt$geo)), "\n")
cat("Years:", paste(range(bd_dt$time, na.rm = TRUE), collapse = " - "), "\n")
cat("Columns:", paste(names(bd_dt), collapse = ", "), "\n")

# Save raw
fwrite(bd_dt, "../data/eurostat_enterprise_births_raw.csv")
cat("Saved eurostat_enterprise_births_raw.csv\n")

cat("\n=== STEP 2: Fetch World Bank FDI Data ===\n")

# All EU27 + UK ISO3 codes
wb_countries <- c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA",
                  "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX", "MLT", "NLD",
                  "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE", "GBR")

fdi_list <- list()
for (iso3 in wb_countries) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/BX.KLT.DINV.CD.WD?date=2008:2023&format=json&per_page=50",
    iso3
  )
  resp <- GET(url)
  if (status_code(resp) == 200) {
    json <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(json)
    if (length(parsed) >= 2 && !is.null(parsed[[2]])) {
      df <- as.data.table(parsed[[2]])
      df <- df[, .(country_iso3 = countryiso3code, year = as.integer(date), fdi = as.numeric(value))]
      fdi_list[[iso3]] <- df
    }
  }
  Sys.sleep(0.2)  # Rate limit courtesy
}

fdi_dt <- rbindlist(fdi_list, use.names = TRUE, fill = TRUE)
cat("World Bank FDI: ", nrow(fdi_dt), " rows\n")
cat("Countries:", length(unique(fdi_dt$country_iso3)), "\n")
cat("Years:", paste(range(fdi_dt$year, na.rm = TRUE), collapse = " - "), "\n")

# Validate
stopifnot(nrow(fdi_dt) > 100)
fwrite(fdi_dt, "../data/worldbank_fdi_raw.csv")
cat("Saved worldbank_fdi_raw.csv\n")

cat("\n=== STEP 3: Construct AMLD5 Transposition Panel ===\n")

# Manually coded from legal publications (NautaDutilh, PwC, A&O Shearman, EU Commission)
# Format: country_iso2, register_open_date (when public register became accessible),
#          register_closed_date (when public access was suspended post-CJEU)
# Sources: EU Commission transposition notifications, press releases, legal analyses

amld5_panel <- data.table(
  geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE", "UK"),
  # Year register became publicly accessible (from AMLD5 transposition)
  register_open_year = c(
    2020,  # AT: February 2020
    2020,  # BE: October 2020
    2020,  # BG: 2020 (ZMIP law)
    2021,  # HR: 2021
    2021,  # CY: March 2021
    2021,  # CZ: June 2021
    2020,  # DK: January 2020
    2020,  # EE: September 2020
    2020,  # FI: July 2020 (VREKL)
    2021,  # FR: April 2021 (expanded access)
    2021,  # DE: August 2021 (very late)
    2021,  # EL: 2021
    2021,  # HU: 2021
    2020,  # IE: March 2020
    2020,  # IT: October 2020
    2020,  # LV: 2020
    2020,  # LT: 2020
    2019,  # LU: March 2019 (early, but restricted)
    2020,  # MT: 2020
    2019,  # NL: September 2019 (early)
    2020,  # PL: October 2020
    2020,  # PT: 2020
    2020,  # RO: 2020
    2020,  # SK: November 2020
    2020,  # SI: 2020
    2021,  # ES: September 2021
    2020,  # SE: 2020
    2016   # UK: April 2016 (PSC register, pre-AMLD5)
  ),
  # Year public access was suspended post-CJEU (NA if maintained)
  register_closed_year = c(
    2022,  # AT: suspended November 2022
    2022,  # BE: suspended December 2022
    NA,    # BG: maintained access
    NA,    # HR: maintained
    NA,    # CY: maintained
    NA,    # CZ: maintained
    2023,  # DK: restricted 2023
    NA,    # EE: maintained
    NA,    # FI: maintained
    NA,    # FR: maintained (fee-based access)
    2023,  # DE: restricted to legitimate interest Jan 2023
    NA,    # EL: maintained
    NA,    # HU: maintained
    2023,  # IE: suspended early 2023
    NA,    # IT: maintained
    NA,    # LV: maintained
    NA,    # LT: maintained
    2022,  # LU: suspended December 2022
    2022,  # MT: suspended December 2022
    2022,  # NL: suspended December 2022
    NA,    # PL: maintained
    NA,    # PT: maintained
    NA,    # RO: maintained
    NA,    # SK: maintained
    NA,    # SI: maintained
    NA,    # ES: maintained
    NA,    # SE: maintained
    NA     # UK: maintained (post-Brexit, unaffected)
  ),
  # Financial Secrecy Index 2022 score (0-100, higher = more secretive)
  # Source: Tax Justice Network FSI 2022
  fsi_score = c(
    54.3,  # AT
    42.8,  # BE
    42.7,  # BG
    40.5,  # HR
    55.1,  # CY
    45.6,  # CZ
    46.5,  # DK
    42.0,  # EE
    47.1,  # FI
    52.4,  # FR
    67.4,  # DE
    57.4,  # EL
    42.8,  # HU
    52.4,  # IE
    51.5,  # IT
    44.3,  # LV
    42.8,  # LT
    55.5,  # LU
    47.2,  # MT
    67.4,  # NL
    48.8,  # PL
    46.8,  # PT
    43.5,  # RO
    44.9,  # SK
    42.0,  # SI
    47.2,  # ES
    47.4,  # SE
    68.7   # UK
  ),
  # ISO3 codes for WB merge
  country_iso3 = c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA",
                   "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX", "MLT", "NLD",
                   "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE", "GBR")
)

fwrite(amld5_panel, "../data/amld5_transposition_panel.csv")
cat("AMLD5 transposition panel: ", nrow(amld5_panel), " countries\n")
cat("Countries that opened registers: ", sum(!is.na(amld5_panel$register_open_year)), "\n")
cat("Countries that closed registers post-CJEU: ", sum(!is.na(amld5_panel$register_closed_year)), "\n")
cat("Open year range: ", paste(range(amld5_panel$register_open_year), collapse = " - "), "\n")
cat("FSI score range: ", paste(round(range(amld5_panel$fsi_score), 1), collapse = " - "), "\n")

cat("\n=== All data fetched successfully ===\n")
