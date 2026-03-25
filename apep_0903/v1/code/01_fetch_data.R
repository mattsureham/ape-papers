# 01_fetch_data.R — Fetch Swiss ZWG housing inventory (16 waves, 2017-2025)
# apep_0903: Second-Home Construction Ban RDD
#
# Source: data.geo.admin.ch STAC API (no auth required)
# Format: GeoPackage files with municipality-level housing composition

base_dir <- normalizePath(file.path(getwd(), ".."))
source(file.path(base_dir, "code", "00_packages.R"))
data_dir <- file.path(base_dir, "data")
dir.create(data_dir, showWarnings = FALSE)

cat("=== Downloading ZWG Housing Inventory (16 waves) ===\n")

# ---------------------------------------------------------------
# 1. Download all 16 GeoPackage files from STAC
# ---------------------------------------------------------------

base_stac <- "https://data.geo.admin.ch/ch.are.wohnungsinventar-zweitwohnungsanteil"
layer_prefix <- "wohnungsinventar-zweitwohnungsanteil"

# Wave identifiers from STAC catalog
waves <- c("2017", "2018", "2019-03", "2019-10",
           "2020-03", "2020-10", "2021-03", "2021-10",
           "2022-03", "2022-10", "2023-03", "2023-10",
           "2024-03", "2024-10", "2025-03", "2025-10")

all_data <- list()

for (wave in waves) {
  fname <- sprintf("%s_%s_2056.gpkg", layer_prefix, wave)
  # Note: 2024-03 has a double dot in the filename (typo in STAC)
  if (wave == "2024-03") {
    fname <- sprintf("%s_%s_2056..gpkg", layer_prefix, wave)
  }
  url <- sprintf("%s/%s_%s/%s", base_stac, layer_prefix, wave, fname)
  local_file <- file.path(data_dir, sprintf("zwg_%s.gpkg", wave))

  if (!file.exists(local_file)) {
    cat(sprintf("Downloading wave %s...\n", wave))
    resp <- httr::GET(url, httr::write_disk(local_file, overwrite = TRUE))
    if (httr::status_code(resp) != 200) {
      cat(sprintf("  WARNING: Failed with status %d, trying without double dot...\n",
                  httr::status_code(resp)))
      # Retry with standard filename
      fname2 <- sprintf("%s_%s_2056.gpkg", layer_prefix, wave)
      url2 <- sprintf("%s/%s_%s/%s", base_stac, layer_prefix, wave, fname2)
      resp <- httr::GET(url2, httr::write_disk(local_file, overwrite = TRUE))
      if (httr::status_code(resp) != 200) {
        cat(sprintf("  ERROR: Wave %s download failed (status %d). Skipping.\n",
                    wave, httr::status_code(resp)))
        file.remove(local_file)
        next
      }
    }
    cat(sprintf("  Downloaded: %s (%.1f KB)\n", local_file,
                file.info(local_file)$size / 1024))
  } else {
    cat(sprintf("Already cached: %s\n", wave))
  }

  # Read the GeoPackage
  tryCatch({
    gdf <- sf::st_read(local_file, quiet = TRUE)
    # Drop geometry for tabular analysis
    df <- sf::st_drop_geometry(gdf)
    df$wave <- wave
    # Parse wave date
    if (nchar(wave) == 4) {
      df$wave_date <- as.Date(paste0(wave, "-03-31"))
    } else {
      parts <- strsplit(wave, "-")[[1]]
      df$wave_date <- as.Date(paste0(parts[1], "-", parts[2], "-01"))
    }
    all_data[[wave]] <- df
    cat(sprintf("  Loaded: %d municipalities, columns: %s\n",
                nrow(df), paste(names(df)[1:min(8, ncol(df))], collapse=", ")))
  }, error = function(e) {
    cat(sprintf("  ERROR reading %s: %s\n", local_file, conditionMessage(e)))
  })
}

cat(sprintf("\nLoaded %d waves successfully.\n", length(all_data)))
stopifnot(length(all_data) >= 10) # Must have substantial coverage

# ---------------------------------------------------------------
# 2. Build panel dataset
# ---------------------------------------------------------------

panel <- data.table::rbindlist(all_data, fill = TRUE)
cat(sprintf("Panel: %d municipality-wave observations\n", nrow(panel)))
cat(sprintf("Unique municipalities: %d\n", uniqueN(panel$gemeinde_nummer)))
cat(sprintf("Waves: %d (%s to %s)\n", uniqueN(panel$wave),
            min(panel$wave), max(panel$wave)))

# Inspect column names
cat("\nColumn names:\n")
cat(paste(names(panel), collapse = ", "), "\n")

# Print summary of key variables
cat("\nKey variable summary:\n")
cat(sprintf("  zwg_3110 (primary %%): mean=%.1f, sd=%.1f, range=[%.1f, %.1f]\n",
            mean(panel$zwg_3110, na.rm=TRUE), sd(panel$zwg_3110, na.rm=TRUE),
            min(panel$zwg_3110, na.rm=TRUE), max(panel$zwg_3110, na.rm=TRUE)))
cat(sprintf("  zwg_3120 (secondary %%): mean=%.1f, sd=%.1f, range=[%.1f, %.1f]\n",
            mean(panel$zwg_3120, na.rm=TRUE), sd(panel$zwg_3120, na.rm=TRUE),
            min(panel$zwg_3120, na.rm=TRUE), max(panel$zwg_3120, na.rm=TRUE)))
cat(sprintf("  zwg_3150 (total dwellings): mean=%.0f, median=%.0f\n",
            mean(panel$zwg_3150, na.rm=TRUE), median(panel$zwg_3150, na.rm=TRUE)))

# Quick summary using actual column names from GeoPackage
cat(sprintf("\nUnique municipalities: %d\n", uniqueN(panel$Gem_No)))

# Convert to numeric for summary
panel[, pct_sec_num := as.numeric(as.character(ZWG_3120))]
cat(sprintf("  ZWG_3120 (secondary %%): mean=%.2f, sd=%.2f, range=[%.2f, %.2f]\n",
            mean(panel$pct_sec_num, na.rm=TRUE), sd(panel$pct_sec_num, na.rm=TRUE),
            min(panel$pct_sec_num, na.rm=TRUE), max(panel$pct_sec_num, na.rm=TRUE)))

# Distribution around threshold (latest wave)
latest <- panel[wave == max(wave)]
breaks <- c(0, 5, 10, 15, 18, 19, 20, 21, 22, 25, 30, 50, 100)
latest[, bucket := cut(pct_sec_num, breaks = breaks, right = FALSE)]
cat(sprintf("\nDistribution around threshold (latest wave):\n"))
print(table(latest$bucket))

treated_count <- nrow(latest[pct_sec_num >= 20])
control_count <- nrow(latest[pct_sec_num < 20])
cat(sprintf("\nTreated (>=20%%): %d, Control (<20%%): %d\n", treated_count, control_count))
panel[, pct_sec_num := NULL]

# ---------------------------------------------------------------
# 3. Save panel
# ---------------------------------------------------------------

data.table::fwrite(panel, file.path(data_dir, "zwg_panel.csv"))
saveRDS(panel, file.path(data_dir, "zwg_panel.rds"))
cat(sprintf("\nPanel saved: %s\n", file.path(data_dir, "zwg_panel.csv")))

cat("\n=== Data fetch complete ===\n")
