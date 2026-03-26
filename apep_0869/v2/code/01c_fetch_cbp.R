# 01c_fetch_cbp.R — Fetch County Business Patterns (establishment size classes)
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry
#
# CBP provides establishment counts by size class at county × NAICS level.
# This directly tests the scale-compression hypothesis: large establishments
# decline while small establishments increase in high-exposure industries
# in IL post-Rosenbach.

source("00_packages.R")

# ============================================================
# Census CBP API
# ============================================================

cat("=== FETCHING COUNTY BUSINESS PATTERNS ===\n")

# Target states and years
target_states <- c("17", "18", "55", "29", "19", "21")
years <- 2015:2023  # CBP is annual; latest available ~2 years lag

# NAICS sectors matching QCEW panel
naics_sectors <- c("51", "52", "54", "62")

# Census API key from environment
census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") {
  cat("WARNING: No CENSUS_API_KEY found. Trying without key (rate-limited).\n")
  key_param <- ""
} else {
  key_param <- paste0("&key=", census_key)
}

# CBP establishment size class variables
# ESTAB = total establishments
# Size class suffixes (n1_4, n5_9, n10_19, n20_49, n50_99, n100_249, n250_499, n500_999, n1000+)
size_vars <- c("ESTAB",
               "EMP",  # Total employment
               "EMPSZES",  # Employment size category code
               "ESTAB")  # Duplicated for safety

# Fetch CBP data via Census API
cbp_all <- list()

for (yr in years) {
  for (st in target_states) {
    # Try the CBP endpoint
    # CBP provides ESTAB and employment by size class at county level
    base_url <- sprintf(
      "https://api.census.gov/data/%d/cbp?get=NAICS2017,COUNTY,STATE,ESTAB,EMP,EMPSZES&for=county:*&in=state:%s%s",
      yr, st, key_param
    )

    cat(sprintf("Fetching CBP %d, state %s...\n", yr, st))

    resp <- tryCatch(
      {
        r <- httr::GET(base_url, httr::timeout(60))
        if (httr::status_code(r) != 200) {
          # Try without EMPSZES
          alt_url <- sprintf(
            "https://api.census.gov/data/%d/cbp?get=NAICS2017,COUNTY,STATE,ESTAB,EMP&for=county:*&in=state:%s%s",
            yr, st, key_param
          )
          r <- httr::GET(alt_url, httr::timeout(60))
        }
        if (httr::status_code(r) == 200) {
          json_text <- httr::content(r, as = "text", encoding = "UTF-8")
          mat <- jsonlite::fromJSON(json_text)
          dt <- as.data.table(mat[-1, , drop = FALSE])
          setnames(dt, mat[1, ])
          dt$year <- yr
          dt
        } else {
          NULL
        }
      },
      error = function(e) {
        cat(sprintf("  WARN: CBP %d, state %s — %s\n", yr, st, e$message))
        NULL
      }
    )

    if (!is.null(resp) && nrow(resp) > 0) {
      cbp_all[[paste(yr, st)]] <- resp
    }

    Sys.sleep(0.5)
  }
}

if (length(cbp_all) == 0) {
  stop("FATAL: No CBP data fetched. Check Census API key and endpoints.")
}

cbp <- rbindlist(cbp_all, fill = TRUE)
cat(sprintf("\nCBP raw: %d rows\n", nrow(cbp)))

# ============================================================
# Clean CBP data
# ============================================================

# Construct 5-digit FIPS
if ("STATE" %in% names(cbp) && "COUNTY" %in% names(cbp)) {
  cbp[, area_fips := paste0(STATE, COUNTY)]
} else if ("state" %in% names(cbp) && "county" %in% names(cbp)) {
  cbp[, area_fips := paste0(state, county)]
}

# Extract 2-digit NAICS
naics_col <- intersect(c("NAICS2017", "naics2017", "NAICS"), names(cbp))
if (length(naics_col) > 0) {
  cbp[, naics_2 := substr(get(naics_col[1]), 1, 2)]
  # Keep only our target sectors
  cbp_clean <- cbp[naics_2 %in% naics_sectors]
} else {
  cat("WARNING: Could not find NAICS column.\n")
  cbp_clean <- cbp
}

# Convert numeric columns
for (col in c("ESTAB", "EMP", "estab", "emp")) {
  if (col %in% names(cbp_clean)) {
    cbp_clean[[col]] <- as.numeric(cbp_clean[[col]])
  }
}

# ============================================================
# Fetch size-class detail (separate endpoint)
# ============================================================

cat("\n=== FETCHING CBP SIZE CLASS DETAIL ===\n")

# CBP size class data uses EMPSZES variable
# Codes: 001=All, 212=1-4, 220=5-9, 230=10-19, 241=20-49,
#        242=50-99, 251=100-249, 252=250-499, 253=500-999, 254=1000+

size_data <- list()

for (yr in years) {
  for (st in target_states) {
    url <- sprintf(
      "https://api.census.gov/data/%d/cbp?get=NAICS2017,COUNTY,ESTAB,EMPSZES&for=county:*&in=state:%s%s",
      yr, st, key_param
    )

    resp <- tryCatch(
      {
        r <- httr::GET(url, httr::timeout(60))
        if (httr::status_code(r) == 200) {
          json_text <- httr::content(r, as = "text", encoding = "UTF-8")
          mat <- jsonlite::fromJSON(json_text)
          dt <- as.data.table(mat[-1, , drop = FALSE])
          setnames(dt, mat[1, ])
          dt$year <- yr
          dt$state_fips <- st
          dt
        } else {
          NULL
        }
      },
      error = function(e) {
        cat(sprintf("  WARN: CBP size %d, state %s — %s\n", yr, st, e$message))
        NULL
      }
    )

    if (!is.null(resp) && nrow(resp) > 0) {
      size_data[[paste(yr, st)]] <- resp
    }

    Sys.sleep(0.5)
  }
}

if (length(size_data) > 0) {
  cbp_size <- rbindlist(size_data, fill = TRUE)
  cat(sprintf("CBP size class: %d rows\n", nrow(cbp_size)))

  # Clean and save
  naics_col <- intersect(c("NAICS2017", "naics2017"), names(cbp_size))
  if (length(naics_col) > 0) {
    cbp_size[, naics_2 := substr(get(naics_col[1]), 1, 2)]
    cbp_size <- cbp_size[naics_2 %in% naics_sectors]
  }
  cbp_size[, ESTAB := as.numeric(ESTAB)]

  fwrite(cbp_size, "../data/cbp_size_class.csv")
  cat("Saved: cbp_size_class.csv\n")
} else {
  cat("WARNING: No CBP size class data. Will use aggregate CBP only.\n")
}

# Save aggregate CBP
fwrite(cbp_clean, "../data/cbp_aggregate.csv")
cat(sprintf("\nSaved: cbp_aggregate.csv (%d rows)\n", nrow(cbp_clean)))

cat("\n=== CBP FETCH COMPLETE ===\n")
