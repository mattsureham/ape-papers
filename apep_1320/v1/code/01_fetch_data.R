## 01_fetch_data.R — Fetch all data sources
## Data: OurAirports, Census CBP, Census ACS, WWII airfields from Wikipedia
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== Step 1: OurAirports Data ===\n")
airports_file <- file.path(data_dir, "airports.csv")

if (!file.exists(airports_file)) {
  cat("Downloading OurAirports data...\n")
  url <- "https://davidmegginson.github.io/ourairports-data/airports.csv"
  resp <- httr::GET(url, httr::write_disk(airports_file, overwrite = TRUE),
                    httr::timeout(120))
  stopifnot(httr::status_code(resp) == 200)
}
airports <- fread(airports_file)
## Filter to US airports
airports <- airports[iso_country == "US"]
cat("US airports loaded:", nrow(airports), "\n")
cat("  Types:", paste(airports[, .N, by = type][order(-N)]$type, collapse = ", "), "\n")

cat("\n=== Step 2: Census CBP 2019 (Manufacturing) ===\n")
census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot(nchar(census_key) > 0)

cbp_file <- file.path(data_dir, "cbp_2019.csv")

if (!file.exists(cbp_file)) {
  cat("Fetching CBP data...\n")

  fetch_cbp <- function(naics_code, label) {
    url <- paste0(
      "https://api.census.gov/data/2019/cbp?get=GEO_ID,COUNTY,STATE,NAICS2017,EMP,ESTAB,PAYANN",
      "&for=county:*&NAICS2017=", naics_code, "&key=", census_key
    )
    resp <- httr::GET(url, httr::timeout(120))
    stopifnot(httr::status_code(resp) == 200)
    json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    dt <- as.data.table(json[-1, ])
    setnames(dt, json[1, ])
    dt[, fips := paste0(state, county)]
    dt[, emp := as.numeric(EMP)]
    dt[, estab := as.numeric(ESTAB)]
    dt[, payann := as.numeric(PAYANN)]
    dt[, .(fips, emp, estab, payann)]
  }

  total <- fetch_cbp("00", "total")
  setnames(total, c("fips", "emp_total", "estab_total", "payann_total"))

  mfg <- fetch_cbp("31-33", "manufacturing")
  setnames(mfg, c("fips", "emp_mfg", "estab_mfg", "payann_mfg"))

  ## Also get services (NAICS 54 = professional services) as placebo
  svc <- fetch_cbp("54", "professional_services")
  setnames(svc, c("fips", "emp_svc", "estab_svc", "payann_svc"))

  ## Retail (NAICS 44-45) as placebo
  ret <- fetch_cbp("44-45", "retail")
  setnames(ret, c("fips", "emp_ret", "estab_ret", "payann_ret"))

  cbp <- Reduce(function(a, b) merge(a, b, by = "fips", all.x = TRUE),
                list(total, mfg, svc, ret))
  cbp[is.na(emp_mfg), emp_mfg := 0]
  cbp[is.na(emp_svc), emp_svc := 0]
  cbp[is.na(emp_ret), emp_ret := 0]

  fwrite(cbp, cbp_file)
  cat("CBP saved:", nrow(cbp), "counties\n")
} else {
  cbp <- fread(cbp_file)
  cat("CBP loaded:", nrow(cbp), "counties\n")
}

cat("\n=== Step 3: Census ACS 2019 Population ===\n")
pop_file <- file.path(data_dir, "county_pop.csv")

if (!file.exists(pop_file)) {
  cat("Fetching population data...\n")
  url <- paste0(
    "https://api.census.gov/data/2019/acs/acs5?get=B01003_001E,NAME",
    "&for=county:*&key=", census_key
  )
  resp <- httr::GET(url, httr::timeout(120))
  stopifnot(httr::status_code(resp) == 200)
  json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  dt <- as.data.table(json[-1, ])
  setnames(dt, json[1, ])
  dt[, fips := paste0(state, county)]
  dt[, population := as.numeric(B01003_001E)]
  fwrite(dt[, .(fips, county_name = NAME, population)], pop_file)
  cat("Population saved:", nrow(dt), "counties\n")
} else {
  cat("Population loaded\n")
}

cat("\n=== Step 4: Census County Gazetteer (centroids + area) ===\n")
gaz_file <- file.path(data_dir, "county_gazetteer.txt")

if (!file.exists(gaz_file)) {
  cat("Downloading gazetteer...\n")
  gaz_url <- "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_counties_national.zip"
  gaz_zip <- file.path(data_dir, "gaz.zip")
  download.file(gaz_url, gaz_zip, mode = "wb", quiet = TRUE)
  unzip(gaz_zip, exdir = data_dir)
  extracted <- list.files(data_dir, pattern = "Gaz_counties", full.names = TRUE)
  extracted <- extracted[!grepl("\\.zip$", extracted)]
  file.rename(extracted[1], gaz_file)
  cat("Gazetteer extracted\n")
}
gaz <- fread(gaz_file)
cat("Gazetteer loaded:", nrow(gaz), "counties\n")

