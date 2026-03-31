## 01c_fetch_natality.R — Fetch county-level birth outcome data
## apep_1190: SNAP Retailer Exits and Birth Outcomes

source("00_packages.R")
data_dir <- "../data"

# ============================================================================
# 1. CDC ENVIRONMENTAL PUBLIC HEALTH TRACKING NETWORK API
# ============================================================================
# MeasureId 1 = Low Birth Weight (% of live births <2500g) at county level
# MeasureId 2 = Very Low Birth Weight
# Content Area 1 = Reproductive Health

cat("=== CDC Tracking Network: Low Birth Weight ===\n")
base_url <- "https://ephtracking.cdc.gov/apigateway/api/v1"

# Get data for LBW by county-year
# The API structure: /getCoreHolder/{measureId}/{stratificationLevel}/{geographicTypeId}/
# geographicTypeId: 2=county, 1=state
# temporal: year

lbw_list <- list()

for (yr in 2012:2022) {
  cat(sprintf("  LBW %d: ", yr))

  # Try the data endpoint
  url <- sprintf(
    "%s/getCoreHolder/%d/%d/%d/%d/json",
    base_url,
    1,    # measureId = Low Birth Weight
    1,    # stratificationLevel (all)
    2,    # geographicTypeId = county
    yr    # temporal
  )

  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    df <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
    if (!is.null(df) && length(df) > 0) {
      if (is.data.frame(df)) {
        cat(sprintf("%d records\n", nrow(df)))
        df$year <- yr
        lbw_list[[as.character(yr)]] <- df
      } else if (is.list(df) && "tableResult" %in% names(df)) {
        tbl <- df$tableResult
        if (is.data.frame(tbl) && nrow(tbl) > 0) {
          cat(sprintf("%d records\n", nrow(tbl)))
          tbl$year <- yr
          lbw_list[[as.character(yr)]] <- tbl
        } else {
          cat("empty result\n")
        }
      } else {
        cat(sprintf("unexpected format: %s\n", class(df)))
        # Save raw for inspection
        writeLines(substr(content, 1, 2000),
                   file.path(data_dir, sprintf("tracking_raw_%d.txt", yr)))
      }
    } else {
      cat("parse error\n")
    }
  } else {
    cat(sprintf("HTTP %s\n",
                ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
  }
  Sys.sleep(0.3)
}

if (length(lbw_list) > 0) {
  lbw <- bind_rows(lbw_list)
  write_csv(lbw, file.path(data_dir, "cdc_tracking_lbw.csv"))
  cat(sprintf("CDC Tracking LBW: %d records saved\n", nrow(lbw)))
}

# ============================================================================
# 2. NCHS VITAL STATISTICS — STATE-LEVEL
# ============================================================================
cat("\n=== NCHS Vital Statistics via data.cdc.gov ===\n")

# Try multiple natality datasets on data.cdc.gov
soda_datasets <- list(
  # NCHS Natality in the US
  natality_state = "https://data.cdc.gov/resource/3h5t-72mc.json?$limit=50000",
  # NCHS Birth rates by state
  birth_rates = "https://data.cdc.gov/resource/kyu4-3dgn.json?$limit=50000",
  # Infant mortality
  infant_mort = "https://data.cdc.gov/resource/yrjr-n7s8.json?$limit=50000"
)

for (name in names(soda_datasets)) {
  cat(sprintf("  %s: ", name))
  resp <- tryCatch(
    httr::GET(soda_datasets[[name]], httr::timeout(30)),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    df <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
      write_csv(df, file.path(data_dir, sprintf("nchs_%s.csv", name)))
      cat(sprintf("%d records. Cols: %s\n",
                  nrow(df), paste(head(names(df), 8), collapse = ", ")))
    } else {
      cat("empty/invalid\n")
    }
  } else {
    cat(sprintf("HTTP %s\n",
                ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
  }
}

# ============================================================================
# 3. CDC NATALITY VIA WONDER TEXT EXPORT
# ============================================================================
# If we can't get county-level data, use state-level natality
# from CDC vital statistics reports

cat("\n=== CDC WONDER Natality (state-level) ===\n")

# State-level natality summary from NCHS
# Provisional birth data by state
# https://data.cdc.gov/resource/dgt8-fkwz.json (provisional natality)
prov_url <- "https://data.cdc.gov/resource/dgt8-fkwz.json?$limit=50000"
resp <- tryCatch(httr::GET(prov_url, httr::timeout(30)), error = function(e) NULL)

if (!is.null(resp) && httr::status_code(resp) == 200) {
  content <- httr::content(resp, "text", encoding = "UTF-8")
  df <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
    write_csv(df, file.path(data_dir, "nchs_provisional_natality.csv"))
    cat(sprintf("Provisional natality: %d records\n", nrow(df)))
    cat(sprintf("Columns: %s\n", paste(names(df), collapse = ", ")))
  }
}

# ============================================================================
# 4. COUNTY-LEVEL BIRTH DATA FROM CDC PLACES
# ============================================================================
cat("\n=== CDC PLACES county health data ===\n")

# CDC PLACES provides county-level health outcomes
# Low birthweight is measure ID "LBW"
places_url <- paste0(
  "https://data.cdc.gov/resource/swc5-untb.json?",
  "$where=measureid='LBW'&$limit=50000"
)

resp <- tryCatch(httr::GET(places_url, httr::timeout(30)), error = function(e) NULL)
if (!is.null(resp) && httr::status_code(resp) == 200) {
  content <- httr::content(resp, "text", encoding = "UTF-8")
  df <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
    write_csv(df, file.path(data_dir, "cdc_places_lbw.csv"))
    cat(sprintf("CDC PLACES LBW: %d records\n", nrow(df)))
  } else {
    cat("No LBW data in PLACES\n")
    # Try without filter to see what measures are available
    places_url2 <- "https://data.cdc.gov/resource/swc5-untb.json?$limit=10"
    resp2 <- tryCatch(httr::GET(places_url2, httr::timeout(30)),
                       error = function(e) NULL)
    if (!is.null(resp2) && httr::status_code(resp2) == 200) {
      df2 <- tryCatch(
        jsonlite::fromJSON(httr::content(resp2, "text", encoding = "UTF-8")),
        error = function(e) NULL
      )
      if (!is.null(df2) && is.data.frame(df2)) {
        cat(sprintf("PLACES columns: %s\n", paste(names(df2), collapse = ", ")))
        if ("measureid" %in% names(df2)) {
          cat(sprintf("Sample measures: %s\n",
                      paste(unique(df2$measureid), collapse = ", ")))
        }
      }
    }
  }
}

