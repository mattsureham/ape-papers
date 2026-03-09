## 01b_fetch_epci.R — Build commune-to-EPCI crosswalk with EPCI-level density
## apep_0561: ZRR reclassification and RN voting
##
## Produces ../data/epci_crosswalk.csv with columns:
##   commune_code, epci_code, epci_name, epci_density, epci_pop, epci_surface
##
## Data sources:
##   1. INSEE "Intercommunalité Métropole au 01/01/2017" (commune→EPCI mapping)
##   2. geo.api.gouv.fr (commune population + surface in hectares)
##   3. Density aggregated to EPCI level (sum pop / sum surface of members)

source("00_packages.R")

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(readxl)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1) Download INSEE 2017 EPCI Composition (commune → EPCI mapping)
# ============================================================
cat("=== Step 1: Downloading INSEE 2017 EPCI composition ===\n")

epci_zip <- file.path(data_dir, "Intercommunalite_2017.zip")
epci_xls <- file.path(data_dir, "Intercommunalite_Metropole_au_01-01-2017.xls")

if (!file.exists(epci_xls)) {
  # Primary source: INSEE
  epci_url <- "https://www.insee.fr/fr/statistiques/fichier/2510634/Intercommunalite_Metropole_au_01-01-2017.zip"

  tryCatch({
    download.file(epci_url, epci_zip, mode = "wb", quiet = FALSE)
    cat("INSEE EPCI ZIP downloaded:", file.size(epci_zip), "bytes\n")
    unzip(epci_zip, exdir = data_dir, overwrite = TRUE)
    cat("Extracted.\n")
  }, error = function(e) {
    stop("FATAL: Cannot download INSEE 2017 EPCI file: ", e$message,
         "\nThis is a required data source. Check network or URL.")
  })

  # Verify extraction
  if (!file.exists(epci_xls)) {
    # The filename inside the ZIP might differ — find it
    xls_files <- list.files(data_dir, pattern = "Intercommunalite.*2017.*\\.xls$",
                            full.names = TRUE)
    if (length(xls_files) == 0) {
      stop("FATAL: ZIP extracted but no XLS file found matching expected pattern.")
    }
    epci_xls <- xls_files[1]
    cat("Found extracted file:", basename(epci_xls), "\n")
  }
} else {
  cat("INSEE EPCI XLS already exists.\n")
}

stopifnot("EPCI XLS must exist" = file.exists(epci_xls))
cat("EPCI XLS size:", round(file.size(epci_xls) / 1e6, 1), "MB\n")

# Read the Composition_communale sheet (commune → EPCI mapping)
cat("\nReading Composition_communale sheet...\n")
comp <- read_excel(epci_xls, sheet = "Composition_communale", skip = 5)
cat("Columns:", paste(names(comp), collapse = ", "), "\n")
cat("Rows:", nrow(comp), "\n")

# Standardize
comp_dt <- data.table(
  commune_code = as.character(comp$CODGEO),
  commune_name = as.character(comp$LIBGEO),
  epci_code    = as.character(comp$EPCI),
  epci_name    = as.character(comp$LIBEPCI),
  dep          = as.character(comp$DEP)
)

# Clean: remove any header artifacts
comp_dt <- comp_dt[!is.na(commune_code) & commune_code != "" &
                     !grepl("^CODGEO$", commune_code)]

# Pad commune codes (handles Corsica 2A/2B correctly — they're already 5 chars)
comp_dt[nchar(commune_code) < 5 & !grepl("^[A-Z]", commune_code),
        commune_code := sprintf("%05s", commune_code)]

cat("Unique communes in crosswalk:", uniqueN(comp_dt$commune_code), "\n")
cat("Unique EPCIs:", uniqueN(comp_dt$epci_code), "\n")

# ============================================================
# 2) Fetch commune-level population and surface from geo.api.gouv.fr
# ============================================================
cat("\n=== Step 2: Fetching commune population & surface from geo API ===\n")

