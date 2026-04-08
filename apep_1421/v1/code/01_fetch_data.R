## ── 01_fetch_data.R ────────────────────────────────────────────
## Load SHRUG district-level data for DMF analysis
## All data from local SHRUG files (Harvard Dataverse)
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

shrug_dir <- "../../../../data/india_shrug"
out_dir   <- "../data"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## ── VIIRS nightlights (2012-2021) ──────────────────────────────
viirs <- fread(file.path(shrug_dir, "viirs_pc11dist.tab"))
cat("VIIRS rows:", nrow(viirs), "| Districts:", uniqueN(viirs$pc11_district_id),
    "| Years:", paste(sort(unique(viirs$year)), collapse = ","), "\n")
stopifnot(nrow(viirs) > 0, "year" %in% names(viirs))

# Keep median-masked category (standard in SHRUG)
viirs <- viirs[category == "median-masked"]
cat("After median-masked filter:", nrow(viirs), "rows\n")

## ── Economic Census 2013 (mining employment) ──────────────────
ec13 <- fread(file.path(shrug_dir, "ec13_pc11dist.tab"))
cat("EC13 rows:", nrow(ec13), "\n")
stopifnot(nrow(ec13) > 0)

## ── Census 2011 PCA (population, literacy, workforce) ─────────
pca <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.tab"))
cat("PCA rows:", nrow(pca), "\n")
stopifnot(nrow(pca) > 0)

## ── Geographic crosswalk (district → state mapping) ───────────
td <- fread(file.path(shrug_dir, "pc11_td_clean_pc11dist.tab"))
cat("TD rows:", nrow(td), "\n")
stopifnot(nrow(td) > 0)

## ── Save raw data ──────────────────────────────────────────────
saveRDS(viirs, file.path(out_dir, "viirs_raw.rds"))
saveRDS(ec13,  file.path(out_dir, "ec13_raw.rds"))
saveRDS(pca,   file.path(out_dir, "pca_raw.rds"))
saveRDS(td,    file.path(out_dir, "td_raw.rds"))

cat("Data fetch complete. All files are real SHRUG district-level data.\n")
