## ============================================================
## 01_fetch_data.R — Fetch DVF, ABC zone classification, Sitadel
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================
## Strategy:
##   2014-2020: Caisse des Depots commune-year aggregates (API)
##   2021-2024: Raw DVF transaction files (aggregate ourselves)
## ============================================================

source("00_packages.R")
library(jsonlite)

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1A. DVF 2014-2020: Caisse des Depots API
# ============================================================
# Commune-year aggregates with VEFA/existing split

cdc_file <- file.path(DATA_DIR, "cdc_dvf_2014_2020.csv")

if (!file.exists(cdc_file)) {
  cat("Downloading Caisse des Depots DVF aggregates (2014-2020)...\n")

  base_url <- "https://opendata.caissedesdepots.fr/api/explore/v2.1/catalog/datasets/donnees-valeurs-foncieres-a-la-commune/exports/csv"
  params <- "?select=anneemut,codgeo_2020,dep_code,com_arm_name_upper,nbmut_vente,nbmut_ventem,nbmut_ventea,nbmut_vefa,nbmut_vefam,nbmut_vefaa,vfmed_ventem,vfmed_vefam,vfmed_ventea,vfmed_vefaa,vfm2_ventea,vfm2_vefaa,pop_2018&delimiter=%3B&limit=-1"

  tryCatch({
    download.file(paste0(base_url, params), cdc_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop(sprintf("Failed to download Caisse des Depots DVF: %s\nPivot research question or fix the source.", e$message))
  })
}

cdc <- fread(cdc_file, sep = ";")
cat(sprintf("Caisse des Depots DVF: %s rows\n", formatC(nrow(cdc), big.mark = ",")))

# Parse year (anneemut is already an integer year, not a date)
cdc[, year := as.integer(anneemut)]
cat("Years in CDC data:\n")
print(table(cdc$year))

# Standardize column names
setnames(cdc, "codgeo_2020", "code_commune")
setnames(cdc, "dep_code", "code_departement")

# Build commune-year panel from CDC
# Price per m2 for apartments (most comparable metric)
# Median transaction value for houses
cdc_panel <- cdc[, .(
  code_commune = code_commune,
  code_departement = code_departement,
  year = year,
  n_transactions = nbmut_vente + nbmut_vefa,
  n_vefa = nbmut_vefa,
  n_sale = nbmut_vente,
  n_vefa_apt = nbmut_vefaa,
  n_sale_apt = nbmut_ventea,
  n_vefa_house = nbmut_vefam,
  n_sale_house = nbmut_ventem,
  price_m2_sale_apt = vfm2_ventea,
  price_m2_vefa_apt = vfm2_vefaa,
  median_price_sale_house = vfmed_ventem,
  median_price_vefa_house = vfmed_vefam,
  median_price_sale_apt = vfmed_ventea,
  median_price_vefa_apt = vfmed_vefaa,
  pop_2018 = pop_2018
)]

# Compute aggregate price per m2 (apartments only, most comparable)
cdc_panel[, price_m2 := fifelse(
  !is.na(price_m2_sale_apt) & !is.na(price_m2_vefa_apt),
  (price_m2_sale_apt * n_sale_apt + price_m2_vefa_apt * n_vefa_apt) /
    (n_sale_apt + n_vefa_apt),
  fifelse(!is.na(price_m2_sale_apt), price_m2_sale_apt, price_m2_vefa_apt)
)]

cat(sprintf("CDC panel: %s commune-years, %d years\n",
            formatC(nrow(cdc_panel), big.mark = ","), uniqueN(cdc_panel$year)))

fwrite(cdc_panel, file.path(DATA_DIR, "cdc_panel_2014_2020.csv"))

# ============================================================
# 1B. DVF 2021-2024: Raw transaction files
# ============================================================

dvf_urls <- list(
  "2021" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234836/valeursfoncieres-2021.txt.zip",
  "2022" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234844/valeursfoncieres-2022.txt.zip",
  "2023" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234851/valeursfoncieres-2023.txt.zip",
  "2024" = "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres/20251018-234857/valeursfoncieres-2024.txt.zip"
)

process_dvf_year <- function(yr, url) {
  cat(sprintf("Processing DVF %s...\n", yr))

  zipfile <- file.path(DATA_DIR, sprintf("dvf_%s.zip", yr))
  csvfile <- file.path(DATA_DIR, sprintf("dvf_%s.csv", yr))

  # Download
  if (!file.exists(zipfile) && !file.exists(csvfile)) {
    tryCatch({
      download.file(url, zipfile, mode = "wb", quiet = TRUE)
    }, error = function(e) {
      stop(sprintf("Failed to download DVF %s: %s\nPivot research question or fix the source.", yr, e$message))
    })
  }

  # Unzip if needed
  if (file.exists(zipfile) && !file.exists(csvfile)) {
    txtfiles <- unzip(zipfile, exdir = DATA_DIR)
    if (length(txtfiles) > 0) csvfile <- txtfiles[1]
  }

  # Find the extracted file
  if (!file.exists(csvfile)) {
    candidates <- list.files(DATA_DIR, pattern = sprintf("valeursfoncieres-%s", yr),
                             full.names = TRUE)
    if (length(candidates) > 0) csvfile <- candidates[1]
  }

  if (!file.exists(csvfile)) stop(sprintf("No file found for DVF %s", yr))

  raw <- fread(csvfile, sep = "|", header = TRUE, na.strings = "",
               encoding = "UTF-8")
  cat(sprintf("  Raw rows for %s: %s\n", yr, formatC(nrow(raw), big.mark = ",")))

  # Standardize column names: lowercase, replace spaces with underscores
  cols <- tolower(gsub(" ", "_", names(raw)))
  names(raw) <- cols

  # Clean price (comma as decimal)
  # Column name after standardization: "valeur_fonciere"
  if ("valeur_fonciere" %in% names(raw)) {
    if (is.character(raw$valeur_fonciere)) {
      raw[, valeur_fonciere := as.numeric(gsub(",", ".", valeur_fonciere))]
    }
  }

  # Ensure key columns exist
  needed <- c("nature_mutation", "valeur_fonciere", "type_local",
              "surface_reelle_bati", "code_commune", "code_departement")
  missing <- setdiff(needed, names(raw))
  if (length(missing) > 0) {
    cat("  Available columns: ", paste(head(names(raw), 20), collapse = ", "), "\n")
    stop(sprintf("Missing columns in DVF %s: %s", yr, paste(missing, collapse = ", ")))
  }

  # Flag VEFA
  raw[, is_vefa := grepl("futur", nature_mutation, ignore.case = TRUE)]
  raw[, is_apt := type_local == "Appartement"]
  raw[, is_house := type_local == "Maison"]
  raw[, year := as.integer(yr)]

  # Price per m2 for apartments
  raw[, price_m2 := fifelse(
    surface_reelle_bati > 0 & valeur_fonciere > 0 & is_apt,
    valeur_fonciere / surface_reelle_bati,
    NA_real_
  )]

  # Aggregate to commune-year (matching CDC structure)
  agg <- raw[valeur_fonciere > 1000 & (is_apt | is_house), .(
    n_transactions = .N,
    n_vefa = sum(is_vefa, na.rm = TRUE),
    n_sale = sum(!is_vefa, na.rm = TRUE),
    n_vefa_apt = sum(is_vefa & is_apt, na.rm = TRUE),
    n_sale_apt = sum(!is_vefa & is_apt, na.rm = TRUE),
    n_vefa_house = sum(is_vefa & is_house, na.rm = TRUE),
    n_sale_house = sum(!is_vefa & is_house, na.rm = TRUE),
    price_m2_sale_apt = median(price_m2[!is_vefa & is_apt & price_m2 > 100 & price_m2 < 50000], na.rm = TRUE),
    price_m2_vefa_apt = median(price_m2[is_vefa & is_apt & price_m2 > 100 & price_m2 < 50000], na.rm = TRUE),
    median_price_sale_house = median(valeur_fonciere[!is_vefa & is_house], na.rm = TRUE),
    median_price_vefa_house = median(valeur_fonciere[is_vefa & is_house], na.rm = TRUE),
    median_price_sale_apt = median(valeur_fonciere[!is_vefa & is_apt], na.rm = TRUE),
    median_price_vefa_apt = median(valeur_fonciere[is_vefa & is_apt], na.rm = TRUE)
  ), by = .(code_commune, code_departement)]

  agg[, year := as.integer(yr)]

  # Compute aggregate price/m2
  agg[, price_m2 := fifelse(
    !is.na(price_m2_sale_apt) & !is.na(price_m2_vefa_apt),
    (price_m2_sale_apt * n_sale_apt + price_m2_vefa_apt * n_vefa_apt) /
      (n_sale_apt + n_vefa_apt),
    fifelse(!is.na(price_m2_sale_apt), price_m2_sale_apt, price_m2_vefa_apt)
  )]

  # Clean up
  rm(raw)
  gc()
  file.remove(csvfile)
  if (file.exists(zipfile)) file.remove(zipfile)

  agg
}

# Process 2021-2024
dvf_recent <- list()
for (yr in names(dvf_urls)) {
  dvf_recent[[yr]] <- process_dvf_year(yr, dvf_urls[[yr]])
  gc()
}

dvf_2021_2024 <- rbindlist(dvf_recent, fill = TRUE)
cat(sprintf("DVF 2021-2024: %s commune-years\n",
            formatC(nrow(dvf_2021_2024), big.mark = ",")))

fwrite(dvf_2021_2024, file.path(DATA_DIR, "dvf_panel_2021_2024.csv"))

# ============================================================
# 1C. Combine 2014-2024 panel
# ============================================================

# Align columns between CDC (2014-2020) and raw DVF (2021-2024)
common_cols <- intersect(names(cdc_panel), names(dvf_2021_2024))
panel_full <- rbind(
  cdc_panel[, ..common_cols],
  dvf_2021_2024[, ..common_cols],
  fill = TRUE
)

cat(sprintf("\nCombined panel: %s commune-years, years %d-%d\n",
            formatC(nrow(panel_full), big.mark = ","),
            min(panel_full$year), max(panel_full$year)))
cat("Year distribution:\n")
print(table(panel_full$year))

fwrite(panel_full, file.path(DATA_DIR, "dvf_residential_agg.csv"))

# Also build a commercial proxy for placebo from 2021-2024 raw data
# (CDC doesn't have commercial separately — we'll use it where available)
cat("\nNote: Commercial placebo will use 2021-2024 data only (CDC lacks commercial breakdown)\n")

# ============================================================
# 2. ABC Zone Classification
# ============================================================

zone_url <- "https://static.data.gouv.fr/resources/liste-des-communes-selon-le-zonage-abc/20250910-150516/liste-des-communes-zonage-abc-5-septembre-2025.csv"
zone_file <- file.path(DATA_DIR, "zonage_abc.csv")

if (!file.exists(zone_file)) {
  tryCatch({
    download.file(zone_url, zone_file, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    # Try xlsx version
    alt_url <- "https://static.data.gouv.fr/resources/liste-des-communes-selon-le-zonage-abc/20250908-122528/liste-des-communes-zonage-abc-5-septembre-2025.xlsx"
    tryCatch({
      xlsx_file <- file.path(DATA_DIR, "zonage_abc.xlsx")
      download.file(alt_url, xlsx_file, mode = "wb", quiet = TRUE)
      zones_tmp <- readxl::read_xlsx(xlsx_file)
      fwrite(as.data.table(zones_tmp), zone_file)
    }, error = function(e2) {
      stop("Failed to download ABC zone classification from any source.")
    })
  })
}

zones <- tryCatch({
  fread(zone_file, encoding = "UTF-8")
}, error = function(e) {
  tryCatch(fread(zone_file, sep = ";", encoding = "UTF-8"),
           error = function(e2) {
    readxl::read_xlsx(gsub("\\.csv$", ".xlsx", zone_file))
  })
})

zones <- as.data.table(zones)
cat(sprintf("Zone classification: %d communes loaded\n", nrow(zones)))
cat("Columns: ", paste(names(zones), collapse = ", "), "\n")

fwrite(zones, file.path(DATA_DIR, "zonage_abc.csv"))

# ============================================================
# 3. Sitadel Construction Permits
# ============================================================

# Try multiple URLs for Sitadel data
sitadel_file <- file.path(DATA_DIR, "sitadel_logements.csv")

if (!file.exists(sitadel_file)) {
  sitadel_urls <- c(
    "https://www.statistiques.developpement-durable.gouv.fr/media/6728/download?inline",
    "https://www.data.gouv.fr/fr/datasets/r/89e5af0f-b2f4-4ac1-b56a-d47b0f83e4f9",
    "https://static.data.gouv.fr/resources/base-des-permis-de-construire-et-autres-autorisations-durbanisme-sitadel/20250116-174704/sitadel-logement-commune.csv"
  )
  downloaded <- FALSE
  for (url in sitadel_urls) {
    tryCatch({
      download.file(url, sitadel_file, mode = "wb", quiet = TRUE)
      downloaded <- TRUE
      cat(sprintf("Downloaded Sitadel from: %s\n", url))
      break
    }, error = function(e) NULL)
  }
  if (!downloaded) {
    cat("WARNING: Could not download Sitadel. Will use DVF VEFA counts as first-stage proxy.\n")
  }
}

if (file.exists(sitadel_file)) {
  sitadel <- tryCatch(fread(sitadel_file), error = function(e) {
    cat("WARNING: Could not parse Sitadel. Will use DVF VEFA as proxy.\n")
    NULL
  })
  if (!is.null(sitadel)) {
    cat(sprintf("Sitadel: %d rows loaded\n", nrow(sitadel)))
  }
} else {
  cat("Sitadel not available — using DVF VEFA counts as first-stage proxy.\n")
}

# ============================================================
# DATA VALIDATION (required)
# ============================================================

stopifnot("Combined panel has observations" = nrow(panel_full) > 100000)
stopifnot("Panel covers 2014-2024" = all(2014:2024 %in% unique(panel_full$year)))
stopifnot("Zone classification loaded" = nrow(zones) > 1000)

cat(sprintf("\n=== DATA VALIDATION PASSED ===\n"))
cat(sprintf("  Combined panel: %s commune-years\n",
            formatC(nrow(panel_full), big.mark = ",")))
cat(sprintf("  Years covered: %d-%d\n",
            min(panel_full$year), max(panel_full$year)))
cat(sprintf("  Communes: %s\n",
            formatC(uniqueN(panel_full$code_commune), big.mark = ",")))
cat(sprintf("  Zone classification: %s communes\n",
            formatC(nrow(zones), big.mark = ",")))
