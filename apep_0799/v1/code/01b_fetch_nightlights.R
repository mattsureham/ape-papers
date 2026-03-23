## ==========================================================================
## 01b_fetch_nightlights.R — Fetch VIIRS Black Marble annual nightlights
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

library(data.table)
library(sf)
library(terra)
library(geodata)
library(blackmarbler)
library(exactextractr)

cat("=== Fetch India District Boundaries (GADM Level 2) ===\n")

gadm_path <- "data/india_gadm"
dir.create(gadm_path, showWarnings = FALSE, recursive = TRUE)

india_districts <- gadm(country = "IND", level = 2, path = gadm_path)
india_sf <- st_as_sf(india_districts)

cat("Downloaded", nrow(india_sf), "district polygons\n")
cat("States:", length(unique(india_sf$NAME_1)), "\n")

st_write(india_sf, "data/india_districts.gpkg", delete_dsn = TRUE, quiet = TRUE)

cat("\n=== Fetch VIIRS Black Marble Annual Composites (VNP46A4) ===\n")

bearer <- Sys.getenv("NASA_EARTHDATA_API_KEY")
if (nchar(bearer) < 10) {
  stop("FATAL: NASA_EARTHDATA_API_KEY not set.")
}

# Annual composites: 2014-2023 (pre-shutdown years for baseline)
years <- 2014:2023

cat("Downloading VNP46A4 annual composites for", length(years), "years...\n")
cat("This may take several minutes per year.\n")

# Extract district-level mean nightlights for each year
ntl_list <- list()

for (yr in years) {
  cat("\n--- Year:", yr, "---\n")

  result <- tryCatch({
    bm_extract(
      roi_sf = india_sf,
      product_id = "VNP46A4",
      date = yr,
      bearer = bearer,
      aggregation_fun = "mean",
      quiet = FALSE
    )
  }, error = function(e) {
    cat("  ERROR for year", yr, ":", e$message, "\n")
    NULL
  })

  if (!is.null(result)) {
    result_dt <- as.data.table(result)
    result_dt[, year := yr]
    ntl_list[[as.character(yr)]] <- result_dt
    cat("  Extracted", nrow(result_dt), "district values\n")
  }
}

if (length(ntl_list) == 0) {
  stop("FATAL: Could not download nightlights for any year.")
}

ntl_annual <- rbindlist(ntl_list, fill = TRUE)
cat("\n=== Nightlights Summary ===\n")
cat("Total district-year observations:", nrow(ntl_annual), "\n")
cat("Years covered:", paste(unique(ntl_annual$year), collapse = ", "), "\n")
cat("Columns:", paste(names(ntl_annual), collapse = ", "), "\n")

fwrite(ntl_annual, "data/ntl_annual.csv")
cat("Saved to data/ntl_annual.csv\n")
