## ── 01_fetch_data.R ────────────────────────────────────────────────
## Fetch and validate data for apep_1294
## ST reservation rotation and deforestation in India
## ────────────────────────────────────────────────────────────────────
source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ── 1. Load SHRUG district-level data ──────────────────────────────
shrug_dir <- file.path("..", "..", "..", "data", "india_shrug")
stopifnot("SHRUG data directory missing" = dir.exists(shrug_dir))

## Census PCA (district level) — has ST population
pca <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.tab"))
cat("Census PCA loaded:", nrow(pca), "districts\n")
stopifnot("PCA data is empty" = nrow(pca) > 0)

## Nightlights (district-year level)
nl <- fread(file.path(shrug_dir, "dmsp_pc11dist.tab"))
cat("Nightlights loaded:", nrow(nl), "district-year obs\n")
stopifnot("Nightlights data is empty" = nrow(nl) > 0)

## ── 2. Construct district-level ST share ───────────────────────────
## ST population share from Census 2011 (predetermined — 2001 Census
## determined 2008 delimitation; 2011 is the nearest available)
pca[, st_share := pc11_pca_p_st / pc11_pca_tot_p]
pca[, sc_share := pc11_pca_p_sc / pc11_pca_tot_p]
pca[, dist_id := paste0(pc11_state_id, "_", pc11_district_id)]

## Summary
cat("\nST share distribution:\n")
print(summary(pca$st_share))
cat("SC share distribution:\n")
print(summary(pca$sc_share))
cat("Districts with ST share > 0:", sum(pca$st_share > 0, na.rm = TRUE), "\n")
cat("Districts with ST share > 0.20:", sum(pca$st_share > 0.20, na.rm = TRUE), "\n")

## ── 3. Download district-level forest cover loss (Hansen GFC) ──────
## Try GADM + GFC via terra for a clean spatial approach.
## Fallback: use FSI data from web or pre-computed GFW downloads.

## First try: download pre-computed GFC district-level data from GFW
## GFW provides bulk country downloads with subnational breakdowns
cat("\nAttempting to download India forest loss data from GFW...\n")

## GFW hosts pre-computed subnational datasets on their data portal
## Using the GFW GLAD dataset API
gfw_url <- "https://gfw2-data.s3.amazonaws.com/country-pages/country_stats/download/IND.json"
resp <- tryCatch(
  httr::GET(gfw_url, httr::timeout(30)),
  error = function(e) NULL
)

## Also try alternative: GFW country stats CSV
gfw_csv_url <- "https://gfw2-data.s3.amazonaws.com/country-pages/country_stats/download/IND.csv"
resp_csv <- tryCatch(
  httr::GET(gfw_csv_url, httr::timeout(30)),
  error = function(e) NULL
)

forest_data_obtained <- FALSE

## Try GFW JSON
if (!is.null(resp) && httr::status_code(resp) == 200) {
  cat("GFW country JSON downloaded successfully\n")
  gfw_data <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  saveRDS(gfw_data, file.path(data_dir, "gfw_india.rds"))
  forest_data_obtained <- TRUE
}

## Try GFW CSV
if (!forest_data_obtained && !is.null(resp_csv) && httr::status_code(resp_csv) == 200) {
  cat("GFW country CSV downloaded successfully\n")
  writeBin(httr::content(resp_csv, "raw"), file.path(data_dir, "gfw_india.csv"))
  forest_data_obtained <- TRUE
}

## Alternative: Download Hansen GFC lossyear tile for central India
## This covers the most forested (and ST-dense) part of India
if (!forest_data_obtained) {
  cat("\nGFW download failed. Trying Hansen GFC tile (central India: 20N_080E)...\n")

  ## Check if terra is available for raster processing
  has_terra <- requireNamespace("terra", quietly = TRUE)
  has_sf <- requireNamespace("sf", quietly = TRUE)

  if (has_terra && has_sf) {
    cat("R terra and sf packages available. Downloading GFC tile...\n")

    ## Download lossyear tile for 20N_080E (covers MP, CG, Odisha, Jharkhand)
    ## These are the most ST-dense and forested districts
    gfc_url <- "https://storage.googleapis.com/earthenginepartners-hansen/GFC-2023-v1.11/Hansen_GFC-2023-v1.11_lossyear_20N_080E.tif"
    gfc_file <- file.path(data_dir, "lossyear_20N_080E.tif")

    if (!file.exists(gfc_file)) {
      cat("Downloading GFC lossyear tile (~400MB)...\n")
      dl_result <- tryCatch(
        download.file(gfc_url, gfc_file, mode = "wb", timeout = 600),
        error = function(e) {
          cat("GFC download failed:", conditionMessage(e), "\n")
          1L
        }
      )
      if (dl_result == 0) {
        cat("GFC tile downloaded successfully:", file.size(gfc_file), "bytes\n")
        forest_data_obtained <- TRUE
      }
    } else {
      cat("GFC tile already exists:", file.size(gfc_file), "bytes\n")
      forest_data_obtained <- TRUE
    }
  } else {
    cat("terra/sf not available. Installing...\n")
    install.packages(c("terra", "sf"), repos = "https://cloud.r-project.org")
    cat("Installed terra/sf. Re-run to process GFC data.\n")
  }
}

