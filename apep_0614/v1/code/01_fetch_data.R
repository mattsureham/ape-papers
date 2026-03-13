## 01_fetch_data.R — Download CEJST, NREL EV stations, and HMDA data
## APEP paper apep_0614: CEJST Justice40 RDD

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. CEJST data via ArcGIS Feature Service (archived Nov 2022 v1.0)
# ============================================================
cat("=== Fetching CEJST data from ArcGIS ===\n")

cejst_file <- file.path(data_dir, "cejst_tracts.csv")

if (!file.exists(cejst_file)) {
  base_url <- "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/usa_november_2022/FeatureServer/0/query"

  # Fields we need (no geometry to save bandwidth)
  fields <- paste0(
    "GEOID10,SF,CF,P200_I_PFS,SN_C,SN_T,TPF,THRHLD,",
    "N_CLT,N_ENY,N_TRN,N_HSG,N_PLN,N_HLTH,N_WTR,N_WKFC,",
    "DF_PFS,AF_PFS,HDF_PFS,EBF_PFS,PM25F_PFS,LPF_PFS,TF_PFS,WF_PFS,",
    "DM_B,DM_AI,DM_A,DM_HI,DM_T,DM_W,DM_H,DM_O"
  )

  # Paginate through all 73,767 records (ArcGIS max 2000 per request)
  all_rows <- list()
  offset <- 0
  batch_size <- 2000
  total_expected <- 73767

  cat("Downloading CEJST tracts in batches of", batch_size, "...\n")

  repeat {
    resp <- request(base_url) |>
      req_url_query(
        where = "1=1",
        outFields = fields,
        returnGeometry = "false",
        resultOffset = as.character(offset),
        resultRecordCount = as.character(batch_size),
        f = "json"
      ) |>
      req_timeout(60) |>
      req_perform()

    if (resp_status(resp) != 200) {
      stop("ArcGIS query failed at offset ", offset, " with status ", resp_status(resp))
    }

    body <- resp_body_json(resp)
    features <- body$features

    if (length(features) == 0) break

    # Extract attributes into data.table rows
    batch <- rbindlist(lapply(features, function(f) as.data.table(f$attributes)), fill = TRUE)
    all_rows[[length(all_rows) + 1]] <- batch

    offset <- offset + length(features)
    if (offset %% 10000 == 0 || offset >= total_expected) {
      cat(sprintf("  Downloaded %d / ~%d tracts\n", offset, total_expected))
    }

    if (length(features) < batch_size) break
  }

  cejst <- rbindlist(all_rows, fill = TRUE)
  cat("CEJST total tracts downloaded:", nrow(cejst), "\n")

  stopifnot(nrow(cejst) >= 70000)  # Sanity check

  fwrite(cejst, cejst_file)
  cat("CEJST data saved to", cejst_file, "\n")
} else {
  cat("CEJST data already exists, skipping download.\n")
  cejst <- fread(cejst_file)
  cat("CEJST tracts loaded:", nrow(cejst), "\n")
}

# Quick validation
cat("\nCEJST columns:", paste(names(cejst), collapse = ", "), "\n")
cat("Designated (SN_C=1):", sum(cejst$SN_C == 1, na.rm = TRUE), "\n")
cat("Not designated (SN_C=0):", sum(cejst$SN_C == 0, na.rm = TRUE), "\n")
cat("Income pctile range:", range(cejst$P200_I_PFS, na.rm = TRUE), "\n")
rm(cejst)

# ============================================================
# 2. NREL Alternative Fuel Stations (EV chargers)
# ============================================================
cat("\n=== Fetching NREL EV station data ===\n")

ev_file <- file.path(data_dir, "nrel_ev_stations.csv")

if (!file.exists(ev_file)) {
  # NREL AFDC API — download electric stations
  nrel_url <- "https://developer.nrel.gov/api/alt-fuel-stations/v1.csv"

  cat("Downloading NREL EV station data...\n")
  resp <- tryCatch({
    request(nrel_url) |>
      req_url_query(
        api_key = "DEMO_KEY",
        fuel_type = "ELEC",
        country = "US",
        status = "E",
        limit = "all"
      ) |>
      req_timeout(300) |>
      req_perform()
  }, error = function(e) {
    cat("NREL API error:", e$message, "\n")
    NULL
  })

  if (!is.null(resp) && resp_status(resp) == 200) {
    writeBin(resp_body_raw(resp), ev_file)
    cat("EV station data saved:", format(file.size(ev_file), big.mark = ","), "bytes\n")
  } else {
    # Try without limit=all
    cat("Retrying NREL without limit=all...\n")
    resp <- request(nrel_url) |>
      req_url_query(
        api_key = "DEMO_KEY",
        fuel_type = "ELEC",
        country = "US",
        status = "E"
      ) |>
      req_timeout(300) |>
      req_perform()

    if (resp_status(resp) != 200) {
      stop("NREL EV station download failed with status: ", resp_status(resp))
    }
    writeBin(resp_body_raw(resp), ev_file)
    cat("EV station data saved:", format(file.size(ev_file), big.mark = ","), "bytes\n")
  }
} else {
  cat("EV station data already exists, skipping download.\n")
}

# Validate EV data
ev_sample <- fread(ev_file, nrows = 5)
cat("EV station columns:", paste(head(names(ev_sample), 15), collapse = ", "), "\n")
rm(ev_sample)

# ============================================================
# 3. HMDA Mortgage Data (2021 pre, 2023 post)
# ============================================================
cat("\n=== Fetching HMDA data ===\n")

hmda_dir <- file.path(data_dir, "hmda")
dir.create(hmda_dir, showWarnings = FALSE)

fetch_hmda_year <- function(year) {
  hmda_file <- file.path(hmda_dir, paste0("hmda_", year, ".csv"))
  if (file.exists(hmda_file)) {
    cat(sprintf("HMDA %d already exists, skipping.\n", year))
    return(invisible(NULL))
  }

  cat(sprintf("Downloading HMDA %d from CFPB...\n", year))

  # Use CFPB HMDA data browser — request originated purchase mortgages for 10 large states
  states <- "CA,TX,FL,NY,PA,IL,OH,GA,NC,MI"
  url <- sprintf(
    "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?states=%s&years=%d&actions_taken=1&loan_purposes=1",
    states, year
  )

  resp <- tryCatch({
    request(url) |>
      req_timeout(600) |>
      req_perform()
  }, error = function(e) {
    cat(sprintf("HMDA %d error: %s\n", year, e$message))
    NULL
  })

  if (!is.null(resp) && resp_status(resp) == 200) {
    writeBin(resp_body_raw(resp), hmda_file)
    cat(sprintf("HMDA %d saved: %s bytes\n", year, format(file.size(hmda_file), big.mark = ",")))
  } else {
    cat(sprintf("HMDA %d download failed. Will proceed with EV data only.\n", year))
  }
}

fetch_hmda_year(2021)
fetch_hmda_year(2023)

cat("\n=== All data downloads complete ===\n")
cat("Files in data directory:\n")
cat(paste(list.files(data_dir, recursive = TRUE), collapse = "\n"), "\n")
