## =============================================================================
## 01_fetch_data.R — Fetch all data sources for Chile voting reform paper
## apep_0571
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------------------
## 1. DMCS crime data from datos.gob.cl (2010-2012, monthly, comuna level)
## ---------------------------------------------------------------------------
cat("=== Downloading DMCS 2010-2012 from datos.gob.cl ===\n")
dmcs_url <- "https://datos.gob.cl/uploads/recursos/Estadistico%20Delitos%20de%20Mayor%20Connotacion%20Social%20-%20VIF%20-%20Ley%20de%20Drogas.xlsx"
dmcs_file <- file.path(data_dir, "dmcs_2010_2012.xlsx")
if (!file.exists(dmcs_file)) {
  tryCatch({
    download.file(dmcs_url, dmcs_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded:", dmcs_file, "\n")
  }, error = function(e) stop("DMCS 2010-2012 download failed: ", e$message))
}
stopifnot("DMCS 2010-2012 file missing" = file.exists(dmcs_file))

# Parse the complex xlsx into a clean CSV using Python/openpyxl
# (R's read_excel cannot handle the pivoted monthly-block structure)
dmcs_clean <- file.path(data_dir, "dmcs_2010_2012_clean.csv")
if (!file.exists(dmcs_clean)) {
  cat("  Parsing DMCS xlsx with Python...\n")
  ret <- system2("python3", args = c("parse_dmcs_xlsx.py"), stdout = TRUE, stderr = TRUE)
  cat(paste(ret, collapse = "\n"), "\n")
  if (!file.exists(dmcs_clean)) stop("DMCS parsing failed: dmcs_2010_2012_clean.csv not created")
}
stopifnot("DMCS clean CSV missing" = file.exists(dmcs_clean))

## ---------------------------------------------------------------------------
## 2. CEAD crime data from GitHub (2018-2025, monthly, comuna level)
## ---------------------------------------------------------------------------
cat("=== Downloading CEAD 2018-2025 from GitHub ===\n")
cead_url <- "https://github.com/bastianolea/delincuencia_chile/raw/main/datos_procesados/cead_delincuencia_chile.parquet"
cead_file <- file.path(data_dir, "cead_2018_2025.parquet")
if (!file.exists(cead_file)) {
  tryCatch({
    download.file(cead_url, cead_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded:", cead_file, "\n")
  }, error = function(e) stop("CEAD 2018-2025 download failed: ", e$message))
}
stopifnot("CEAD 2018-2025 file missing" = file.exists(cead_file))

## ---------------------------------------------------------------------------
## 3. CEAD historical crime data (2001-2023) from GitHub raw data
## ---------------------------------------------------------------------------
cat("=== Attempting CEAD historical data from GitHub ===\n")
# The repo has annual aggregated data in delitos_chile.csv
cead_hist_url <- "https://github.com/bastianolea/delincuencia_chile/raw/main/datos_procesados/delitos_chile.csv"
cead_hist_file <- file.path(data_dir, "cead_historical.csv")
if (!file.exists(cead_hist_file)) {
  tryCatch({
    download.file(cead_hist_url, cead_hist_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded historical CSV:", cead_hist_file, "\n")
  }, error = function(e) {
    cat("  WARN: Historical CSV not available:", e$message, "\n")
  })
}

# Also try the commune-level annual data
cead_comuna_url <- "https://github.com/bastianolea/delincuencia_chile/raw/main/datos_procesados/delitos_comunas_chile.csv"
cead_comuna_file <- file.path(data_dir, "cead_comunas_historical.csv")
if (!file.exists(cead_comuna_file)) {
  tryCatch({
    download.file(cead_comuna_url, cead_comuna_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded comuna-level CSV:", cead_comuna_file, "\n")
  }, error = function(e) {
    cat("  WARN: Comuna-level historical CSV not available:", e$message, "\n")
  })
}

## ---------------------------------------------------------------------------
## 4. SERVEL electoral data from Harvard Dataverse (Cox & Gonzalez 2022)
## ---------------------------------------------------------------------------
cat("=== Downloading SERVEL data from Harvard Dataverse ===\n")
servel_url <- "https://dataverse.harvard.edu/api/access/datafile/5810384?format=original"
servel_file <- file.path(data_dir, "servel_participation.dta")
if (!file.exists(servel_file)) {
  tryCatch({
    download.file(servel_url, servel_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded:", servel_file, "\n")
  }, error = function(e) stop("SERVEL data download failed: ", e$message))
}
stopifnot("SERVEL file missing" = file.exists(servel_file))

## ---------------------------------------------------------------------------
## 5. CEAD data from Subsecretaria de Prevencion del Delito (2005-2023)
## ---------------------------------------------------------------------------
cat("=== Attempting CEAD data from SPD ===\n")
# Try various URLs for historical DMCS data
spd_urls <- c(
  "http://cead.spd.gov.cl/wp-content/uploads/file-manager/publicaciones/estadisticas/Frecuencia-DMCS-2005-2023.xlsx",
  "http://cead.spd.gov.cl/wp-content/uploads/Frecuencia-DMCS-Comunal.xlsx",
  "https://cead.spd.gov.cl/wp-content/uploads/estadisticas/dmcs_comunal_2005_2023.xlsx"
)

spd_file <- file.path(data_dir, "cead_spd_historical.xlsx")
spd_downloaded <- FALSE
if (!file.exists(spd_file)) {
  for (url in spd_urls) {
    tryCatch({
      download.file(url, spd_file, mode = "wb", quiet = TRUE)
      if (file.info(spd_file)$size > 1000) {
        cat("  Downloaded SPD data from:", url, "\n")
        spd_downloaded <- TRUE
        break
      } else {
        file.remove(spd_file)
      }
    }, error = function(e) NULL)
  }
  if (!spd_downloaded) cat("  NOTE: SPD historical data not available from tried URLs\n")
}

## ---------------------------------------------------------------------------
## 6. Chile 2002 Census demographics (from INE or alternative)
## ---------------------------------------------------------------------------
cat("=== Fetching Chile 2002 Census commune demographics ===\n")
# Census 2002 pre-computed comuna demographics from SINIM
# SINIM API: https://datos.sinim.gov.cl/
# We'll try to get comuna-level demographics from multiple sources

# Try Harvard Dataverse — Cox & Gonzalez replication data includes demographics
# The file 5810384 (already downloaded) contains comuna-level participation + demographics
# Check if there are additional files in the dataset
servel2_url <- "https://dataverse.harvard.edu/api/access/datafile/5810385?format=original"
servel2_file <- file.path(data_dir, "servel_demographics.dta")
if (!file.exists(servel2_file)) {
  tryCatch({
    download.file(servel2_url, servel2_file, mode = "wb", quiet = TRUE)
    if (file.info(servel2_file)$size > 500) {
      cat("  Downloaded additional Dataverse file:", servel2_file, "\n")
    } else {
      file.remove(servel2_file)
    }
  }, error = function(e) cat("  NOTE: Additional Dataverse file not available\n"))
}

## ---------------------------------------------------------------------------
## 7. SINIM municipal budget data
## ---------------------------------------------------------------------------
cat("=== Fetching SINIM municipal budget data ===\n")
# SINIM API endpoint for municipal budgets
# Variable 881 = Gasto en Seguridad Ciudadana (public safety spending)
# We'll try a couple of approaches

sinim_url <- "https://datos.sinim.gov.cl/storage/datos/2023.csv"
sinim_file <- file.path(data_dir, "sinim_2023.csv")
if (!file.exists(sinim_file)) {
  tryCatch({
    download.file(sinim_url, sinim_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded SINIM 2023:", sinim_file, "\n")
  }, error = function(e) cat("  NOTE: SINIM direct download not available\n"))
}

## ---------------------------------------------------------------------------
## 8. INE population data by comuna (for crime rates per 100K)
## ---------------------------------------------------------------------------
cat("=== Fetching INE population estimates ===\n")
# INE Chile commune population projections
ine_pop_url <- "https://www.ine.gob.cl/docs/default-source/proyecciones-de-poblacion/cuadros-estadisticos/base-2017/ine_estimaciones-y-proyecciones-2002-2035_base-2017_comunas.csv"
ine_pop_file <- file.path(data_dir, "ine_population_comunas.csv")
if (!file.exists(ine_pop_file)) {
  tryCatch({
    download.file(ine_pop_url, ine_pop_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded INE population:", ine_pop_file, "\n")
  }, error = function(e) {
    cat("  NOTE: INE population download failed, trying alternative\n")
    # Alternative: from datos.gob.cl
    alt_url <- "https://datos.gob.cl/dataset/estimaciones-y-proyecciones-de-poblacion"
    cat("  NOTE: May need manual download from datos.gob.cl\n")
  })
}

## ===========================================================================
## VALIDATION
## ===========================================================================
cat("\n=== DATA VALIDATION ===\n")

# Check critical files exist
critical_files <- c(dmcs_file, cead_file, servel_file)
for (f in critical_files) {
  if (!file.exists(f)) stop("Critical file missing: ", f)
  cat("  OK:", basename(f), "-", file.info(f)$size, "bytes\n")
}

# Quick peek at each
cat("\n--- DMCS 2010-2012 ---\n")
sheets <- readxl::excel_sheets(dmcs_file)
cat("  Sheets:", paste(sheets, collapse=", "), "\n")

cat("\n--- CEAD 2018-2025 ---\n")
cead_df <- arrow::read_parquet(cead_file)
cat("  Rows:", nrow(cead_df), "\n")
cat("  Comunas:", n_distinct(cead_df$comuna), "\n")
cat("  Date range:", as.character(min(cead_df$fecha)), "to", as.character(max(cead_df$fecha)), "\n")
cat("  Crime types:", n_distinct(cead_df$delito), "\n")

cat("\n--- SERVEL ---\n")
servel_df <- haven::read_dta(servel_file)
cat("  Comunas:", n_distinct(servel_df$comuna), "\n")
cat("  Columns:", paste(names(servel_df), collapse=", "), "\n")

# Check historical data availability
cat("\n--- Historical data availability ---\n")
hist_files <- c(cead_hist_file, cead_comuna_file, spd_file)
for (f in hist_files) {
  if (file.exists(f)) {
    cat("  FOUND:", basename(f), "-", file.info(f)$size, "bytes\n")
  } else {
    cat("  MISSING:", basename(f), "\n")
  }
}

cat("\nData fetch complete.\n")
