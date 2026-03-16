## 01_fetch_data.R — Download all data for apep_0700
## UK LHA Freeze and Homelessness in England
## Sources: Cambridgeshire Insight (LHA rates), MHCLG (homelessness), NOMIS (controls)

source("00_packages.R")
setwd("../data")

cat("=== Downloading data for apep_0700 ===\n")

## -----------------------------------------------------------------------
## 1. LHA rates by BRMA (Cambridgeshire Insight — all years in one CSV)
## -----------------------------------------------------------------------
lha_url <- "https://data.cambridgeshireinsight.org.uk/sites/default/files/lha-rates-weekly-all-years-open.csv"
cat("Downloading LHA rates...\n")
tryCatch({
  download.file(lha_url, "lha_rates_all_years.csv", mode = "wb", quiet = TRUE)
  lha_raw <- fread("lha_rates_all_years.csv")
  cat("  LHA rates:", nrow(lha_raw), "rows,", ncol(lha_raw), "cols\n")
  cat("  Columns:", paste(names(lha_raw), collapse = ", "), "\n")
  stopifnot(nrow(lha_raw) > 0)
}, error = function(e) {
  stop("FATAL: Failed to download LHA rates CSV: ", e$message)
})

## -----------------------------------------------------------------------
## 2. Homelessness — Table 784 (annual, LA-level, 2004-2018)
## -----------------------------------------------------------------------
t784_url <- "https://assets.publishing.service.gov.uk/media/5c1133c6e5274a0bfc8a70f4/Table_784_2017_18.xlsx"
cat("Downloading Table 784 (annual homelessness)...\n")
tryCatch({
  download.file(t784_url, "table_784.xlsx", mode = "wb", quiet = TRUE)
  cat("  Table 784 downloaded.\n")
  stopifnot(file.exists("table_784.xlsx"))
}, error = function(e) {
  stop("FATAL: Failed to download Table 784: ", e$message)
})

## -----------------------------------------------------------------------
## 3. Homelessness — Table 784a (quarterly, LA-level, 2014Q2-2018Q1)
## -----------------------------------------------------------------------
t784a_url <- "https://assets.publishing.service.gov.uk/media/5c1133dbe5274a0ad4ea6629/Table_784a_201803.xlsx"
cat("Downloading Table 784a (quarterly homelessness)...\n")
tryCatch({
  download.file(t784a_url, "table_784a.xlsx", mode = "wb", quiet = TRUE)
  cat("  Table 784a downloaded.\n")
  stopifnot(file.exists("table_784a.xlsx"))
}, error = function(e) {
  stop("FATAL: Failed to download Table 784a: ", e$message)
})

## -----------------------------------------------------------------------
## 4. H-CLIC detailed LA data (post-2018)
## -----------------------------------------------------------------------
# Annual detailed file for 2024-25
hclic_url <- "https://assets.publishing.service.gov.uk/media/6925ff49aca6213a492dd0a1/Statutory_Homelessness_Detailed_Local_Authority_Data_2024-2025.ods"
cat("Downloading H-CLIC detailed LA data (2024-25)...\n")
tryCatch({
  download.file(hclic_url, "hclic_detailed_2024_25.ods", mode = "wb", quiet = TRUE)
  cat("  H-CLIC detailed data downloaded.\n")
}, error = function(e) {
  cat("  Warning: Could not download H-CLIC 2024-25 data: ", e$message, "\n")
  cat("  Continuing with Table 784a as primary source.\n")
})

## -----------------------------------------------------------------------
## 5. Temporary accommodation (quarterly, up to 2018Q1)
## -----------------------------------------------------------------------
ta_url <- "https://assets.publishing.service.gov.uk/media/5d00bd40e5274a3d4b416479/Temporary_accommodation2018Q1.xlsx"
cat("Downloading Temporary Accommodation data...\n")
tryCatch({
  download.file(ta_url, "temp_accommodation.xlsx", mode = "wb", quiet = TRUE)
  cat("  TA data downloaded.\n")
}, error = function(e) {
  cat("  Warning: Could not download TA data: ", e$message, "\n")
})

## -----------------------------------------------------------------------
## 6. NOMIS — Claimant count by LA (monthly, for controls)
## -----------------------------------------------------------------------
cat("Downloading NOMIS claimant count data...\n")
# NM_162_1: Claimant count (Jobseeker's Allowance + UC) by LA
# Geography TYPE464 = English local authority districts
nomis_base <- "https://www.nomisweb.co.uk/api/v01/dataset/NM_162_1.data.csv"
nomis_params <- paste0(
  "?geography=TYPE464",
  "&date=2013-01...2023-12",
  "&gender=0",        # Total
  "&age=0",           # All ages
  "&measure=1",       # Claimants
  "&measures=20100",  # Value
  "&select=date_name,geography_name,geography_code,obs_value"
)
tryCatch({
  download.file(paste0(nomis_base, nomis_params), "nomis_claimant_count.csv",
                mode = "wb", quiet = TRUE)
  cc <- fread("nomis_claimant_count.csv")
  cat("  Claimant count:", nrow(cc), "rows\n")
  stopifnot(nrow(cc) > 100)
}, error = function(e) {
  stop("FATAL: Failed to download NOMIS claimant count: ", e$message)
})

## -----------------------------------------------------------------------
## 7. BRMA boundary shapefiles (for BRMA-to-LA spatial mapping)
## -----------------------------------------------------------------------
cat("Downloading BRMA boundary shapefiles...\n")
brma_shp_url <- "https://data.cambridgeshireinsight.org.uk/sites/default/files/BRMA_England_0412_0.zip"
tryCatch({
  download.file(brma_shp_url, "brma_boundaries.zip", mode = "wb", quiet = TRUE)
  unzip("brma_boundaries.zip", exdir = "brma_shp")
  cat("  BRMA shapefiles extracted.\n")
}, error = function(e) {
  cat("  Warning: Could not download BRMA shapefiles: ", e$message, "\n")
  cat("  Will construct mapping from names.\n")
})

## -----------------------------------------------------------------------
## 8. LA boundary shapefiles (ONS Open Geography Portal)
## -----------------------------------------------------------------------
cat("Downloading LA boundary shapefiles...\n")
# Local Authority Districts (December 2019) — Generalised Clipped boundaries
la_shp_url <- "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/910f48f3c4b3400aa9eb0af9f44460e3/shapefile?layers=0"
tryCatch({
  download.file(la_shp_url, "la_boundaries.zip", mode = "wb", quiet = TRUE)
  unzip("la_boundaries.zip", exdir = "la_shp")
  cat("  LA shapefiles extracted.\n")
}, error = function(e) {
  cat("  Warning: Could not download LA shapefiles: ", e$message, "\n")
  # Fallback: we'll construct the mapping from name matching
})

cat("\n=== All downloads complete ===\n")
cat("Files in data directory:\n")
print(list.files(recursive = TRUE))

setwd("../code")
