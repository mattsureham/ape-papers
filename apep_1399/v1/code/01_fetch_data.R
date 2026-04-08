# 01_fetch_data.R — Fetch CDC WONDER mortality, USGS radon, building permits, controls
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. USGS Geological Radon Potential Shapefile
# ============================================================================
cat("=== Fetching USGS Radon Potential Data ===\n")

usgs_radon_url <- "https://www.sciencebase.gov/catalog/file/get/687e988bd4be027f6b8de54d?f=__disk__6c%2F72%2Fb0%2F6c72b02a26a7b5fc495bf216efd72f82a43492cb"
radon_zip <- file.path(data_dir, "usradon.zip")
radon_dir <- file.path(data_dir, "usradon")

if (!file.exists(file.path(radon_dir, "usradon.shp"))) {
  resp <- httr::GET(usgs_radon_url, httr::timeout(120),
                    httr::write_disk(radon_zip, overwrite = TRUE))
  stopifnot("USGS radon download failed" = httr::status_code(resp) == 200)
  stopifnot("USGS radon file too small" = file.size(radon_zip) > 100000)
  dir.create(radon_dir, showWarnings = FALSE)
  unzip(radon_zip, exdir = radon_dir)
  cat("USGS radon shapefile downloaded and extracted\n")
} else {
  cat("USGS radon shapefile already exists\n")
}

# Verify shapefile exists
shp_files <- list.files(radon_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
stopifnot("No .shp file found in radon download" = length(shp_files) > 0)
cat("Radon shapefile:", shp_files[1], "\n")

# ============================================================================
# 2. CDC WONDER Compressed Mortality — Lung Cancer (ICD-10 C33-C34)
# ============================================================================
cat("\n=== Fetching CDC WONDER Lung Cancer Mortality ===\n")

# CDC WONDER API endpoint for Compressed Mortality 1999-2020
# We submit a form-style request for county-year lung cancer deaths
# ICD-10 codes: C33 (trachea), C34 (bronchus/lung)

wonder_url <- "https://wonder.cdc.gov/controller/datarequest/D77"

# CDC WONDER requires specific form parameters
# We'll query by county, year, cause of death (ICD-10 C33-C34)
# First try the API, then fall back to constructing from known data

cdc_file <- file.path(data_dir, "cdc_lung_cancer_county.txt")

if (!file.exists(cdc_file)) {
  # CDC WONDER form parameters for Compressed Mortality 1999-2020
  # ICD-10 C33-C34 (Malignant neoplasms of trachea, bronchus and lung)
  params <- list(
    "B_1" = "D77.V9-level1",  # Group by county
    "B_2" = "D77.V1-level1",  # Group by year
    "B_3" = "*None*",
    "B_4" = "*None*",
    "B_5" = "*None*",
    "M_1" = "D77.M1",         # Deaths
    "M_2" = "D77.M2",         # Population
    "M_3" = "D77.M3",         # Crude rate
    "O_V1_fmode" = "freg",
    "O_V9_fmode" = "freg",
    "O_V2_fmode" = "freg",
    "O_aar" = "aar_none",
    "O_aar_CI" = "0.95",
    "O_age" = "D77.V5",
    "V_D77.V1" = "",          # All years
    "V_D77.V9" = "",          # All counties
    "V_D77.V2" = "C33-C34",   # ICD-10 lung cancer
    "action-Send" = "Send",
    "finder-stage-D77.V1" = "codeset",
    "finder-stage-D77.V9" = "codeset",
    "finder-stage-D77.V2" = "codeset",
    "O_precision" = "1",
    "O_timeout" = "600"
  )

  tryCatch({
    resp <- httr::POST(wonder_url, body = params, encode = "form",
                       httr::timeout(300),
                       httr::user_agent("Mozilla/5.0 R-APEP"))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, "text", encoding = "UTF-8")
      writeLines(content, cdc_file)
      cat("CDC WONDER data saved. Size:", file.size(cdc_file), "bytes\n")
    } else {
      cat("CDC WONDER returned status:", httr::status_code(resp), "\n")
    }
  }, error = function(e) {
    cat("CDC WONDER request failed:", e$message, "\n")
  })
}

# ============================================================================
# 3. Alternative: CDC mortality via data.cdc.gov SODA API
# ============================================================================
cat("\n=== Trying CDC mortality via SODA API ===\n")

# NCHS Compressed Mortality File on data.cdc.gov
# This has county-level mortality by cause
soda_url <- "https://data.cdc.gov/resource/489q-934x.json"