## ── 4. Download GADM district boundaries if we got GFC ─────────────
if (forest_data_obtained && exists("gfc_file") && file.exists(gfc_file)) {
  cat("\nDownloading GADM India district boundaries...\n")

  ## GADM provides admin boundaries via geodata package or direct URL
  gadm_file <- file.path(data_dir, "gadm_india_2.rds")

  if (!file.exists(gadm_file)) {
    ## Try geodata package first
    if (requireNamespace("geodata", quietly = TRUE)) {
      library(geodata)
      india_districts <- gadm(country = "IND", level = 2, path = data_dir)
      saveRDS(india_districts, gadm_file)
      cat("GADM boundaries downloaded via geodata\n")
    } else {
      ## Direct download from GADM
      gadm_url <- "https://geodata.ucdavis.edu/gadm/gadm4.1/Rsf/gadm41_IND_2_pk.rds"
      dl <- tryCatch(
        download.file(gadm_url, gadm_file, mode = "wb", timeout = 120),
        error = function(e) {
          cat("GADM download failed:", conditionMessage(e), "\n")
          1L
        }
      )
      if (dl == 0) cat("GADM boundaries downloaded directly\n")
    }
  } else {
    cat("GADM boundaries already cached\n")
  }
}

## ── 5. Build primary analysis dataset ──────────────────────────────

## District-year nightlights panel
nl[, dist_id := paste0(pc11_state_id, "_", pc11_district_id)]

## Merge nightlights with ST/SC shares
panel <- merge(nl, pca[, .(dist_id, st_share, sc_share,
                            pc11_pca_tot_p, pc11_pca_p_st, pc11_pca_p_sc)],
               by = "dist_id", all.x = TRUE)

## Drop if missing population
panel <- panel[!is.na(pc11_pca_tot_p) & pc11_pca_tot_p > 0]

## Create treatment variables
panel[, post2008 := as.integer(year >= 2008)]

## Treatment intensity: ST share × Post2008
panel[, treat_st := st_share * post2008]
panel[, treat_sc := sc_share * post2008]  # SC placebo

## High ST indicator (top quartile of ST share)
st_q75 <- quantile(panel$st_share, 0.75, na.rm = TRUE)
panel[, high_st := as.integer(st_share >= st_q75)]
panel[, treat_high_st := high_st * post2008]

## Log nightlights (adding 1 to handle zeros)
panel[, log_nl := log(dmsp_total_light_cal + 1)]
panel[, log_mean_nl := log(dmsp_mean_light_cal + 0.01)]

## Year range
cat("\nPanel summary:\n")
cat("Year range:", range(panel$year), "\n")
cat("Districts:", uniqueN(panel$dist_id), "\n")
cat("Observations:", nrow(panel), "\n")
cat("Pre-2008 obs:", sum(panel$year < 2008), "\n")
cat("Post-2008 obs:", sum(panel$year >= 2008), "\n")

## ── 6. Save analysis-ready dataset ────────────────────────────────
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")

## ── 7. Summary statistics for validation ───────────────────────────
cat("\n--- Validation Summary ---\n")
cat("Districts with ST > 0:", uniqueN(panel[st_share > 0]$dist_id), "\n")
cat("Districts with ST > 0.20:", uniqueN(panel[st_share > 0.20]$dist_id), "\n")
cat("Mean nightlights (pre-2008):", mean(panel[year < 2008]$dmsp_total_light_cal, na.rm = TRUE), "\n")
cat("Mean nightlights (post-2008):", mean(panel[year >= 2008]$dmsp_total_light_cal, na.rm = TRUE), "\n")
