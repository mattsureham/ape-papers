## 01b_combine_data.R — Combine downloaded DVF files and save essential datasets
## Run this instead of 01_fetch_data.R (which was interrupted)

source("00_packages.R")

data_dir <- "../data"

## =========================================================================
## A. Combine DVF department files
## =========================================================================

cat("=== A. Combining DVF department files ===\n")

dvf_dir <- file.path(data_dir, "dvf_geo")
dvf_files <- list.files(dvf_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
dvf_files <- dvf_files[file.size(dvf_files) > 100]

cat("  Found", length(dvf_files), "files\n")

dvf_list <- lapply(dvf_files, function(f) {
  tryCatch({
    fread(f, select = c(
      "id_mutation", "date_mutation", "nature_mutation",
      "valeur_fonciere", "code_postal", "code_commune", "nom_commune",
      "code_departement", "id_parcelle",
      "nombre_lots", "code_type_local", "type_local",
      "surface_reelle_bati", "nombre_pieces_principales",
      "surface_terrain", "longitude", "latitude"
    ), na.strings = c("", "NA"))
  }, error = function(e) {
    cat("  WARN: Could not read", basename(f), "\n")
    NULL
  })
})

dvf_geo <- rbindlist(dvf_list[!sapply(dvf_list, is.null)], fill = TRUE)
cat("  DVF geocoded rows:", format(nrow(dvf_geo), big.mark = ","), "\n")
cat("  DVF with lat/lon:", format(sum(!is.na(dvf_geo$latitude)), big.mark = ","), "\n")

fwrite(dvf_geo, file.path(data_dir, "dvf_geocoded_2020_2024.csv"))
cat("  Saved dvf_geocoded_2020_2024.csv\n")

## =========================================================================
## B. Save city coordinates and ZFE dates
## =========================================================================

cat("\n=== B. Saving city coordinates ===\n")

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

fwrite(city_coords, file.path(data_dir, "city_coordinates.csv"))

## =========================================================================
## C. Air quality data (Open-Meteo / CAMS)
## =========================================================================

cat("\n=== C. Downloading air quality data ===\n")

aq_list <- list()

for (i in 1:nrow(city_coords)) {
  city <- city_coords$city[i]
  cat("  ", city, "...")

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
        no2 <- as.numeric(unlist(js$hourly$nitrogen_dioxide))
        pm25 <- as.numeric(unlist(js$hourly$pm2_5))
        months <- substr(times, 1, 7)
        dt_aq <- data.table(month = months, no2 = no2, pm25 = pm25)
        monthly <- dt_aq[, .(
          mean_no2 = mean(no2, na.rm = TRUE),
          mean_pm25 = mean(pm25, na.rm = TRUE),
          n_hours = sum(!is.na(no2))
        ), by = month]
        monthly[, city := city]
        aq_list[[length(aq_list) + 1]] <- monthly
      }
      Sys.sleep(0.15)
    }, error = function(e) NULL)
  }
  cat(" done\n")
}

air_quality <- rbindlist(aq_list)
fwrite(air_quality, file.path(data_dir, "air_quality_monthly.csv"))
cat("  Air quality:", nrow(air_quality), "city-month observations\n")

## =========================================================================
## D. Validation
## =========================================================================

cat("\n=== D. Validation ===\n")
stopifnot("DVF data present" = nrow(dvf_geo) > 100000)
stopifnot("Coordinates present" = sum(!is.na(dvf_geo$latitude)) > 50000)
stopifnot("BNZFE boundary file present" = file.exists(file.path(data_dir, "bnzfe_aires.geojson")))
stopifnot("Air quality data present" = nrow(air_quality) > 100)

cat("All validation passed.\n")
cat("  DVF:", format(nrow(dvf_geo), big.mark = ","), "rows\n")
cat("  Air quality:", nrow(air_quality), "city-months\n")
cat("  BNZFE: present\n")