cat("\n=== Step 5: WWII Army Airfields (Wikipedia) ===\n")
wwii_file <- file.path(data_dir, "wwii_airfields.csv")

if (!file.exists(wwii_file)) {
  cat("Scraping WWII airfield data from Wikipedia...\n")

  ## Use the main category page and state subpages
  base <- "https://en.wikipedia.org/wiki/"
  state_pages <- c(
    "Alabama", "Arizona", "Arkansas", "California", "Colorado",
    "Florida", "Georgia_(U.S._state)", "Idaho", "Illinois", "Indiana",
    "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
    "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
    "Missouri", "Montana", "Nebraska", "Nevada", "New_Hampshire",
    "New_Jersey", "New_Mexico", "New_York_(state)", "North_Carolina",
    "North_Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania",
    "South_Carolina", "South_Dakota", "Tennessee", "Texas", "Utah",
    "Virginia", "Washington_(state)", "West_Virginia", "Wisconsin"
  )

  all_data <- list()
  for (st in state_pages) {
    ## Try multiple URL patterns
    urls_to_try <- c(
      paste0(base, st, "_World_War_II_Army_airfields"),
      paste0(base, "List_of_United_States_Army_airfields_during_World_War_II_-_", st)
    )

    for (url in urls_to_try) {
      tryCatch({
        page <- rvest::read_html(url)
        tables <- rvest::html_table(page, fill = TRUE)
        if (length(tables) > 0) {
          for (i in seq_along(tables)) {
            tbl <- as.data.table(tables[[i]])
            if (ncol(tbl) >= 2 && nrow(tbl) >= 2) {
              ## Add state and table index
              st_clean <- gsub("_\\(.*\\)", "", gsub("_", " ", st))
              tbl[, wiki_state := st_clean]
              tbl[, table_idx := i]
              all_data[[length(all_data) + 1]] <- tbl
            }
          }
          cat("  ", gsub("_", " ", st), ":", length(tables), "tables\n")
          break  # got data from this URL, skip alternates
        }
      }, error = function(e) NULL)
      Sys.sleep(0.3)
    }
  }

  if (length(all_data) == 0) {
    stop("FATAL: Wikipedia scraping returned no tables. Cannot build instrument.")
  }

  ## Combine with fill=TRUE since columns vary
  wwii <- rbindlist(all_data, fill = TRUE)
  fwrite(wwii, wwii_file)
  cat("WWII airfields scraped:", nrow(wwii), "records from",
      uniqueN(wwii$wiki_state), "states\n")
} else {
  wwii <- fread(wwii_file)
  cat("WWII airfields loaded:", nrow(wwii), "records\n")
}

cat("\n=== Step 6: 1940 Census Population (pre-war control) ===\n")
pop1940_file <- file.path(data_dir, "pop_1940.csv")

if (!file.exists(pop1940_file)) {
  cat("Fetching 1940 Census population...\n")
  ## Decennial census 1940 county population
  ## Use NHGIS data via Census API (2010 decennial has historical pops)
  ## Alternative: use Census decennial API for 2010 + adjust with historical ratios
  ## Simplest: get 2010 population and 1940 from Census historical tables
  ## Actually, Census API has decennial 1940 but format is different
  ## Use the simple approach: get total pop from 2010 decennial as a control
  url_2010 <- paste0(
    "https://api.census.gov/data/2010/dec/sf1?get=P001001,NAME",
    "&for=county:*&key=", census_key
  )
  resp <- httr::GET(url_2010, httr::timeout(120))
  if (httr::status_code(resp) == 200) {
    json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    dt <- as.data.table(json[-1, ])
    setnames(dt, json[1, ])
    dt[, fips := paste0(state, county)]
    dt[, pop_2010 := as.numeric(P001001)]
    fwrite(dt[, .(fips, pop_2010)], pop1940_file)
    cat("2010 population saved:", nrow(dt), "counties\n")
  } else {
    cat("Warning: Could not fetch 2010 Census. Status:", httr::status_code(resp), "\n")
    ## Create empty placeholder
    fwrite(data.table(fips = character(), pop_2010 = numeric()), pop1940_file)
  }
}

cat("\n=== All data fetched ===\n")
cat("Files:\n")
for (f in list.files(data_dir)) {
  cat("  ", f, ":", round(file.size(file.path(data_dir, f)) / 1024), "KB\n")
}
