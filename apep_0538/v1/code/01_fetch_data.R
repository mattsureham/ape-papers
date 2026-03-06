## 01_fetch_data.R — Fetch DVF transactions, ZFE boundaries, and air quality data
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## =========================================================================
## A. ZFE boundaries (BNZFE — transport.data.gouv.fr)
## =========================================================================

cat("=== A. Downloading ZFE boundaries ===\n")

bnzfe_url <- "https://transport.data.gouv.fr/datasets/base-nationale-consolidee-des-zones-a-faibles-emissions"

## The BNZFE dataset page links to a consolidated GeoJSON.
## Try the direct resource URL for the national consolidated file.
bnzfe_geojson_url <- "https://transport.data.gouv.fr/resources/79647/download"

bnzfe_file <- file.path(data_dir, "bnzfe.geojson")

if (!file.exists(bnzfe_file)) {
  cat("  Downloading BNZFE from transport.data.gouv.fr...\n")
  res <- tryCatch({
    download.file(bnzfe_geojson_url, bnzfe_file, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)

  if (!res || !file.exists(bnzfe_file) || file.size(bnzfe_file) < 1000) {
    ## Fallback: try individual city GeoJSON files
    cat("  National file unavailable, fetching individual city boundaries...\n")
    city_urls <- list(
      paris     = "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/zone-a-faibles-emissions/exports/geojson",
      lyon      = "https://transport.data.gouv.fr/resources/81020/download",
      grenoble  = "https://transport.data.gouv.fr/resources/81150/download",
      toulouse  = "https://transport.data.gouv.fr/resources/79647/download",
      rouen     = "https://transport.data.gouv.fr/resources/81340/download"
    )
    zfe_parts <- list()
    for (city in names(city_urls)) {
      f <- file.path(data_dir, paste0("zfe_", city, ".geojson"))
      tryCatch({
        download.file(city_urls[[city]], f, mode = "wb", quiet = TRUE)
        sf_obj <- st_read(f, quiet = TRUE)
        sf_obj$city <- city
        zfe_parts[[city]] <- sf_obj
        cat("    ", city, ":", nrow(sf_obj), "features\n")
      }, error = function(e) {
        cat("    WARN:", city, "failed:", e$message, "\n")
      })
    }
    if (length(zfe_parts) == 0) {
      stop("FATAL: Could not download ANY ZFE boundary data. Cannot proceed.")
    }
  }
}

## Try to read the BNZFE file
zfe_boundaries <- tryCatch({
  sf_obj <- st_read(bnzfe_file, quiet = TRUE)
  cat("  BNZFE loaded:", nrow(sf_obj), "features\n")
  sf_obj
}, error = function(e) {
  cat("  BNZFE file unreadable, using individual city files...\n")
  if (exists("zfe_parts") && length(zfe_parts) > 0) {
    ## Bind individual city files
    ## Standardize columns
    do.call(rbind, lapply(zfe_parts, function(x) {
      x <- st_transform(x, 4326)
      x[, c("city", "geometry")]
    }))
  } else {
    stop("FATAL: No ZFE boundary data available.")
  }
})

cat("  ZFE boundary CRS:", st_crs(zfe_boundaries)$epsg, "\n")

## =========================================================================
## B. DVF geocoded transactions (2020-2024)
## =========================================================================

cat("\n=== B. Downloading DVF geocoded transactions (2020-2024) ===\n")

## Departments for ZFE cities
## Paris: 75,92,93,94 (Grand Paris/A86)
## Lyon: 69 | Grenoble: 38 | Rouen: 76 | Toulouse: 31
## Nice: 06 | Marseille: 13 | Montpellier: 34 | Saint-Etienne: 42
## Clermont-Ferrand: 63 | Reims: 51
zfe_depts <- c("06", "13", "31", "34", "38", "42", "51", "63",
               "69", "75", "76", "92", "93", "94")

years_geocoded <- 2020:2024
dvf_dir <- file.path(data_dir, "dvf_geo")
dir.create(dvf_dir, showWarnings = FALSE)

for (yr in years_geocoded) {
  for (dept in zfe_depts) {
    fname <- file.path(dvf_dir, paste0(dept, "_", yr, ".csv.gz"))
    if (!file.exists(fname)) {
      url <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/",
                     yr, "/departements/", dept, ".csv.gz")
      cat("  Downloading:", dept, yr, "...\n")
      tryCatch({
        download.file(url, fname, mode = "wb", quiet = TRUE)
      }, error = function(e) {
        cat("    WARN: Failed for", dept, yr, ":", e$message, "\n")
      })
    }
  }
}

## Read all department-year files into a single data.table
cat("  Reading DVF files...\n")
dvf_files <- list.files(dvf_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
dvf_files <- dvf_files[file.size(dvf_files) > 100]  # skip empty/failed

dvf_list <- lapply(dvf_files, function(f) {
  tryCatch({
    dt <- fread(f, select = c(
      "id_mutation", "date_mutation", "nature_mutation",
      "valeur_fonciere", "code_postal", "code_commune", "nom_commune",
      "code_departement", "id_parcelle",
      "nombre_lots", "code_type_local", "type_local",
      "surface_reelle_bati", "nombre_pieces_principales",
      "surface_terrain", "longitude", "latitude"
    ), na.strings = c("", "NA"))
    dt
  }, error = function(e) {
    cat("    WARN: Could not read", f, ":", e$message, "\n")
    NULL
  })
})

dvf_geo <- rbindlist(dvf_list[!sapply(dvf_list, is.null)], fill = TRUE)
cat("  DVF geocoded rows:", nrow(dvf_geo), "\n")
cat("  DVF geocoded with lat/lon:", sum(!is.na(dvf_geo$latitude)), "\n")
cat("  Years:", paste(sort(unique(substr(dvf_geo$date_mutation, 1, 4))), collapse = ", "), "\n")

## =========================================================================
## C. DVF non-geocoded transactions (2014-2019) for pre-trends
## =========================================================================

cat("\n=== C. Downloading DVF non-geocoded (2014-2019) for pre-trends ===\n")

## The original DVF bulk CSVs are at data.gouv.fr
## These don't have lat/lon but have commune codes for aggregate trends
dvf_raw_dir <- file.path(data_dir, "dvf_raw")
dir.create(dvf_raw_dir, showWarnings = FALSE)

## Check data.gouv.fr for the original DVF data
## The Etalab DVF CSV files cover 2014+
dvf_raw_base <- "https://files.data.gouv.fr/geo-dvf/latest/csv"

## Try full national files for 2020+ first (we already have dept files)
## For pre-2020, the original DVF is at a different location
## Try the data.gouv.fr DVF dataset (non-geocoded)
## URL pattern: https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/...
## Actually, use CEREMA API for commune-level aggregates (more efficient for 8GB RAM)

cat("  Fetching commune-level aggregates via CEREMA API for pre-trends...\n")

## ZFE commune codes for key cities
zfe_communes <- list(
  paris = paste0("751", sprintf("%02d", 1:20)),    # Paris arrondissements
  lyon  = c("69381", "69382", "69383", "69384", "69385",
            "69386", "69387", "69388", "69389"),     # Lyon arrondissements
  grenoble = "38185",
  rouen    = "76540",
  toulouse = "31555",
  nice     = "06088",
  marseille = paste0("132", sprintf("%02d", 1:16)),  # Marseille arrondissements
  montpellier = "34172",
  saint_etienne = "42218",
  clermont_ferrand = "63113",
  reims = "51454"
)

## For each commune, fetch summary counts by year from CEREMA API
commune_summary <- list()

for (city_name in names(zfe_communes)) {
  for (commune in zfe_communes[[city_name]]) {
    for (yr in 2014:2024) {
      url <- paste0(
        "https://apidf-preprod.cerema.fr/dvf_opendata/mutations/",
        "?code_insee=", commune,
        "&annee_mutation_min=", yr,
        "&annee_mutation_max=", yr,
        "&page_size=1"
      )
      tryCatch({
        resp <- httr::GET(url, httr::timeout(10))
        if (httr::status_code(resp) == 200) {
          js <- httr::content(resp, as = "parsed")
          commune_summary[[length(commune_summary) + 1]] <- data.table(
            city = city_name,
            code_commune = commune,
            year = yr,
            n_transactions = js$count
          )
        }
        Sys.sleep(0.1)  # Rate limit
      }, error = function(e) NULL)
    }
  }
  cat("    ", city_name, "done\n")
}

commune_counts <- rbindlist(commune_summary)
cat("  Commune-year transaction counts:", nrow(commune_counts), "\n")

## For commune-level price trends, fetch a sample of transactions per year
## Use a larger page_size to get median prices
cat("  Fetching price data for commune-level pre-trends...\n")

commune_prices <- list()
sample_communes <- c("75101", "75105", "75110", "75115", "75120",  # Paris sample
                      "69381", "69383", "69386",                    # Lyon
                      "38185", "76540", "31555", "06088", "34172")  # Other cities

for (commune in sample_communes) {
  for (yr in 2014:2024) {
    url <- paste0(
      "https://apidf-preprod.cerema.fr/dvf_opendata/mutations/",
      "?code_insee=", commune,
      "&annee_mutation_min=", yr,
      "&annee_mutation_max=", yr,
      "&page_size=100"
    )
    tryCatch({
      resp <- httr::GET(url, httr::timeout(15))
      if (httr::status_code(resp) == 200) {
        js <- httr::content(resp, as = "parsed")
        if (length(js$results) > 0) {
          prices <- sapply(js$results, function(x) {
            v <- as.numeric(x$valeurfonc)
            s <- as.numeric(x$sbati)
            if (!is.na(v) && !is.na(s) && s > 0) v / s else NA
          })
          prices <- prices[!is.na(prices) & prices > 100 & prices < 50000]
          if (length(prices) > 0) {
            commune_prices[[length(commune_prices) + 1]] <- data.table(
              code_commune = commune,
              year = yr,
              n_obs = length(prices),
              median_price_m2 = median(prices),
              mean_price_m2 = mean(prices),
              p25_price_m2 = quantile(prices, 0.25),
              p75_price_m2 = quantile(prices, 0.75)
            )
          }
        }
      }
      Sys.sleep(0.1)
    }, error = function(e) NULL)
  }
  cat("    ", commune, "done\n")
}

commune_price_trends <- rbindlist(commune_prices)
cat("  Commune-year price observations:", nrow(commune_price_trends), "\n")

## =========================================================================
## D. Air quality data (Open-Meteo / CAMS reanalysis)
## =========================================================================

cat("\n=== D. Downloading air quality data ===\n")

## City coordinates for air quality queries
city_coords <- data.table(
  city = c("paris", "lyon", "grenoble", "rouen", "toulouse",
           "nice", "marseille", "montpellier", "saint_etienne",
           "clermont_ferrand", "reims"),
  lat = c(48.8566, 45.7640, 45.1885, 49.4432, 43.6047,
          43.7102, 43.2965, 43.6108, 45.4397,
          45.7772, 49.2583),
  lon = c(2.3522, 4.8357, 5.7245, 1.0993, 1.4442,
          7.2620, 5.3698, 3.8767, 4.3872,
          3.0870, 3.5199),
  zfe_start = as.Date(c("2017-01-01", "2020-01-01", "2019-05-01",
                          "2021-09-01", "2022-03-01",
                          "2022-01-01", "2022-09-01", "2022-07-01",
                          "2022-01-01", "2023-01-01", "2023-01-01"))
)

aq_list <- list()

for (i in 1:nrow(city_coords)) {
  city <- city_coords$city[i]
  cat("  Fetching air quality for", city, "...\n")

  ## Fetch monthly averages by querying daily data in yearly chunks
  for (yr in 2018:2024) {
    url <- paste0(
      "https://air-quality-api.open-meteo.com/v1/air-quality",
      "?latitude=", city_coords$lat[i],
      "&longitude=", city_coords$lon[i],
      "&hourly=pm2_5,nitrogen_dioxide",
      "&start_date=", yr, "-01-01",
      "&end_date=", yr, "-12-31"
    )
    tryCatch({
      resp <- httr::GET(url, httr::timeout(30))
      if (httr::status_code(resp) == 200) {
        js <- httr::content(resp, as = "parsed")
        times <- unlist(js$hourly$time)
        no2 <- unlist(js$hourly$nitrogen_dioxide)
        pm25 <- unlist(js$hourly$pm2_5)

        ## Aggregate to monthly
        months <- substr(times, 1, 7)
        dt_aq <- data.table(
          month = months,
          no2 = as.numeric(no2),
          pm25 = as.numeric(pm25)
        )
        monthly <- dt_aq[, .(
          mean_no2 = mean(no2, na.rm = TRUE),
          mean_pm25 = mean(pm25, na.rm = TRUE),
          n_hours = sum(!is.na(no2))
        ), by = month]

        monthly[, city := city]
        aq_list[[length(aq_list) + 1]] <- monthly
      }
      Sys.sleep(0.2)
    }, error = function(e) {
      cat("    WARN:", city, yr, ":", e$message, "\n")
    })
  }
}

air_quality <- rbindlist(aq_list)
cat("  Air quality observations:", nrow(air_quality), "\n")

## =========================================================================
## E. Save all raw data
## =========================================================================

cat("\n=== E. Saving raw data ===\n")

fwrite(dvf_geo, file.path(data_dir, "dvf_geocoded_2020_2024.csv"))
st_write(zfe_boundaries, file.path(data_dir, "zfe_boundaries.geojson"),
         delete_dsn = TRUE, quiet = TRUE)
fwrite(commune_counts, file.path(data_dir, "commune_transaction_counts.csv"))
fwrite(commune_price_trends, file.path(data_dir, "commune_price_trends.csv"))
fwrite(air_quality, file.path(data_dir, "air_quality_monthly.csv"))
fwrite(city_coords, file.path(data_dir, "city_coordinates.csv"))

cat("\nAll data saved to", data_dir, "\n")

## =========================================================================
## F. Data validation
## =========================================================================

cat("\n=== F. Data validation ===\n")

stopifnot("Expected DVF geocoded data" = nrow(dvf_geo) > 100000)
stopifnot("Expected lat/lon coordinates" = sum(!is.na(dvf_geo$latitude)) > 50000)
stopifnot("Expected ZFE boundaries" = nrow(zfe_boundaries) > 0)
stopifnot("Expected air quality data" = nrow(air_quality) > 100)
stopifnot("Expected commune price trends" = nrow(commune_price_trends) > 50)

cat("Data validation passed:\n")
cat("  DVF geocoded:", format(nrow(dvf_geo), big.mark = ","), "rows\n")
cat("  DVF with coordinates:", format(sum(!is.na(dvf_geo$latitude)), big.mark = ","), "\n")
cat("  ZFE boundaries:", nrow(zfe_boundaries), "features\n")
cat("  Air quality:", nrow(air_quality), "city-month obs\n")
cat("  Commune price trends:", nrow(commune_price_trends), "commune-year obs\n")