geo_cache <- file.path(data_dir, "geo_api_communes.csv")

if (!file.exists(geo_cache)) {
  geo_url <- "https://geo.api.gouv.fr/communes?fields=code,nom,surface,population,codeEpci"

  cat("Downloading from geo.api.gouv.fr (all communes)...\n")
  tryCatch({
    geo_raw <- curl::curl_fetch_memory(geo_url)
    if (geo_raw$status_code != 200) {
      stop("geo API returned HTTP ", geo_raw$status_code)
    }
    geo_json <- jsonlite::fromJSON(rawToChar(geo_raw$content))
    cat("Downloaded", nrow(geo_json), "communes from geo API.\n")

    # Save as CSV cache
    geo_dt <- data.table(
      commune_code = geo_json$code,
      commune_name_geo = geo_json$nom,
      surface_ha = geo_json$surface,
      population = geo_json$population,
      epci_code_current = geo_json$codeEpci
    )
    fwrite(geo_dt, geo_cache)
    cat("Cached to", geo_cache, "\n")
  }, error = function(e) {
    stop("FATAL: Cannot fetch commune data from geo API: ", e$message)
  })
} else {
  cat("Geo API cache already exists.\n")
  geo_dt <- fread(geo_cache)
}

cat("Geo API communes:", nrow(geo_dt), "\n")
cat("  With surface:", sum(!is.na(geo_dt$surface_ha)), "\n")
cat("  With population:", sum(!is.na(geo_dt$population)), "\n")

# Convert surface from hectares to km²
geo_dt[, surface_km2 := surface_ha / 100]

# ============================================================
# 3) Merge: use 2017 EPCI mapping + geo API for pop/surface
# ============================================================
cat("\n=== Step 3: Merging crosswalk with population/surface ===\n")

# Merge the 2017 EPCI mapping with geo API data (surface + population)
merged <- merge(comp_dt, geo_dt[, .(commune_code, surface_ha, surface_km2, population)],
                by = "commune_code", all.x = TRUE)

cat("Merged rows:", nrow(merged), "\n")
cat("  With population:", sum(!is.na(merged$population)), "\n")
cat("  Without population:", sum(is.na(merged$population)), "\n")

# For communes without geo API data (e.g., merged/renamed since 2017),
# try to match via the current EPCI code from geo API
if (sum(is.na(merged$population)) > 0) {
  missing <- merged[is.na(population), .(commune_code, commune_name)]
  cat("  Missing communes (first 10):\n")
  print(head(missing, 10))
}

# Drop communes with missing population (typically very small, merged since 2017)
n_before <- nrow(merged)
merged_clean <- merged[!is.na(population) & !is.na(surface_km2)]
cat("Dropped", n_before - nrow(merged_clean), "communes with missing pop/surface.\n")
cat("Remaining:", nrow(merged_clean), "communes\n")

# ============================================================
# 4) Aggregate to EPCI level: density = sum(pop) / sum(surface)
# ============================================================
cat("\n=== Step 4: Computing EPCI-level density ===\n")

epci_agg <- merged_clean[, .(
  epci_pop      = sum(population, na.rm = TRUE),
  epci_surface  = sum(surface_km2, na.rm = TRUE),
  n_communes    = .N,
  epci_name     = epci_name[1]
), by = epci_code]

epci_agg[, epci_density := epci_pop / epci_surface]

cat("EPCI-level aggregation:\n")
cat("  N EPCIs:", nrow(epci_agg), "\n")
cat("  Density stats (hab/km²):\n")
cat("    Min:", round(min(epci_agg$epci_density), 1), "\n")
cat("    Median:", round(median(epci_agg$epci_density), 1), "\n")
cat("    Mean:", round(mean(epci_agg$epci_density), 1), "\n")
cat("    Max:", round(max(epci_agg$epci_density), 1), "\n")
cat("    SD:", round(sd(epci_agg$epci_density), 1), "\n")

