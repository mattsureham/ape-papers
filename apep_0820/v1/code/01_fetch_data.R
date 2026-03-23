## 01_fetch_data.R — Fetch all data from real sources
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

source("00_packages.R")

DATA_DIR <- normalizePath("../data", mustWork = FALSE)
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
cat("Data directory:", DATA_DIR, "\n")

# ============================================================
# 1. EPA Facility Locations via ECHO (two-step API)
# ============================================================
if (!file.exists(file.path(DATA_DIR, "echo_facilities.rds"))) {
  cat("=== Fetching EPA facility locations via ECHO ===\n")

  states <- c("AL","AZ","AR","CA","CO","CT","DE","FL","GA","IL","IN","IA",
              "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE",
              "NJ","NM","NY","NC","OH","OK","OR","PA","SC","TN","TX",
              "UT","VA","WA","WV","WI")

  fac_list <- list()
  for (st in states) {
    qid_url <- paste0(
      "https://echodata.epa.gov/echo/air_rest_services.get_facilities?",
      "output=JSON&p_st=", st,
      "&p_air_univ=Major&p_act=Y&responseset=1000"
    )
    resp <- httr::GET(qid_url, httr::timeout(60))
    if (httr::status_code(resp) != 200) next

    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(raw, flatten = TRUE)
    qid <- parsed$Results$QueryID
    n_rows <- as.integer(parsed$Results$QueryRows)
    if (is.null(n_rows) || n_rows == 0) next

    data_url <- paste0(
      "https://echodata.epa.gov/echo/air_rest_services.get_qid?",
      "output=JSON&qid=", qid, "&responseset=", min(n_rows, 1000)
    )
    resp2 <- httr::GET(data_url, httr::timeout(60))
    if (httr::status_code(resp2) != 200) next

    raw2 <- httr::content(resp2, as = "text", encoding = "UTF-8")
    parsed2 <- jsonlite::fromJSON(raw2, flatten = TRUE)
    facs <- parsed2$Results$Facilities
    if (!is.null(facs) && nrow(facs) > 0) {
      fac_list[[st]] <- facs
      cat("  ", st, ":", nrow(facs), "\n")
    }
    Sys.sleep(0.3)
  }

  facilities_raw <- bind_rows(fac_list)
  facilities <- facilities_raw %>%
    mutate(
      facilityId = coalesce(SourceID, AIRIDs, RegistryID),
      facilityName = AIRName,
      stateCode = AIRState,
      latitude = as.numeric(FacLat),
      longitude = as.numeric(FacLong),
      fips = FacFIPSCode
    ) %>%
    filter(!is.na(latitude), !is.na(longitude),
           latitude > 24, latitude < 50,
           longitude < -65, longitude > -125) %>%
    select(facilityId, facilityName, stateCode, latitude, longitude, fips) %>%
    distinct(facilityId, .keep_all = TRUE)

  cat("Major facilities:", nrow(facilities), "\n")
  saveRDS(facilities, file.path(DATA_DIR, "echo_facilities.rds"))
} else {
  cat("=== ECHO facilities already cached ===\n")
  facilities <- readRDS(file.path(DATA_DIR, "echo_facilities.rds"))
  cat("  Loaded", nrow(facilities), "facilities\n")
}

# ============================================================
# 2. EPA AQS — Monitor data (bulk download, selected years)
# ============================================================
if (!file.exists(file.path(DATA_DIR, "aqs_monitors.rds"))) {
  cat("\n=== Fetching EPA AQS monitor data ===\n")

  aqs_list <- list()
  for (yr in c(2010, 2013, 2015, 2017)) {
    ad_file <- file.path(DATA_DIR, paste0("aqs_", yr, ".zip"))
    ad_url <- paste0("https://aqs.epa.gov/aqsweb/airdata/annual_conc_by_monitor_", yr, ".zip")

    # Use system curl for reliability
    exit_code <- system2("curl", args = c("-sL", "-o", ad_file,
                                           "--connect-timeout", "30",
                                           "--max-time", "300",
                                           ad_url), stdout = FALSE, stderr = FALSE)

    if (exit_code == 0 && file.exists(ad_file) && file.info(ad_file)$size > 10000) {
      unzip(ad_file, exdir = DATA_DIR, overwrite = TRUE)
      csvs <- list.files(DATA_DIR, pattern = paste0("annual_conc.*", yr, "\\.csv$"), full.names = TRUE)
      if (length(csvs) > 0) {
        df <- read_csv(csvs[1], show_col_types = FALSE)
        aqs_list[[as.character(yr)]] <- df
        cat("  AQS", yr, ":", nrow(df), "records\n")
      }
    } else {
      cat("  AQS", yr, "failed (exit code", exit_code, ")\n")
    }
  }

  if (length(aqs_list) > 0) {
    aqs_data <- bind_rows(aqs_list)
    cat("Total AQS records:", nrow(aqs_data), "\n")
    saveRDS(aqs_data, file.path(DATA_DIR, "aqs_monitors.rds"))
  } else {
    cat("WARNING: No AQS data downloaded. Proceeding without monitor data.\n")
  }
} else {
  cat("=== AQS data already cached ===\n")
}

