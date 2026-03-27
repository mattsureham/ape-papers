# 01_fetch_data.R — Fetch EPA Green Book, AQS air quality, and QWI data
# APEP Paper apep_1086: CAA Attainment Redesignation

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. EPA Green Book — PHISTORY (designation history, 1992-present)
# ============================================================================
cat("=== Fetching EPA Green Book ===\n")

# PHISTORY: all counties in nonattainment areas, with designation dates
phistory_url <- "https://www3.epa.gov/airquality/greenbook/downld/phistory.xls"
phistory_file <- file.path(data_dir, "phistory.xls")
if (!file.exists(phistory_file)) {
  resp <- GET(phistory_url, write_disk(phistory_file, overwrite = TRUE), timeout(60))
  if (resp$status_code != 200) stop("PHISTORY download failed: HTTP ", resp$status_code)
}
cat("PHISTORY:", format(file.size(phistory_file), big.mark = ","), "bytes\n")

# NAYRO: county-level current designations
nayro_url <- "https://www3.epa.gov/airquality/greenbook/downld/nayro.xls"
nayro_file <- file.path(data_dir, "nayro.xls")
if (!file.exists(nayro_file)) {
  resp <- GET(nayro_url, write_disk(nayro_file, overwrite = TRUE), timeout(60))
  if (resp$status_code != 200) stop("NAYRO download failed: HTTP ", resp$status_code)
}
cat("NAYRO:", format(file.size(nayro_file), big.mark = ","), "bytes\n")

# Quick check: read and validate
phistory <- read_xls(phistory_file)
cat("PHISTORY:", nrow(phistory), "rows,", ncol(phistory), "cols\n")
cat("Columns:", paste(names(phistory), collapse = ", "), "\n")

nayro <- read_xls(nayro_file)
cat("NAYRO:", nrow(nayro), "rows,", ncol(nayro), "cols\n")
cat("Columns:", paste(names(nayro), collapse = ", "), "\n")

# ============================================================================
# 2. AQS — Ambient Air Quality (annual county-level concentrations)
# ============================================================================
cat("\n=== Fetching AQS Annual Data ===\n")

# EPA pre-generated annual summary files
# PM2.5 (88101) and Ozone (44201) are the most common nonattainment pollutants
# Annual summary by county: already aggregated, ~2-5 MB each

aqs_base <- "https://aqs.epa.gov/aqsweb/airdata"

# Fetch annual concentration by monitor for PM2.5 and Ozone
for (yr in 2000:2023) {
  aqs_zip <- file.path(data_dir, paste0("aqs_annual_", yr, ".zip"))
  aqs_csv <- file.path(data_dir, paste0("aqs_annual_", yr, ".csv"))

  if (file.exists(aqs_csv)) {
    cat("AQS", yr, "exists\n")
    next
  }

  aqs_url <- paste0(aqs_base, "/annual_conc_by_monitor_", yr, ".zip")
  cat("Fetching AQS", yr, "...")

  resp <- tryCatch(
    GET(aqs_url, write_disk(aqs_zip, overwrite = TRUE), timeout(120)),
    error = function(e) { cat(" error:", e$message, "\n"); NULL }
  )

  if (!is.null(resp) && resp$status_code == 200) {
    # Unzip
    tryCatch({
      unzip(aqs_zip, exdir = data_dir)
      # Rename the extracted file
      extracted <- list.files(data_dir, pattern = paste0("annual_conc_by_monitor_", yr),
                              full.names = TRUE)
      extracted <- extracted[!grepl("\\.zip$", extracted)]
      if (length(extracted) > 0) {
        file.rename(extracted[1], aqs_csv)
      }
      file.remove(aqs_zip)
      cat(" OK:", format(file.size(aqs_csv), big.mark = ","), "bytes\n")
    }, error = function(e) cat(" unzip error:", e$message, "\n"))
  } else {
    cat(" HTTP", ifelse(is.null(resp), "error", resp$status_code), "\n")
    if (file.exists(aqs_zip)) file.remove(aqs_zip)
  }

  Sys.sleep(0.5)
}

# ============================================================================
# 3. QWI — Manufacturing Employment by County
# ============================================================================
cat("\n=== Fetching QWI Data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
census_key_param <- ifelse(census_key == "", "", paste0("&key=", census_key))

state_fips <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))

qwi_all <- list()
failed_states <- character(0)

for (st in state_fips) {
  qwi_file <- file.path(data_dir, paste0("qwi_mfg_", st, ".rds"))
  if (file.exists(qwi_file)) {
    qwi_all[[st]] <- readRDS(qwi_file)
    next
  }

  years_str <- paste(2001:2023, collapse = ",")

  qwi_url <- paste0(
    "https://api.census.gov/data/timeseries/qwi/se?",
    "get=Emp,EmpS,HirA,Sep,EarnHirAS",
    "&for=county:*",
    "&in=state:", st,
    "&industry=31-33",
    "&sex=0&agegrp=A00&race=A0&ethnicity=A0",
    "&firmage=0&firmsize=0&ownercode=A05",
    "&quarter=1",
    "&year=", years_str,
    census_key_param
  )

  cat("QWI state", st, "...")
  resp <- tryCatch(
    GET(qwi_url, timeout(60)),
    error = function(e) { cat(" err\n"); NULL }
  )

  if (is.null(resp) || resp$status_code != 200) {
    cat(" HTTP", ifelse(is.null(resp), "err", resp$status_code), "\n")
    failed_states <- c(failed_states, st)
    next
  }

  raw <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)

  if (is.null(parsed) || length(parsed) < 2) {
    cat(" empty\n")
    failed_states <- c(failed_states, st)
    next
  }

  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  saveRDS(df, qwi_file)
  qwi_all[[st]] <- df
  cat(" ", nrow(df), "rows\n")
  Sys.sleep(0.3)
}

qwi_combined <- bind_rows(qwi_all)
cat("\nQWI total:", format(nrow(qwi_combined), big.mark = ","), "rows\n")
if (length(failed_states) > 0) {
  cat("Failed states:", paste(failed_states, collapse = ", "), "\n")
}
saveRDS(qwi_combined, file.path(data_dir, "qwi_manufacturing.rds"))

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
all_files <- list.files(data_dir)
cat("Total files:", length(all_files), "\n")
cat("Green Book: phistory.xls (", nrow(phistory), "rows), nayro.xls (", nrow(nayro), "rows)\n")
cat("AQS annual files:", sum(grepl("aqs_annual", all_files)), "years\n")
cat("QWI counties:", format(nrow(qwi_combined), big.mark = ","), "obs\n")