# Show density distribution (ZRR threshold is typically ~31 hab/km²)
cat("\n  Density distribution around ZRR threshold (~31 hab/km²):\n")
cat("    Below 20:", sum(epci_agg$epci_density < 20), "EPCIs\n")
cat("    20-31:", sum(epci_agg$epci_density >= 20 & epci_agg$epci_density < 31), "EPCIs\n")
cat("    31-50:", sum(epci_agg$epci_density >= 31 & epci_agg$epci_density < 50), "EPCIs\n")
cat("    50-100:", sum(epci_agg$epci_density >= 50 & epci_agg$epci_density < 100), "EPCIs\n")
cat("    Above 100:", sum(epci_agg$epci_density >= 100), "EPCIs\n")

# ============================================================
# 5) Build final crosswalk: commune_code → EPCI with density
# ============================================================
cat("\n=== Step 5: Building final crosswalk ===\n")

crosswalk <- merge(
  merged_clean[, .(commune_code, epci_code)],
  epci_agg[, .(epci_code, epci_name, epci_density, epci_pop, epci_surface, n_communes)],
  by = "epci_code", all.x = TRUE
)

# Reorder columns
setcolorder(crosswalk, c("commune_code", "epci_code", "epci_name",
                          "epci_density", "epci_pop", "epci_surface", "n_communes"))

# ============================================================
# 6) Attempt to fetch EPCI-level median fiscal income (Filosofi)
# ============================================================
cat("\n=== Step 6: Attempting to fetch fiscal income data ===\n")

# Try multiple sources for EPCI-level median income
income_fetched <- FALSE

# Source 1: INSEE Filosofi commune-level data (to aggregate to EPCI)
# The INSEE download server is unreliable — try but handle failure gracefully
filosofi_urls <- c(
  "https://www.insee.fr/fr/statistiques/fichier/6692392/cc_filosofi_2020_COM.csv",
  "https://www.insee.fr/fr/statistiques/fichier/4190004/base-cc-filosofi-2017.zip",
  "https://www.insee.fr/fr/statistiques/fichier/4265439/ensemble.zip"
)

for (url in filosofi_urls) {
  if (income_fetched) break
  cat("  Trying:", url, "\n")
  tryCatch({
    resp <- curl::curl_fetch_memory(url, handle = curl::new_handle(timeout = 15))
    if (resp$status_code == 200 && length(resp$content) > 1000) {
      cat("    -> Got response (", length(resp$content), "bytes)\n")
      # Would need to parse here — but INSEE is returning 500s on all these
      income_fetched <- TRUE
    } else {
      cat("    -> HTTP", resp$status_code, "\n")
    }
  }, error = function(e) {
    cat("    -> Failed:", e$message, "\n")
  })
}

if (!income_fetched) {
  cat("\n  NOTE: Could not download fiscal income data.\n")
  cat("  INSEE file server is returning errors for Filosofi datasets.\n")
  cat("  The epci_median_income column will be NA.\n")
  cat("  To add income data later, place a CSV with columns\n")
  cat("  (epci_code, median_income) at ../data/filosofi_epci.csv\n")
  crosswalk[, epci_median_income := NA_real_]
} else {
  # Parse and merge income data (placeholder — currently not reached)
  crosswalk[, epci_median_income := NA_real_]
}

# Check if user has manually placed a Filosofi file
filosofi_manual <- file.path(data_dir, "filosofi_epci.csv")
if (file.exists(filosofi_manual)) {
  cat("  Found manual Filosofi file:", filosofi_manual, "\n")
  filo <- fread(filosofi_manual)
  if ("epci_code" %in% names(filo) && "median_income" %in% names(filo)) {
    crosswalk[, epci_median_income := NULL]
    crosswalk <- merge(crosswalk, filo[, .(epci_code, epci_median_income = median_income)],
                        by = "epci_code", all.x = TRUE)
    cat("  Merged income data for",
        sum(!is.na(crosswalk$epci_median_income)), "/",
        nrow(crosswalk), "communes.\n")
  }
}

