## 01c_fetch_stations.R — Fetch WQP station metadata for county mapping
source("00_packages.R")

DATA_DIR <- "../data"

COAL_STATES <- c("AL", "KY", "OH", "PA", "TN", "VA", "WV")
COAL_STATE_FIPS <- c("01", "21", "39", "42", "47", "51", "54")

if (!file.exists(file.path(DATA_DIR, "wqp_stations.rds"))) {
  station_all <- list()

  for (i in seq_along(COAL_STATES)) {
    st <- COAL_STATES[i]
    st_fips <- COAL_STATE_FIPS[i]
    cat("Fetching stations for", st, "...\n")

    url <- paste0(
      "https://www.waterqualitydata.us/data/Station/search?",
      "statecode=US%3A", st_fips,
      "&mimeType=csv&zip=no&sorted=no"
    )

    tryCatch({
      resp <- GET(url, timeout(300))
      if (status_code(resp) == 200) {
        txt <- content(resp, as = "text", encoding = "UTF-8")
        if (nchar(txt) > 200) {
          df <- fread(text = txt, fill = TRUE, quote = "\"")
          df <- clean_names(df)
          station_all[[st]] <- df
          cat("  ", st, ":", nrow(df), "stations\n")
        }
      } else {
        cat("  ", st, ": HTTP", status_code(resp), "\n")
      }
    }, error = function(e) {
      cat("  ", st, ": ERROR -", conditionMessage(e), "\n")
    })
    Sys.sleep(2)
  }

  if (length(station_all) > 0) {
    stations <- rbindlist(station_all, fill = TRUE)
    cat("Total stations:", nrow(stations), "\n")
    cat("Station columns:", paste(head(names(stations), 20), collapse = ", "), "\n")
    saveRDS(stations, file.path(DATA_DIR, "wqp_stations.rds"))
  } else {
    stop("FATAL: No station data retrieved")
  }
} else {
  stations <- readRDS(file.path(DATA_DIR, "wqp_stations.rds"))
  cat("Loaded cached stations:", nrow(stations), "records\n")
}

# Show key columns for mapping
stn_cols <- names(stations)
cat("\nKey columns:\n")
cat("  county:", paste(stn_cols[grepl("county", stn_cols, ignore.case = TRUE)], collapse = ", "), "\n")
cat("  state:", paste(stn_cols[grepl("state", stn_cols, ignore.case = TRUE)], collapse = ", "), "\n")
cat("  location:", paste(stn_cols[grepl("monitor.*location.*id|location.*id", stn_cols, ignore.case = TRUE)], collapse = ", "), "\n")