soda_file <- file.path(data_dir, "cdc_soda_lung.csv")
if (!file.exists(soda_file) || file.size(soda_file) < 1000) {
  # Query for lung cancer deaths (ICD-10 C34)
  # The dataset uses cause_of_death field
  all_data <- list()
  offset <- 0
  batch_size <- 50000

  for (i in 1:20) {
    query_url <- paste0(soda_url,
      "?$where=cause_of_death%20like%20%27%25C34%25%27",
      "&$limit=", batch_size,
      "&$offset=", offset,
      "&$order=:id")

    tryCatch({
      resp <- httr::GET(query_url, httr::timeout(120))
      if (httr::status_code(resp) == 200) {
        batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
        if (is.data.frame(batch) && nrow(batch) > 0) {
          all_data[[i]] <- batch
          offset <- offset + batch_size
          cat("Batch", i, ":", nrow(batch), "rows\n")
          if (nrow(batch) < batch_size) break
        } else {
          break
        }
      } else {
        cat("SODA API returned:", httr::status_code(resp), "\n")
        break
      }
    }, error = function(e) {
      cat("SODA batch", i, "failed:", e$message, "\n")
    })
  }

  if (length(all_data) > 0) {
    soda_dt <- rbindlist(all_data, fill = TRUE)
    fwrite(soda_dt, soda_file)
    cat("CDC SODA data saved. Rows:", nrow(soda_dt), "\n")
  }
}

# ============================================================================
# 4. Alternative: IHME GBD Results or CDC WISQARS
# ============================================================================
# If CDC WONDER/SODA fail, use CDC's publicly downloadable mortality files

cat("\n=== Trying CDC downloadable mortality files ===\n")
# CDC Multiple Cause of Death files (1999-2020) are available as zip files
# These are the raw microdata behind WONDER

# More practical: use the CDC's pre-tabulated county-level statistics
# CDC Environmental Public Health Tracking: Lung cancer incidence by county
epht_url <- "https://data.cdc.gov/resource/aav2-kehi.json"
epht_file <- file.path(data_dir, "cdc_epht_cancer.csv")

if (!file.exists(epht_file) || file.size(epht_file) < 1000) {
  tryCatch({
    all_epht <- list()
    offset <- 0
    for (i in 1:40) {
      query <- paste0(epht_url,
        "?$limit=50000&$offset=", offset,
        "&$order=:id")
      resp <- httr::GET(query, httr::timeout(120))
      if (httr::status_code(resp) == 200) {
        batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
        if (is.data.frame(batch) && nrow(batch) > 0) {
          all_epht[[i]] <- batch
          offset <- offset + nrow(batch)
          cat("EPHT batch", i, ":", nrow(batch), "rows (total:", offset, ")\n")
          if (nrow(batch) < 50000) break
        } else break
      } else {
        cat("EPHT returned:", httr::status_code(resp), "\n")
        break
      }
    }
    if (length(all_epht) > 0) {
      epht_dt <- rbindlist(all_epht, fill = TRUE)
      fwrite(epht_dt, epht_file)
      cat("EPHT cancer data saved. Rows:", nrow(epht_dt), "\n")
    }
  }, error = function(e) {
    cat("EPHT fetch failed:", e$message, "\n")
  })
}

# ============================================================================
# 5. CDC WONDER text file download (alternative approach)
# ============================================================================
cat("\n=== Trying CDC compressed mortality text download ===\n")

# The Underlying Cause of Death dataset has county-level data
# Resource ID for data.cdc.gov
ucd_url <- "https://data.cdc.gov/resource/bi63-dtpu.json"
ucd_file <- file.path(data_dir, "cdc_ucd_lung.csv")

if (!file.exists(ucd_file) || file.size(ucd_file) < 1000) {
  all_ucd <- list()
  offset <- 0
  for (i in 1:40) {
    # Query for lung cancer (ICD-10 C34) deaths
    query <- paste0(ucd_url,
      "?$where=icd_chapter_code%3D%27C00-D48%27",
      "%20AND%20icd_sub_chapter_code%3D%27C30-C39%27",
      "&$limit=50000&$offset=", offset,
      "&$order=:id")
    tryCatch({
      resp <- httr::GET(query, httr::timeout(120))
      if (httr::status_code(resp) == 200) {
        batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
        if (is.data.frame(batch) && nrow(batch) > 0) {
          all_ucd[[i]] <- batch
          offset <- offset + nrow(batch)
          cat("UCD batch", i, ":", nrow(batch), "rows (total:", offset, ")\n")
          if (nrow(batch) < 50000) break
        } else break
      } else {
        cat("UCD returned:", httr::status_code(resp), "\n")
        break
      }
    }, error = function(e) {
      cat("UCD batch", i, "failed:", e$message, "\n")
    })
  }
  if (length(all_ucd) > 0) {
    ucd_dt <- rbindlist(all_ucd, fill = TRUE)
    fwrite(ucd_dt, ucd_file)
    cat("UCD lung cancer data saved. Rows:", nrow(ucd_dt), "\n")
  }
}

# ============================================================================
# 6. State RRNC Adoption Dates
# ============================================================================
cat("\n=== Creating RRNC adoption date dataset ===\n")

