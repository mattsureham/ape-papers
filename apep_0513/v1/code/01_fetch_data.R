## 01_fetch_data.R — Fetch STATS19 road casualty data + Land Registry PPD
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. STATS19 Collision Data (2019–2024)
# ============================================================
cat("=== Fetching STATS19 collision data ===\n")

# Years to fetch
years <- 2019:2023

collisions_list <- list()
casualties_list <- list()

for (yr in years) {
  cat(sprintf("  Downloading %d collisions...\n", yr))
  col <- tryCatch(
    get_stats19(year = yr, type = "collision"),
    error = function(e) stop("STATS19 collision download failed for ", yr, ": ", e$message,
                              "\nCannot proceed without real collision data.")
  )
  collisions_list[[as.character(yr)]] <- col

  cat(sprintf("  Downloading %d casualties...\n", yr))
  cas <- tryCatch(
    get_stats19(year = yr, type = "casualty"),
    error = function(e) stop("STATS19 casualty download failed for ", yr, ": ", e$message,
                              "\nCannot proceed without real casualty data.")
  )
  casualties_list[[as.character(yr)]] <- cas
}

# Attempt 2024 data
cat("  Attempting 2024 data download...\n")
col_2024 <- tryCatch(
  get_stats19(year = 2024, type = "collision"),
  error = function(e) {
    cat("  NOTE: 2024 collision data not yet in stats19 package. Will try direct download.\n")
    NULL
  }
)
cas_2024 <- tryCatch(
  get_stats19(year = 2024, type = "casualty"),
  error = function(e) {
    cat("  NOTE: 2024 casualty data not yet in stats19 package.\n")
    NULL
  }
)

if (!is.null(col_2024)) collisions_list[["2024"]] <- col_2024
if (!is.null(cas_2024)) casualties_list[["2024"]] <- cas_2024

# Try direct download of 2024 if stats19 package doesn't have it
if (is.null(col_2024)) {
  cat("  Trying direct CSV download for 2024...\n")
  url_2024 <- "https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-collision-2024.csv"
  dest_2024 <- file.path(data_dir, "collisions_2024.csv")
  dl_ok <- tryCatch({
    download.file(url_2024, dest_2024, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) {
    cat("  Direct 2024 download failed:", e$message, "\n")
    FALSE
  })
  if (dl_ok && file.exists(dest_2024) && file.size(dest_2024) > 1000) {
    col_2024_raw <- fread(dest_2024)
    cat(sprintf("  Downloaded 2024 collisions: %d rows\n", nrow(col_2024_raw)))
    collisions_list[["2024"]] <- col_2024_raw

    # Also try casualties
    url_cas_2024 <- "https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-casualty-2024.csv"
    dest_cas_2024 <- file.path(data_dir, "casualties_2024.csv")
    tryCatch({
      download.file(url_cas_2024, dest_cas_2024, mode = "wb", quiet = TRUE)
      cas_2024_raw <- fread(dest_cas_2024)
      cat(sprintf("  Downloaded 2024 casualties: %d rows\n", nrow(cas_2024_raw)))
      casualties_list[["2024"]] <- cas_2024_raw
    }, error = function(e) {
      cat("  2024 casualties direct download failed:", e$message, "\n")
    })
  }
}

# Bind all years
cat("  Binding collision data across years...\n")
collisions <- rbindlist(lapply(collisions_list, as.data.table), fill = TRUE)
casualties <- rbindlist(lapply(casualties_list, as.data.table), fill = TRUE)

cat(sprintf("  Total collisions: %s rows\n", format(nrow(collisions), big.mark = ",")))
cat(sprintf("  Total casualties: %s rows\n", format(nrow(casualties), big.mark = ",")))

# ============================================================
# 2. Identify Welsh vs English Collisions
# ============================================================
cat("\n=== Identifying Welsh vs English areas ===\n")

# Welsh police forces
welsh_forces <- c("Dyfed-Powys", "Gwent", "North Wales", "South Wales")
scottish_forces <- c("Police Scotland")

# Use police_force field for geographic assignment (more complete than LA codes)
if ("police_force" %in% names(collisions)) {
  collisions[, nation := fifelse(
    police_force %in% welsh_forces, "Wales",
    fifelse(police_force %in% scottish_forces, "Scotland", "England")
  )]
} else {
  # Fallback: use LSOA prefix
  collisions[, nation := fcase(
    grepl("^W", lsoa_of_collision_location), "Wales",
    grepl("^S", lsoa_of_collision_location), "Scotland",
    grepl("^E", lsoa_of_collision_location), "England",
    default = NA_character_
  )]
}

cat("  Nation distribution:\n")
print(collisions[, .N, by = nation])

# ============================================================
# 3. Save Processed Data
# ============================================================
cat("\n=== Saving data ===\n")

fwrite(collisions, file.path(data_dir, "collisions_all_years.csv"))
fwrite(casualties, file.path(data_dir, "casualties_all_years.csv"))

cat("  Saved collisions_all_years.csv and casualties_all_years.csv\n")

# ============================================================
# 4. Land Registry Price Paid Data (Welsh + English border LAs)
# ============================================================
cat("\n=== Fetching Land Registry Price Paid Data ===\n")

# Download annual files for 2019-2024
lr_years <- 2019:2024
lr_list <- list()

for (yr in lr_years) {
  url <- sprintf("http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-%d.csv", yr)
  dest <- file.path(data_dir, sprintf("pp_%d.csv", yr))

  if (!file.exists(dest)) {
    cat(sprintf("  Downloading Land Registry %d...\n", yr))
    dl_ok <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      cat(sprintf("  WARNING: Land Registry %d download failed: %s\n", yr, e$message))
      FALSE
    })
    if (!dl_ok) next
  } else {
    cat(sprintf("  Land Registry %d already downloaded.\n", yr))
  }

  if (file.exists(dest) && file.size(dest) > 1000) {
    cat(sprintf("  Reading Land Registry %d...\n", yr))
    lr <- fread(dest, header = FALSE,
                col.names = c("txn_id", "price", "date", "postcode", "prop_type",
                              "new_build", "tenure", "paon", "saon", "street",
                              "locality", "town", "district", "county",
                              "ppd_cat", "record_status"))
    lr[, year := yr]
    lr_list[[as.character(yr)]] <- lr
  }
}

