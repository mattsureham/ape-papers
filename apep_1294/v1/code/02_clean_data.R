## ── 02_clean_data.R ────────────────────────────────────────────────
## Process Hansen GFC tiles + GADM boundaries → district-level forest loss
## Download multiple tiles to cover all of India
## ────────────────────────────────────────────────────────────────────
source("code/00_packages.R")
library(terra)
library(sf)

data_dir <- "data"

## ── 1. Download all GFC tiles covering India ��──────────────────────
## India spans roughly 8°N-35°N, 68°E-97°E
## GFC tiles are 10° × 10° blocks named by upper-left corner
tiles <- c("10N_070E", "10N_080E", "10N_090E",
           "20N_070E", "20N_080E", "20N_090E",
           "30N_070E", "30N_080E", "30N_090E")

base_url <- "https://storage.googleapis.com/earthenginepartners-hansen/GFC-2023-v1.11"

## Download lossyear tiles
cat("Downloading Hansen GFC lossyear tiles for India...\n")
loss_files <- c()
for (tile in tiles) {
  fname <- paste0("Hansen_GFC-2023-v1.11_lossyear_", tile, ".tif")
  fpath <- file.path(data_dir, fname)
  if (!file.exists(fpath)) {
    url <- paste0(base_url, "/", fname)
    dl <- tryCatch(
      download.file(url, fpath, mode = "wb", timeout = 300, quiet = TRUE),
      error = function(e) { cat("  SKIP", tile, ":", conditionMessage(e), "\n"); 1L }
    )
    if (dl == 0) {
      cat("  Downloaded:", tile, "(", round(file.size(fpath) / 1e6, 1), "MB)\n")
      loss_files <- c(loss_files, fpath)
    }
  } else {
    cat("  Cached:", tile, "\n")
    loss_files <- c(loss_files, fpath)
  }
}

## Download treecover2000 tiles
cat("\nDownloading Hansen GFC treecover2000 tiles...\n")
tc_files <- c()
for (tile in tiles) {
  fname <- paste0("Hansen_GFC-2023-v1.11_treecover2000_", tile, ".tif")
  fpath <- file.path(data_dir, fname)
  if (!file.exists(fpath)) {
    url <- paste0(base_url, "/", fname)
    dl <- tryCatch(
      download.file(url, fpath, mode = "wb", timeout = 300, quiet = TRUE),
      error = function(e) { cat("  SKIP", tile, ":", conditionMessage(e), "\n"); 1L }
    )
    if (dl == 0) {
      cat("  Downloaded:", tile, "(", round(file.size(fpath) / 1e6, 1), "MB)\n")
      tc_files <- c(tc_files, fpath)
    }
  } else {
    cat("  Cached:", tile, "\n")
    tc_files <- c(tc_files, fpath)
  }
}

cat("\nLossyear tiles:", length(loss_files), "\n")
cat("Treecover tiles:", length(tc_files), "\n")

## ── 2. Load GADM district boundaries ──────────────────────────────
gadm_candidates <- list.files(data_dir, pattern = "gadm.*IND.*\\.rds$",
                              recursive = TRUE, full.names = TRUE)
if (length(gadm_candidates) == 0) {
  stop("GADM boundary file not found. Run 01_fetch_data.R first.")
}
gadm_file <- gadm_candidates[1]
cat("Using GADM file:", gadm_file, "\n")

gadm <- readRDS(gadm_file)
if (inherits(gadm, "SpatVector")) {
  gadm_vect <- gadm
} else if (inherits(gadm, "sf")) {
  gadm_vect <- vect(gadm)
} else {
  gadm_vect <- vect(gadm)
}
cat("GADM districts:", nrow(gadm_vect), "\n")

## ── 3. Process lossyear: extract district-level annual forest loss ─
## Process tile-by-tile with aggregation to manage memory
## Aggregate 30m to 300m (factor 10) before extraction
## Each aggregated pixel represents ~100 original pixels = 9 hectares
agg_factor <- 10
pixel_area_ha <- 0.09 * agg_factor^2  # 9 ha per aggregated pixel

all_loss <- data.table()

