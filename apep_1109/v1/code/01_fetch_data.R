## 01_fetch_data.R — Fetch all data sources
## apep_1109: Crop Insurance and Deaths of Despair

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
setwd(data_dir)

cat("=== 1. NCHS Model-Based Drug Overdose Death Rates ===\n")

if (!file.exists("nchs_overdose_raw.csv")) {
  nchs_url <- "https://data.cdc.gov/resource/rpvx-m2md.csv"
  limit <- 50000
  offset <- 0
  nchs_chunks <- list()

  repeat {
    resp <- httr2::request(nchs_url) |>
      httr2::req_url_query(`$limit` = limit, `$offset` = offset) |>
      httr2::req_perform()

    chunk <- httr2::resp_body_string(resp) |> read.csv(text = _)
    if (nrow(chunk) == 0) break
    nchs_chunks <- c(nchs_chunks, list(chunk))
    offset <- offset + limit
    cat(sprintf("  Fetched %d rows (offset %d)\n", nrow(chunk), offset))
    if (nrow(chunk) < limit) break
  }

  nchs_raw <- bind_rows(nchs_chunks)
  fwrite(nchs_raw, "nchs_overdose_raw.csv")
  cat(sprintf("NCHS: %d rows, %d counties, years %d-%d\n",
              nrow(nchs_raw), n_distinct(nchs_raw$fips),
              min(nchs_raw$year), max(nchs_raw$year)))
} else {
  nchs_raw <- fread("nchs_overdose_raw.csv")
  cat(sprintf("NCHS loaded from cache: %d rows\n", nrow(nchs_raw)))
}
stopifnot("NCHS data must have >50000 rows" = nrow(nchs_raw) > 50000)

cat("\n=== 2. USDA RMA Crop Insurance Summary of Business ===\n")

if (!file.exists("rma_county_year.csv")) {
  rma_all <- list()

  for (yr in 2003:2021) {
    rma_url <- sprintf(
      "https://pubfs-rma.fpac.usda.gov/pub/Web_Data_Files/Summary_of_Business/state_county_crop/sobcov_%d.zip",
      yr
    )
    cat(sprintf("  Fetching RMA %d... ", yr))
    tmp_zip <- tempfile(fileext = ".zip")

    resp <- tryCatch(
      {
        httr2::request(rma_url) |>
          httr2::req_timeout(120) |>
          httr2::req_perform(path = tmp_zip)
      },
      error = function(e) NULL
    )

    if (!is.null(resp)) {
      # Extract the txt file from zip
      txt_files <- unzip(tmp_zip, list = TRUE)$Name
      txt_file <- txt_files[grepl("\\.txt$", txt_files, ignore.case = TRUE)][1]

      if (!is.na(txt_file)) {
        tmp_dir <- tempdir()
        unzip(tmp_zip, files = txt_file, exdir = tmp_dir)

        chunk <- fread(
          file.path(tmp_dir, txt_file),
          sep = "|", header = FALSE,
          colClasses = "character"
        )

        # Columns per RMA layout: V1=year, V2=state_fips, V4=county_fips,
        # V21=liability, V22=premium, V23=subsidy, V27=indemnity
        if (ncol(chunk) >= 27) {
          county_agg <- chunk[, .(
            indemnity = sum(as.numeric(gsub(",", "", V27)), na.rm = TRUE),
            premium = sum(as.numeric(gsub(",", "", V22)), na.rm = TRUE),
            subsidy = sum(as.numeric(gsub(",", "", V23)), na.rm = TRUE),
            liability = sum(as.numeric(gsub(",", "", V21)), na.rm = TRUE),
            policies = sum(as.numeric(V14), na.rm = TRUE),
            net_acres = sum(as.numeric(gsub(",", "", V19)), na.rm = TRUE)
          ), by = .(state_fips = V2, county_fips = V4, year = as.integer(V1))]

          rma_all <- c(rma_all, list(county_agg))
          cat(sprintf("%d county-years\n", nrow(county_agg)))
        } else {
          cat(sprintf("unexpected columns: %d\n", ncol(chunk)))
        }
        unlink(file.path(tmp_dir, txt_file))
      } else {
        cat("no txt in zip\n")
      }
    } else {
      cat("download failed\n")
    }
    unlink(tmp_zip)
  }

  if (length(rma_all) == 0) stop("FATAL: Cannot download RMA crop insurance data")

  rma_county <- rbindlist(rma_all)
  # Create 5-digit FIPS
  rma_county[, fips := sprintf("%02d%03d",
                                as.integer(state_fips),
                                as.integer(county_fips))]
  fwrite(rma_county, "rma_county_year.csv")
  cat(sprintf("RMA total: %d county-year obs, %d years\n",
              nrow(rma_county), n_distinct(rma_county$year)))
} else {
  rma_county <- fread("rma_county_year.csv")
  cat(sprintf("RMA loaded from cache: %d rows\n", nrow(rma_county)))
}

cat("\n=== 3. NOAA Palmer Drought Severity Index ===\n")

if (!file.exists("pdsi_raw.txt")) {
  pdsi_url <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-pdsidv-v1.0.0-20260305"
  cat("  Fetching PDSI from NCEI...\n")
  resp <- httr2::request(pdsi_url) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  pdsi_text <- httr2::resp_body_string(resp)
  writeLines(pdsi_text, "pdsi_raw.txt")
  cat(sprintf("  PDSI saved: %d bytes\n", nchar(pdsi_text)))
} else {
  cat("  PDSI loaded from cache\n")
}
stopifnot("PDSI file must exist" = file.exists("pdsi_raw.txt"))

cat("\n=== 4. Climate Division to County Crosswalk ===\n")

if (!file.exists("climdiv_county_xwalk.csv")) {
  xwalk_url <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/county-to-climdiv-assignment.csv"
  resp <- tryCatch(
    httr2::request(xwalk_url) |>
      httr2::req_timeout(60) |>
      httr2::req_perform(),
    error = function(e) NULL
  )
  if (!is.null(resp)) {
    writeLines(httr2::resp_body_string(resp), "climdiv_county_xwalk.csv")
    cat("  Crosswalk saved\n")
  } else {
    cat("  Crosswalk not directly available — will construct from FIPS-division mapping\n")
  }
} else {
  cat("  Crosswalk loaded from cache\n")
}

cat("\n=== 5. Population Data (Census) ===\n")
# Population already in NCHS data — will use that
cat("  Using population from NCHS dataset\n")

cat("\n=== All data fetch complete ===\n")
cat(sprintf("Files: %s\n", paste(list.files(data_dir), collapse = ", ")))