if (length(lr_list) > 0) {
  land_reg <- rbindlist(lr_list, fill = TRUE)
  cat(sprintf("  Total Land Registry transactions: %s\n", format(nrow(land_reg), big.mark = ",")))
  fwrite(land_reg, file.path(data_dir, "land_registry_all.csv"))
  cat("  Saved land_registry_all.csv\n")
} else {
  stop("No Land Registry data downloaded. Cannot proceed without property price data.")
}

# ============================================================
# 5. ONS Mid-Year Population Estimates
# ============================================================
cat("\n=== Fetching ONS Population Estimates ===\n")

# Download LA-level population estimates from NOMIS
# NM_2002_1 = Mid-Year Population Estimates
pop_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?",
  "geography=TYPE464&",  # Local authority districts (2023 boundaries)
  "date=latestMINUS5-latest&",  # Last 6 years
  "gender=0&",  # All persons
  "c_age=200&",  # All ages
  "measures=20100"  # Value
)

nomis_key <- Sys.getenv("NOMIS_API_KEY")
if (nchar(nomis_key) > 0) {
  pop_url <- paste0(pop_url, "&uid=", nomis_key)
}

pop_dest <- file.path(data_dir, "population_la.csv")
tryCatch({
  download.file(pop_url, pop_dest, mode = "wb", quiet = TRUE)
  pop <- fread(pop_dest)
  cat(sprintf("  Population data: %d rows, %d LAs\n", nrow(pop), n_distinct(pop$GEOGRAPHY_CODE)))
}, error = function(e) {
  cat("  WARNING: Population download from NOMIS failed:", e$message, "\n")
  cat("  Will use collision counts without per-capita normalization.\n")
})

# ============================================================
# 6. Data Validation
# ============================================================
cat("\n=== Data Validation ===\n")

# Validate collision data
stopifnot("Need Welsh collisions" = sum(collisions$nation == "Wales", na.rm = TRUE) > 5000)
stopifnot("Need English collisions" = sum(collisions$nation == "England", na.rm = TRUE) > 100000)
stopifnot("Need multiple years" = length(unique(year(collisions$date))) >= 5)

# Check speed limit field
if ("speed_limit" %in% names(collisions)) {
  cat("  Speed limit distribution:\n")
  print(collisions[!is.na(speed_limit), .N, by = speed_limit][order(speed_limit)])
  stopifnot("Need 20mph and 30mph collisions" =
    sum(collisions$speed_limit %in% c(20, 30), na.rm = TRUE) > 50000)
}

# Validate Land Registry
if (exists("land_reg")) {
  stopifnot("Need Land Registry transactions" = nrow(land_reg) > 1000000)
  cat(sprintf("  Land Registry: %s transactions across %d years\n",
              format(nrow(land_reg), big.mark = ","),
              n_distinct(land_reg$year)))
}

cat("\n=== DATA VALIDATION PASSED ===\n")
cat(sprintf("  Collisions: %s rows, nations: %s\n",
            format(nrow(collisions), big.mark = ","),
            paste(unique(collisions$nation), collapse = ", ")))
cat(sprintf("  Years covered: %s\n",
            paste(sort(unique(year(collisions$date))), collapse = ", ")))