for (i in seq_along(loss_files)) {
  tile_name <- gsub(".*lossyear_(.+)\\.tif", "\\1", loss_files[i])
  cat("Processing lossyear tile", tile_name, "...\n")

  r <- rast(loss_files[i])

  ## Crop to India extent first (reduces data volume)
  r_crop <- tryCatch(crop(r, ext(gadm_vect)), error = function(e) NULL)
  if (is.null(r_crop) || ncell(r_crop) == 0) {
    cat("  No overlap with India boundaries, skipping\n")
    rm(r); gc(verbose = FALSE)
    next
  }

  ## Process year-by-year to extract loss counts per district
  ## For each year Y (1-23), count aggregated pixels with lossyear == Y
  years_in_tile <- sort(unique(values(r_crop)[values(r_crop) > 0]))
  if (length(years_in_tile) == 0) {
    cat("  No forest loss in this tile\n")
    rm(r, r_crop); gc(verbose = FALSE)
    next
  }

  tile_results <- data.table()
  for (yr in years_in_tile) {
    ## Create binary mask for this year
    yr_mask <- (r_crop == yr)

    ## Aggregate: sum of loss pixels in each 10x10 block
    yr_agg <- aggregate(yr_mask, fact = agg_factor, fun = "sum", na.rm = TRUE)

    ## Extract sum per district (total loss pixels)
    ex <- extract(yr_agg, gadm_vect, fun = "sum", na.rm = TRUE, ID = TRUE)
    setDT(ex)
    names(ex) <- c("ID", "n_loss_agg")
    ex <- ex[n_loss_agg > 0]

    if (nrow(ex) > 0) {
      ex[, year := yr + 2000]
      ## Convert aggregated pixel count to hectares
      ## Each aggregated pixel = agg_factor^2 original pixels = agg_factor^2 * 0.09 ha
      ## But we summed the original pixel counts within blocks
      ex[, loss_ha := n_loss_agg * 0.09]
      tile_results <- rbind(tile_results, ex[, .(ID, year, loss_ha)])
    }

    rm(yr_mask, yr_agg, ex)
  }

  if (nrow(tile_results) > 0) {
    tile_results[, tile := tile_name]
    all_loss <- rbind(all_loss, tile_results)
    cat("  Found", nrow(tile_results), "district-year loss observations\n")
  }

  rm(r, r_crop, tile_results)
  gc(verbose = FALSE)
}

## Aggregate across tiles (districts near tile boundaries may appear twice)
district_loss <- all_loss[, .(loss_ha = sum(loss_ha), n_pixels = sum(n_pixels)),
                          by = .(ID, year)]

## Add district names from GADM
gadm_dt <- as.data.table(as.data.frame(gadm_vect))
gadm_dt[, ID := .I]
district_loss <- merge(district_loss, gadm_dt[, .(ID, NAME_1, NAME_2, GID_2)],
                       by = "ID", all.x = TRUE)

cat("\nTotal forest loss data:", nrow(district_loss), "district-year obs\n")
cat("Districts with loss:", uniqueN(district_loss$GID_2), "\n")

## ── 4. Process treecover2000: baseline forest density per district ─
cat("\nComputing baseline tree cover per district...\n")
all_tc <- data.table()

for (i in seq_along(tc_files)) {
  tile_name <- gsub(".*treecover2000_(.+)\\.tif", "\\1", tc_files[i])
  cat("Processing treecover tile", tile_name, "...\n")

  r <- rast(tc_files[i])
  r_crop <- crop(r, ext(gadm_vect))

  if (is.null(r_crop) || ncell(r_crop) == 0) {
    cat("  No overlap, skipping\n")
    next
  }

  ## Mean tree cover per district
  tc_ex <- extract(r_crop, gadm_vect, fun = "mean", na.rm = TRUE, ID = TRUE)
  setDT(tc_ex)
  names(tc_ex) <- c("ID", "tc_mean")
  tc_ex[, tile := tile_name]

  all_tc <- rbind(all_tc, tc_ex[!is.na(tc_mean) & tc_mean > 0])

  rm(r, r_crop, tc_ex)
  gc(verbose = FALSE)
}

## Average across tiles for districts that appear in multiple tiles
tc_baseline <- all_tc[, .(treecover2000_pct = mean(tc_mean, na.rm = TRUE)),
                      by = ID]
tc_baseline <- merge(tc_baseline, gadm_dt[, .(ID, NAME_1, NAME_2, GID_2)],
                     by = "ID", all.x = TRUE)

cat("Baseline tree cover for", nrow(tc_baseline), "districts\n")

## ── 5. Build complete forest panel ────────────────────────────────
all_districts <- unique(gadm_dt[, .(ID, NAME_1, NAME_2, GID_2)])
forest_panel <- CJ(GID_2 = all_districts$GID_2, year = 2001:2023)
forest_panel <- merge(forest_panel, all_districts, by = "GID_2", all.x = TRUE)

## Merge forest loss
forest_panel <- merge(forest_panel,
                      district_loss[, .(GID_2, year, loss_ha)],
                      by = c("GID_2", "year"), all.x = TRUE)