# ============================================================
# 7) Save final crosswalk
# ============================================================
cat("\n=== Step 7: Saving crosswalk ===\n")

output_file <- file.path(data_dir, "epci_crosswalk.csv")
fwrite(crosswalk, output_file)
cat("Saved:", output_file, "\n")
cat("  Rows:", nrow(crosswalk), "\n")
cat("  Columns:", paste(names(crosswalk), collapse = ", "), "\n")

# Also save the EPCI-level aggregation separately (useful for RD analysis)
epci_file <- file.path(data_dir, "epci_level.csv")
fwrite(epci_agg, epci_file)
cat("Saved EPCI-level data:", epci_file, "\n")
cat("  EPCIs:", nrow(epci_agg), "\n")

# ============================================================
# 8) Merge into existing analysis datasets
# ============================================================
cat("\n=== Step 8: Merging EPCI data into analysis datasets ===\n")

# Load existing datasets
datasets <- c("did_sample.csv", "sym_sample.csv", "full_panel.csv")

for (ds_name in datasets) {
  ds_path <- file.path(data_dir, ds_name)
  if (!file.exists(ds_path)) {
    cat("  SKIP:", ds_name, "(not found)\n")
    next
  }

  cat("  Processing:", ds_name, "...\n")
  dt <- fread(ds_path)

  # Remove old EPCI columns if they exist (from prior runs)
  old_cols <- intersect(names(dt), c("epci_code", "epci_name", "epci_density",
                                      "epci_pop", "epci_surface", "n_communes",
                                      "epci_median_income"))
  if (length(old_cols) > 0) {
    dt[, (old_cols) := NULL]
  }

  # Merge
  dt_merged <- merge(dt, crosswalk, by = "commune_code", all.x = TRUE)

  # Report merge rate
  n_total <- nrow(dt_merged)
  n_matched <- sum(!is.na(dt_merged$epci_code))
  cat("    Matched:", n_matched, "/", n_total,
      "(", round(100 * n_matched / n_total, 1), "%)\n")

  # Save (overwrite)
  fwrite(dt_merged, ds_path)
  cat("    Saved:", ds_path, "\n")
}

# ============================================================
# VALIDATION
# ============================================================
cat("\n=== VALIDATION ===\n")

stopifnot("Crosswalk must have commune_code" = "commune_code" %in% names(crosswalk))
stopifnot("Crosswalk must have epci_code" = "epci_code" %in% names(crosswalk))
stopifnot("Crosswalk must have epci_density" = "epci_density" %in% names(crosswalk))
stopifnot("Must have >30000 communes" = nrow(crosswalk) > 30000)
stopifnot("All densities must be positive" = all(crosswalk$epci_density > 0))
stopifnot("Must have >1000 EPCIs" = uniqueN(crosswalk$epci_code) > 1000)

# Sanity: check that Paris (75056) maps to Métropole du Grand Paris
paris_epci <- crosswalk[commune_code == "75056", epci_code]
if (length(paris_epci) > 0) {
  cat("Paris EPCI:", paris_epci, "\n")
  paris_density <- crosswalk[commune_code == "75056", epci_density]
  cat("Paris EPCI density:", round(paris_density, 0), "hab/km²\n")
}

# Check a rural commune
rural_sample <- crosswalk[epci_density < 20][1]
cat("Sample rural EPCI:", rural_sample$epci_name,
    "- density:", round(rural_sample$epci_density, 1), "hab/km²\n")

cat("\n=== 01b_fetch_epci.R complete ===\n")
cat("Output: ../data/epci_crosswalk.csv (", nrow(crosswalk), "communes)\n")
cat("Output: ../data/epci_level.csv (", nrow(epci_agg), "EPCIs)\n")