# ============================================================
# 3. ASOS Weather Stations + Wind Data
# ============================================================
if (!file.exists(file.path(DATA_DIR, "asos_wind_raw.rds"))) {
  cat("\n=== Fetching ASOS station list and wind data ===\n")

  # Fetch ASOS stations state by state using httr (not curl)
  state_codes <- c("AL","AZ","AR","CA","CO","CT","DE","FL","GA","IL","IN","IA",
                   "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE",
                   "NJ","NM","NY","NC","OH","OK","OR","PA","SC","TN","TX",
                   "UT","VA","WA","WV","WI","ID","NH","ND","RI","SD","VT","WY","NV")

  stn_list <- list()
  for (sc in state_codes) {
    stn_url <- paste0("https://mesonet.agron.iastate.edu/sites/networks.php?network=",
                      sc, "_ASOS&format=csv&nohtml=on")
    resp <- tryCatch(httr::GET(stn_url, httr::timeout(15)), error = function(e) NULL)
    if (!is.null(resp) && httr::status_code(resp) == 200) {
      raw <- httr::content(resp, as = "text", encoding = "UTF-8")
      if (grepl("^stid,", raw)) {
        df <- tryCatch(read_csv(I(raw), show_col_types = FALSE), error = function(e) NULL)
        if (!is.null(df) && nrow(df) > 0) {
          stn_list[[sc]] <- df
        }
      }
    }
  }
  cat("  Fetched stations from", length(stn_list), "states\n")

  stations <- bind_rows(stn_list)
  stn_cols <- names(stations)
  cat("  Station columns:", paste(stn_cols, collapse = ", "), "\n")

  # Robust rename
  if ("stid" %in% stn_cols) stations <- stations %>% rename(id = stid)
  if ("lat" %in% stn_cols) stations <- stations %>% rename(latitude = lat, longitude = lon)

  stations <- stations %>%
    mutate(latitude = as.numeric(latitude), longitude = as.numeric(longitude)) %>%
    filter(!is.na(latitude), !is.na(longitude)) %>%
    distinct(id, .keep_all = TRUE)

  cat("  ASOS stations:", nrow(stations), "\n")
  saveRDS(stations, file.path(DATA_DIR, "asos_stations.rds"))

  # Match facilities to nearest station
  cat("  Matching facilities to stations...\n")
  matches_list <- lapply(1:nrow(facilities), function(i) {
    dists <- geosphere::distHaversine(
      c(facilities$longitude[i], facilities$latitude[i]),
      cbind(stations$longitude, stations$latitude)
    )
    data.frame(facilityId = facilities$facilityId[i],
               nearest_station = stations$id[which.min(dists)],
               station_dist_km = min(dists) / 1000,
               stringsAsFactors = FALSE)
  })
  fac_station <- bind_rows(matches_list)
  cat("  Median distance:", round(median(fac_station$station_dist_km), 1), "km\n")
  saveRDS(fac_station, file.path(DATA_DIR, "facility_station_match.rds"))

  # Fetch wind data (4 years for panel variation)
  needed_stations <- unique(fac_station$nearest_station)
  station_sample <- head(needed_stations, 150)
  cat("  Fetching wind for", length(station_sample), "stations, 4 years\n")

  wind_data_list <- list()
  for (yr in c(2010, 2013, 2015, 2017)) {
    cat("  Year", yr, "...")
    count <- 0
    for (stn in station_sample) {
      wind_url <- paste0(
        "https://mesonet.agron.iastate.edu/cgi-bin/request/asos.py?",
        "station=", stn,
        "&data=drct&data=sknt",
        "&year1=", yr, "&month1=1&day1=1",
        "&year2=", yr, "&month2=12&day2=31",
        "&tz=UTC&format=comma&latlon=no&elev=no&missing=empty&trace=empty",
        "&direct=no&report_type=3"
      )

      resp <- tryCatch(
        httr::GET(wind_url, httr::timeout(15)),
        error = function(e) NULL
      )
      if (!is.null(resp) && httr::status_code(resp) == 200) {
        raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
        lines <- strsplit(raw_text, "\n")[[1]]
        data_lines <- lines[!grepl("^#", lines) & nchar(trimws(lines)) > 5]
        if (length(data_lines) > 1) {
          wind_df <- tryCatch(
            read_csv(I(paste(data_lines, collapse = "\n")), show_col_types = FALSE),
            error = function(e) NULL
          )
          if (!is.null(wind_df) && nrow(wind_df) > 100) {
            wind_df$station_id <- stn
            wind_df$wind_year <- yr
            wind_data_list[[paste0(stn, "_", yr)]] <- wind_df
            count <- count + 1
          }
        }
      }
    }
    cat(" got", count, "stations\n")
    Sys.sleep(1)
  }

  cat("  Total station-years:", length(wind_data_list), "\n")
  if (length(wind_data_list) == 0) stop("No wind data fetched")

  wind_data <- bind_rows(wind_data_list)
  saveRDS(wind_data, file.path(DATA_DIR, "asos_wind_raw.rds"))
} else {
  cat("=== ASOS wind data already cached ===\n")
}