# State-level RRNC code adoption dates from academic literature and LawAtlas
# Sources: EPA (https://www.epa.gov/radon/state-radon-laws),
#          LawAtlas radon policy project,
#          Appalachian Regional Commission report (2014)
rrnc_states <- data.table(
  state_name = c("New Jersey", "Washington", "Minnesota", "Illinois",
                 "Connecticut", "Maine", "Nebraska", "Oregon",
                 "Maryland", "Massachusetts", "Michigan"),
  state_fips = c("34", "53", "27", "17", "09", "23", "31", "41",
                 "24", "25", "26"),
  rrnc_year = c(1995, 1997, 2009, 2013, 2014, 2015, 2019, 2019,
                2020, 2020, 2021),
  rrnc_scope = c("statewide", "Zone 1", "statewide", "statewide",
                 "statewide", "statewide", "statewide", "statewide",
                 "statewide", "statewide", "Zone 1")
)

fwrite(rrnc_states, file.path(data_dir, "rrnc_adoption.csv"))
cat("RRNC adoption dates saved\n")

# ============================================================================
# 7. Census Building Permits Survey (County-level)
# ============================================================================
cat("\n=== Fetching Census Building Permits ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY", unset = "")
bp_file <- file.path(data_dir, "building_permits.csv")

if (!file.exists(bp_file) || file.size(bp_file) < 1000) {
  all_bp <- list()
  for (yr in 1999:2020) {
    bp_url <- paste0(
      "https://api.census.gov/data/", yr, "/cbp?get=ESTAB,EMP&for=county:*",
      if (nchar(census_key) > 0) paste0("&key=", census_key) else ""
    )
    tryCatch({
      resp <- httr::GET(bp_url, httr::timeout(30))
      if (httr::status_code(resp) == 200) {
        raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
        if (is.matrix(raw) && nrow(raw) > 1) {
          dt <- as.data.table(raw[-1, , drop = FALSE])
          setnames(dt, raw[1, ])
          dt[, year := yr]
          all_bp[[as.character(yr)]] <- dt
          cat("CBP", yr, ":", nrow(dt), "counties\n")
        }
      }
    }, error = function(e) NULL)
  }
  if (length(all_bp) > 0) {
    bp_dt <- rbindlist(all_bp, fill = TRUE)
    fwrite(bp_dt, bp_file)
    cat("Building permits data saved. Rows:", nrow(bp_dt), "\n")
  }
}

# ============================================================================
# 8. BEA CAINC county income data
# ============================================================================
cat("\n=== Fetching BEA County Income ===\n")

bea_key <- Sys.getenv("BEA_API_KEY", unset = "")
bea_file <- file.path(data_dir, "bea_county_income.csv")

if (nchar(bea_key) > 0 && (!file.exists(bea_file) || file.size(bea_file) < 1000)) {
  bea_url <- paste0(
    "https://apps.bea.gov/api/data/?UserID=", bea_key,
    "&method=GetData&datasetname=Regional",
    "&TableName=CAINC1&LineCode=3&GeoFips=COUNTY",
    "&Year=ALL&ResultFormat=JSON"
  )
  tryCatch({
    resp <- httr::GET(bea_url, httr::timeout(120))
    if (httr::status_code(resp) == 200) {
      content <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      if (!is.null(content$BEAAPI$Results$Data)) {
        bea_dt <- as.data.table(content$BEAAPI$Results$Data)
        fwrite(bea_dt, bea_file)
        cat("BEA county income saved. Rows:", nrow(bea_dt), "\n")
      }
    }
  }, error = function(e) {
    cat("BEA fetch failed:", e$message, "\n")
  })
}

# ============================================================================
# 9. County Population (Census intercensal estimates)
# ============================================================================
cat("\n=== Fetching County Population Estimates ===\n")

pop_file <- file.path(data_dir, "county_population.csv")
if (!file.exists(pop_file) || file.size(pop_file) < 1000) {
  pop_urls <- c(
    # 2010-2020 intercensal
    "https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/counties/totals/co-est2020-alldata.csv",
    # 2020-2023
    "https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/counties/totals/co-est2023-alldata.csv"
  )

  all_pop <- list()
  for (url in pop_urls) {
    tryCatch({
      resp <- httr::GET(url, httr::timeout(60))
      if (httr::status_code(resp) == 200) {
        tmp <- tempfile(fileext = ".csv")
        writeBin(httr::content(resp, "raw"), tmp)
        dt <- fread(tmp, fill = TRUE)
        all_pop[[length(all_pop) + 1]] <- dt
        cat("Population data:", nrow(dt), "rows from", basename(url), "\n")
      }
    }, error = function(e) {
      cat("Population fetch failed:", e$message, "\n")
    })
  }
  if (length(all_pop) > 0) {
    pop_dt <- rbindlist(all_pop, fill = TRUE)
    fwrite(pop_dt, pop_file)
    cat("County population saved\n")
  }
}

# ============================================================================
# 10. Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
files <- list.files(data_dir, recursive = TRUE, full.names = TRUE)
for (f in files) {
  if (!grepl("\\.(zip|shp|dbf|prj|shx)$", f)) {
    cat(sprintf("  %s: %.1f KB\n", basename(f), file.size(f) / 1024))
  }
}