# ============================================================================
# 5. USE QWI FOR STATE-LEVEL EMPLOYMENT AS PROXY FOR ANALYSIS UNIT
# ============================================================================
cat("\n=== Quarterly Workforce Indicators (NAICS 4451) ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
qwi_list <- list()

for (yr in 2012:2022) {
  for (qtr in 1:4) {
    qtr_str <- sprintf("%d-%d", yr, qtr)
    cat(sprintf("  QWI %s: ", qtr_str))

    url <- sprintf(
      "https://api.census.gov/data/timeseries/qwi/sa?get=Emp,EmpS,FrmJbGn,FrmJbLs,HirA&for=state:*&industry=4451&time=%d-Q%d&key=%s",
      yr, qtr, census_key
    )

    resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      raw <- tryCatch(
        jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")),
        error = function(e) NULL
      )
      if (!is.null(raw) && nrow(raw) > 1) {
        df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
        names(df) <- raw[1, ]
        df$year <- yr
        df$quarter <- qtr
        qwi_list[[qtr_str]] <- df
        cat(sprintf("%d states\n", nrow(df)))
      } else {
        cat("empty\n")
      }
    } else {
      cat(sprintf("HTTP %s\n",
                  ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
    }
    Sys.sleep(0.2)
  }
}

if (length(qwi_list) > 0) {
  qwi <- bind_rows(qwi_list)
  write_csv(qwi, file.path(data_dir, "qwi_grocery_state.csv"))
  cat(sprintf("QWI grocery panel: %d state-quarters\n", nrow(qwi)))
}

# ============================================================================
# 6. REPORT
# ============================================================================
cat("\n=== All data files ===\n")
files <- list.files(data_dir, full.names = TRUE)
for (f in files) {
  cat(sprintf("  %s (%s)\n", basename(f),
              format(file.size(f), big.mark = ",")))
}