# ============================================================
# 4. Stanford SEDA — School-level test scores
# ============================================================
if (!file.exists(file.path(DATA_DIR, "edfacts_raw.rds"))) {
  cat("\n=== Fetching EdFacts school-level math achievement data ===\n")

  # EdFacts school-level math proficiency data from ED.gov
  edfacts_list <- list()
  for (yr in c("2012-13", "2013-14", "2014-15", "2015-16", "2016-17", "2017-18")) {
    yr_short <- sub("20", "", sub("-", "", yr))
    ef_url <- paste0("https://www2.ed.gov/about/inits/ed/edfacts/data-files/math-achievement-sch-sy",
                     yr, ".csv")
    ef_file <- file.path(DATA_DIR, paste0("edfacts_math_", yr_short, ".csv"))
    cat("  Fetching", yr, "...\n")

    exit <- system2("curl", args = c("-sL", "-o", ef_file, "--max-time", "300", ef_url),
                    stdout = FALSE, stderr = FALSE)

    if (exit == 0 && file.exists(ef_file) && file.info(ef_file)$size > 10000) {
      df <- read_csv(ef_file, show_col_types = FALSE, guess_max = 5000)
      df$school_year <- yr
      edfacts_list[[yr]] <- df
      cat("    Records:", nrow(df), "\n")
    } else {
      cat("    Failed\n")
    }
  }

  if (length(edfacts_list) > 0) {
    edfacts <- bind_rows(edfacts_list)
    cat("Total EdFacts records:", nrow(edfacts), "\n")
    cat("Columns:", paste(head(names(edfacts), 20), collapse = ", "), "\n")
    saveRDS(edfacts, file.path(DATA_DIR, "edfacts_raw.rds"))
  } else {
    stop("EdFacts data fetch FAILED")
  }
} else {
  cat("=== EdFacts data already cached ===\n")
}

# ============================================================
# 5. NCES EDGE — School geocodes
# ============================================================
if (!file.exists(file.path(DATA_DIR, "nces_geocodes.rds"))) {
  cat("\n=== Fetching NCES school geocodes ===\n")

  # Use ZIP format (CSV endpoints are 404)
  nces_zip_urls <- c(
    "https://nces.ed.gov/programs/edge/data/EDGE_GEOCODE_PUBLICSCH_2122.zip",
    "https://nces.ed.gov/programs/edge/data/EDGE_GEOCODE_PUBLICSCH_2223.zip"
  )

  geocodes <- NULL
  for (url in nces_zip_urls) {
    nces_zip <- file.path(DATA_DIR, "nces_geocode.zip")
    cat("  Trying:", basename(url), "...\n")
    exit <- system2("curl", args = c("-sL", "-o", nces_zip, "--max-time", "300", url),
                    stdout = FALSE, stderr = FALSE)
    if (exit == 0 && file.exists(nces_zip) && file.info(nces_zip)$size > 10000) {
      unzip(nces_zip, exdir = DATA_DIR, overwrite = TRUE)
      geo_files <- list.files(DATA_DIR, pattern = "EDGE_GEOCODE.*\\.TXT$",
                              full.names = TRUE, recursive = TRUE)
      if (length(geo_files) > 0) {
        # TXT file has no header — assign column names based on EDGE documentation
        geocodes <- read_delim(geo_files[1], delim = "|", col_names = FALSE,
                               show_col_types = FALSE, guess_max = 5000)
        # Key columns: X1=NCESSCH, X13=LAT, X14=LON
        names(geocodes)[1] <- "NCESSCH"
        names(geocodes)[13] <- "LAT"
        names(geocodes)[14] <- "LON"
        cat("  NCES geocode records:", nrow(geocodes), "\n")
        cat("  Columns:", paste(head(names(geocodes), 15), collapse = ", "), "\n")
        break
      }
    }
  }

  if (is.null(geocodes)) {
    stop("NCES geocode fetch FAILED — need school coordinates for spatial matching")
  }
  saveRDS(geocodes, file.path(DATA_DIR, "nces_geocodes.rds"))
} else {
  cat("=== NCES geocodes already cached ===\n")
}

# ============================================================
# Summary
# ============================================================
cat("\n=== Data Fetch Summary ===\n")
cat("  Facilities:", nrow(readRDS(file.path(DATA_DIR, "echo_facilities.rds"))), "\n")
if (file.exists(file.path(DATA_DIR, "aqs_monitors.rds")))
  cat("  AQS records:", nrow(readRDS(file.path(DATA_DIR, "aqs_monitors.rds"))), "\n")
cat("  EdFacts records:", nrow(readRDS(file.path(DATA_DIR, "edfacts_raw.rds"))), "\n")
cat("  Geocodes:", nrow(readRDS(file.path(DATA_DIR, "nces_geocodes.rds"))), "\n")
cat("\n01_fetch_data.R COMPLETE\n")