forest_panel[is.na(loss_ha), loss_ha := 0]

## Merge baseline tree cover
forest_panel <- merge(forest_panel,
                      tc_baseline[, .(GID_2, treecover2000_pct)],
                      by = "GID_2", all.x = TRUE)
forest_panel[is.na(treecover2000_pct), treecover2000_pct := 0]

## Treatment timing and log outcomes
forest_panel[, post2008 := as.integer(year >= 2008)]
forest_panel[, log_loss := log(loss_ha + 1)]

## ── 6. Merge nightlights ST data into forest panel ─────────────────
## Load the nightlights panel for ST shares
nl_panel <- fread(file.path(data_dir, "analysis_panel.csv"))

## Get unique district-level ST data from nightlights panel
st_data <- unique(nl_panel[, .(dist_id, st_share, sc_share,
                                pc11_pca_tot_p, pc11_pca_p_st, pc11_pca_p_sc)])

## GADM GID_2 format: IND.XX.YY_1 — need to match to SHRUG dist_id format
## SHRUG: "SS_DDD" (state_district)
## GADM NAME_1 = state name, NAME_2 = district name
## Matching by name is unreliable. Better: use GADM state code mapping.
## For now, we'll run forest analysis with GADM IDs and match ST shares via state

## Create state-level ST share as a proxy (imperfect but workable)
state_st <- nl_panel[, .(
  st_share = weighted.mean(st_share, pc11_pca_tot_p, na.rm = TRUE),
  sc_share = weighted.mean(sc_share, pc11_pca_tot_p, na.rm = TRUE),
  total_pop = sum(unique(pc11_pca_tot_p))
), by = .(state_id = substr(dist_id, 1, regexpr("_", dist_id) - 1))]

## Map GADM state names to Census state IDs
## Build a rough mapping from GADM NAME_1 to SHRUG state codes
gadm_states <- unique(gadm_dt[, .(NAME_1)])
cat("\nGADM state names:", sort(gadm_states$NAME_1), "\n")

## Manual mapping of key states (Census 2011 state codes)
state_map <- data.table(
  NAME_1 = c("Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
             "Chhattisgarh", "Goa", "Gujarat", "Haryana",
             "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
             "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya",
             "Mizoram", "Nagaland", "Odisha", "Punjab",
             "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
             "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
             "Jammu and Kashmir", "NCT of Delhi", "Ladakh",
             "Andaman and Nicobar", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
             "Lakshadweep", "Puducherry"),
  state_id = c("28", "12", "18", "10",
               "22", "30", "24", "06",
               "02", "20", "29", "32",
               "23", "27", "14", "17",
               "15", "13", "21", "03",
               "08", "11", "33", "36",
               "16", "09", "05", "19",
               "01", "07", "37",
               "35", "04", "26",
               "31", "34")
)

## Merge state IDs to forest panel
forest_panel <- merge(forest_panel, state_map, by = "NAME_1", all.x = TRUE)
forest_panel <- merge(forest_panel, state_st, by = "state_id", all.x = TRUE)

## For districts without ST data (unmatched states), set to NA
cat("Forest panel with ST data:", sum(!is.na(forest_panel$st_share)), "of", nrow(forest_panel), "\n")

## Treatment variables
forest_panel[, treat_st := st_share * post2008]
forest_panel[, treat_sc := sc_share * post2008]

## High-forest indicator (baseline tree cover > median)
tc_med <- median(forest_panel[treecover2000_pct > 0]$treecover2000_pct, na.rm = TRUE)
forest_panel[, high_forest := as.integer(treecover2000_pct > tc_med)]

## ── 7. Save final datasets ────────────────────────────────────────
fwrite(forest_panel, file.path(data_dir, "forest_panel.csv"))
fwrite(tc_baseline, file.path(data_dir, "treecover_baseline.csv"))

cat("\n=== FINAL DATA SUMMARY ===\n")
cat("Forest panel:", nrow(forest_panel), "obs,",
    uniqueN(forest_panel$GID_2), "districts,",
    length(unique(forest_panel$year)), "years\n")
cat("Districts with ANY forest loss:", uniqueN(district_loss$GID_2), "\n")
cat("Mean annual loss (all districts):", round(mean(forest_panel$loss_ha), 2), "ha\n")
cat("Mean annual loss (positive only):", round(mean(forest_panel[loss_ha > 0]$loss_ha), 2), "ha\n")
cat("Median baseline tree cover:", round(median(tc_baseline$treecover2000_pct), 1), "%\n")
cat("Districts with ST match:", sum(!is.na(unique(forest_panel[, .(GID_2, st_share)])$st_share)), "\n")
