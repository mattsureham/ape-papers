## 01_fetch_data.R — Fetch CBS agricultural census data for apep_1114
## Real data only — no simulated fallbacks

source("00_packages.R")

cat("=== Fetching CBS data for Dutch Piekbelasters analysis ===\n\n")

# ---------------------------------------------------------------
# 1. CBS 80781ned — Agriculture; crops, livestock, municipality
# ---------------------------------------------------------------
cat("1. Fetching CBS 80781ned (agriculture by municipality)...\n")

agri_raw <- cbs_get_data("80781ned")
stopifnot("Data fetch returned empty" = nrow(agri_raw) > 0)
cat("  Rows fetched:", nrow(agri_raw), "\n")

# Get metadata for column labels
agri_meta <- cbs_get_meta("80781ned")
cat("  Columns:", ncol(agri_raw), "\n")

# Save raw
saveRDS(agri_raw, "../data/cbs_80781ned_raw.rds")
saveRDS(agri_meta, "../data/cbs_80781ned_meta.rds")
cat("  Saved to data/cbs_80781ned_raw.rds\n")

# ---------------------------------------------------------------
# 2. CBS 83582NED — Employment; SBI by municipality
# ---------------------------------------------------------------
cat("\n2. Fetching CBS 83582NED (employment by municipality)...\n")

empl_raw <- cbs_get_data("83582NED")
stopifnot("Employment data fetch returned empty" = nrow(empl_raw) > 0)
cat("  Rows fetched:", nrow(empl_raw), "\n")

empl_meta <- cbs_get_meta("83582NED")

saveRDS(empl_raw, "../data/cbs_83582NED_raw.rds")
saveRDS(empl_meta, "../data/cbs_83582NED_meta.rds")
cat("  Saved to data/cbs_83582NED_raw.rds\n")

# ---------------------------------------------------------------
# 3. Natura 2000 sites — PDOK GeoPackage
# ---------------------------------------------------------------
cat("\n3. Fetching Natura 2000 boundaries from PDOK...\n")

n2k_wfs_url <- paste0(
  "https://service.pdok.nl/rvo/natura2000/wfs/v1_0?",
  "service=WFS&version=2.0.0&request=GetFeature&",
  "typeName=natura2000:natura2000&outputFormat=json&count=500"
)

n2k <- st_read(n2k_wfs_url, quiet = TRUE)
stopifnot("Natura 2000 WFS returned empty" = nrow(n2k) > 0)
cat("  Natura 2000 sites loaded:", nrow(n2k), "features\n")
cat("  CRS:", st_crs(n2k)$input, "\n")

saveRDS(n2k, "../data/natura2000_sf.rds")

# ---------------------------------------------------------------
# 4. CBS municipality boundaries (for spatial join)
# ---------------------------------------------------------------
cat("\n4. Fetching CBS municipality boundaries...\n")

# Use CBS WFS for municipality boundaries
muni_wfs_url <- "https://service.pdok.nl/cbs/gebiedsindelingen/2023/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=gemeente_gegeneraliseerd&outputFormat=json&count=500"

muni_sf <- tryCatch({
  sf::st_read(muni_wfs_url, quiet = TRUE)
}, error = function(e) {
  cat("  WFS failed, trying alternative URL...\n")
  # Try 2024 boundaries
  alt_url <- "https://service.pdok.nl/cbs/gebiedsindelingen/2024/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=gemeente_gegeneraliseerd&outputFormat=json&count=500"
  sf::st_read(alt_url, quiet = TRUE)
})

stopifnot("Municipality boundaries not fetched" = nrow(muni_sf) > 0)
cat("  Municipalities loaded:", nrow(muni_sf), "features\n")

saveRDS(muni_sf, "../data/municipality_boundaries_sf.rds")

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
cat("\n=== Data fetch complete ===\n")
cat("Files saved in data/:\n")
cat("  - cbs_80781ned_raw.rds (agriculture)\n")
cat("  - cbs_83582NED_raw.rds (employment)\n")
cat("  - natura2000.gpkg + natura2000_sf.rds\n")
cat("  - municipality_boundaries_sf.rds\n")
