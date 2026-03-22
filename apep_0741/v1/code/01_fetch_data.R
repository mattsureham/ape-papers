## 01_fetch_data.R — Download FARS data from NHTSA
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- FARS download ----
fars_years <- 2015:2022

for (yr in fars_years) {
  zip_file <- file.path(data_dir, paste0("FARS", yr, "NationalCSV.zip"))

  if (!file.exists(zip_file)) {
    url <- paste0("https://static.nhtsa.gov/nhtsa/downloads/FARS/", yr,
                   "/National/FARS", yr, "NationalCSV.zip")
    cat("Downloading FARS", yr, "from", url, "\n")

    result <- tryCatch(
      download.file(url, zip_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        stop("FATAL: Failed to download FARS ", yr, ": ", e$message,
             "\nCannot proceed without real data.")
      }
    )
    if (result != 0) stop("FATAL: download.file returned non-zero for FARS ", yr)
    cat("  Downloaded:", round(file.info(zip_file)$size / 1e6, 1), "MB\n")
  } else {
    cat("FARS", yr, "already downloaded.\n")
  }
}

## ---- Extract relevant CSVs ----
accident_list <- list()
distract_list <- list()

for (yr in fars_years) {
  zip_file <- file.path(data_dir, paste0("FARS", yr, "NationalCSV.zip"))
  contents <- unzip(zip_file, list = TRUE)$Name

  acc_file <- contents[grepl("accident", contents, ignore.case = TRUE) &
                         grepl("\\.csv$", contents, ignore.case = TRUE)][1]
  dist_file <- contents[grepl("distract", contents, ignore.case = TRUE) &
                          grepl("\\.csv$", contents, ignore.case = TRUE)][1]

  if (is.na(acc_file)) stop("FATAL: No ACCIDENT CSV in FARS ", yr)
  if (is.na(dist_file)) stop("FATAL: No DISTRACT CSV in FARS ", yr)

  cat("Extracting", yr, ":", acc_file, "+", dist_file, "\n")

  # Read accident — read all columns then select to handle schema changes
  acc_raw <- fread(cmd = paste0("unzip -p '", zip_file, "' '", acc_file, "'"),
                   showProgress = FALSE)

  # Standardize column names
  if ("LONGITUDE" %in% names(acc_raw) && !"LONGITUD" %in% names(acc_raw)) {
    setnames(acc_raw, "LONGITUDE", "LONGITUD")
  }

  # Keep needed columns (DRUNK_DR missing in 2021-2022)
  keep_cols <- intersect(
    c("STATE", "ST_CASE", "COUNTY", "MONTH", "DAY", "YEAR", "HOUR",
      "LATITUDE", "LONGITUD", "FATALS", "DRUNK_DR", "WEATHER", "FUNC_SYS"),
    names(acc_raw)
  )
  acc_raw <- acc_raw[, ..keep_cols]
  if (!"DRUNK_DR" %in% names(acc_raw)) acc_raw[, DRUNK_DR := NA_integer_]

  accident_list[[as.character(yr)]] <- acc_raw

  # Read distract — handle column name change (MDRDSTRD → DRDISTRACT in 2020+)
  dist_raw <- fread(cmd = paste0("unzip -p '", zip_file, "' '", dist_file, "'"),
                    showProgress = FALSE)

  # Standardize: rename DRDISTRACT → MDRDSTRD for consistency
  if ("DRDISTRACT" %in% names(dist_raw) && !"MDRDSTRD" %in% names(dist_raw)) {
    setnames(dist_raw, "DRDISTRACT", "MDRDSTRD")
  }

  dist_raw <- dist_raw[, .(STATE, ST_CASE, MDRDSTRD)]
  distract_list[[as.character(yr)]] <- dist_raw
}

## ---- Combine across years ----
accident <- rbindlist(accident_list, use.names = TRUE, fill = TRUE)
distract <- rbindlist(distract_list, use.names = TRUE, fill = TRUE)

cat("\nAccident records:", nrow(accident), "\n")
cat("Distract records:", nrow(distract), "\n")

## ---- Clean coordinates ----
accident[, LATITUDE := as.numeric(LATITUDE)]
accident[, LONGITUD := as.numeric(LONGITUD)]

# Remove invalid coordinates (continental US only)
accident <- accident[
  LATITUDE > 24 & LATITUDE < 50 &
  LONGITUD < -65 & LONGITUD > -125
]

cat("After coordinate cleaning:", nrow(accident), "crashes\n")

## ---- Flag phone-distracted crashes ----
# Phone codes: 5 (talking/listening), 6 (manipulating), 15 (other cellular phone related)
phone_crashes <- distract[MDRDSTRD %in% c(5, 6, 15),
                          .(phone_distracted = 1L),
                          by = .(STATE, ST_CASE)]

# Any distraction: exclude 0 (not distracted), 96 (not reported), 97-99 (unknown)
any_distract_dt <- distract[!is.na(MDRDSTRD) & !MDRDSTRD %in% c(0, 96, 97, 98, 99),
                            .(any_distraction = 1L),
                            by = .(STATE, ST_CASE)]

# Non-phone distraction: codes like 3,7,9,10,13 (eating, radio, etc.) but NOT phone
nonphone_codes <- c(1, 2, 3, 4, 7, 8, 9, 10, 11, 13, 14, 19, 92, 93, 97, 98)
nonphone_distract_dt <- distract[MDRDSTRD %in% nonphone_codes,
                                 .(nonphone_distracted = 1L),
                                 by = .(STATE, ST_CASE)]

accident <- merge(accident, phone_crashes, by = c("STATE", "ST_CASE"), all.x = TRUE)
accident <- merge(accident, any_distract_dt, by = c("STATE", "ST_CASE"), all.x = TRUE)
accident <- merge(accident, nonphone_distract_dt, by = c("STATE", "ST_CASE"), all.x = TRUE)

accident[is.na(phone_distracted), phone_distracted := 0L]
accident[is.na(any_distraction), any_distraction := 0L]
accident[is.na(nonphone_distracted), nonphone_distracted := 0L]

cat("\nPhone-distracted crashes:", sum(accident$phone_distracted), "\n")
cat("Any-distraction crashes:", sum(accident$any_distraction), "\n")
cat("Non-phone-distraction crashes:", sum(accident$nonphone_distracted), "\n")
cat("Total fatal crashes:", nrow(accident), "\n")

## ---- Save combined data ----
fwrite(accident, file.path(data_dir, "fars_accident_2015_2022.csv"))
cat("\nSaved:", file.path(data_dir, "fars_accident_2015_2022.csv"), "\n")
cat("Done.\n")
