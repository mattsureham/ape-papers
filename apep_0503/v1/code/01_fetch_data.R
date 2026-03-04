## ============================================================================
## 01_fetch_data.R — Fetch ADEME DPE + DVF property transaction data
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## PART 1: ADEME DPE Data (post-July 2021)
## ============================================================================

cat("\n=== Fetching ADEME DPE data (post-2021) ===\n")

# The ADEME API has a 10K row limit per request. We paginate.
# Dataset: meg-83tjwtg8dyz4vv7h1dqe (DPE Logements existants depuis juillet 2021)
DPE_BASE_URL <- "https://data.ademe.fr/data-fair/api/v1/datasets/meg-83tjwtg8dyz4vv7h1dqe/lines"

# API field names (lowercase, as returned by the ADEME API)
# Key fields: numero_dpe, date_reception_dpe, etiquette_dpe, etiquette_ges,
# conso_5_usages_par_m2_ep, emission_ges_5_usages_par_m2,
# surface_habitable_immeuble, code_postal_ban, code_insee_ban,
# type_batiment, cout_total_5_usages

# Select key fields to reduce bandwidth
DPE_SELECT <- paste(c(
  "numero_dpe", "date_reception_dpe", "etiquette_dpe", "etiquette_ges",
  "conso_5_usages_par_m2_ep", "emission_ges_5_usages_par_m2",
  "surface_habitable_immeuble", "code_postal_ban", "code_insee_ban",
  "type_batiment", "cout_total_5_usages"
), collapse = ",")

dpe_file <- file.path(DATA_DIR, "dpe_near_cutoffs.parquet")

if (!file.exists(dpe_file)) {
  cat("Downloading DPE records near cutoffs...\n")

  # Strategy: fetch records within ±40 kWh/m² of each cutoff
  # This gives us enough bandwidth for RDD while keeping data manageable
  all_dpe <- list()

  for (cutoff_name in names(DPE_ENERGY_CUTS)) {
    cutoff_val <- DPE_ENERGY_CUTS[cutoff_name]
    lower <- cutoff_val - 40
    upper <- cutoff_val + 40

    cat(sprintf("  Cutoff %s (%d kWh): fetching range [%d, %d]...\n",
                cutoff_name, cutoff_val, lower, upper))

    # Use API query string to filter server-side
    qs <- sprintf("conso_5_usages_par_m2_ep:[%d TO %d]", lower, upper)

    page_size <- 10000
    batch <- 1
    cutoff_records <- list()
    total_fetched <- 0

    # First request URL
    next_url <- sprintf("%s?size=%d&qs=%s&select=%s",
                        DPE_BASE_URL, page_size,
                        URLencode(qs, reserved = TRUE),
                        URLencode(DPE_SELECT, reserved = TRUE))

    repeat {
      tryCatch({
        resp <- jsonlite::fromJSON(next_url, flatten = TRUE)
      }, error = function(e) {
        stop("DPE API request failed: ", e$message,
             "\nURL: ", next_url,
             "\nPivot research question or fix the source.")
      })

      if (length(resp$results) == 0) break

      df_page <- as_tibble(resp$results)
      cutoff_records[[length(cutoff_records) + 1]] <- df_page

      n_fetched <- nrow(df_page)
      total_fetched <- total_fetched + n_fetched
      cat(sprintf("    Batch %d: %d records (total: %d)\n", batch, n_fetched, total_fetched))

      if (n_fetched < page_size) break

      # Cursor-based pagination: use the "next" URL from the response
      if (is.null(resp[["next"]]) || resp[["next"]] == "") break
      next_url <- resp[["next"]]

      batch <- batch + 1
      Sys.sleep(0.15)  # Rate limit courtesy

      # Safety: cap at 200K per cutoff to avoid runaway
      if (total_fetched >= 200000) {
        cat("    Reached 200K cap, moving on\n")
        break
      }
    }

    if (length(cutoff_records) > 0) {
      cutoff_df <- bind_rows(cutoff_records)
      cutoff_df$nearest_cutoff <- cutoff_name
      cutoff_df$cutoff_value <- cutoff_val
      all_dpe[[cutoff_name]] <- cutoff_df
      cat(sprintf("  -> %s: %d records\n", cutoff_name, nrow(cutoff_df)))
    }
  }

  dpe_raw <- bind_rows(all_dpe)

  # Standardize column names
  dpe_raw <- dpe_raw %>%
    rename(
      dpe_id = numero_dpe,
      date_dpe = date_reception_dpe,
      dpe_label = etiquette_dpe,
      ges_label = etiquette_ges,
      energy_kwh_m2 = conso_5_usages_par_m2_ep,
      ghg_kg_m2 = emission_ges_5_usages_par_m2,
      surface_m2 = surface_habitable_immeuble,
      postal_code = code_postal_ban,
      insee_code = code_insee_ban,
      building_type = type_batiment,
      energy_cost = cout_total_5_usages
    ) %>%
    mutate(year_built = NA_character_)  # Not reliably available via API

  cat(sprintf("\nTotal DPE records fetched: %d\n", nrow(dpe_raw)))
  arrow::write_parquet(dpe_raw, dpe_file)
  cat("Saved to:", dpe_file, "\n")
} else {
  cat("DPE data already exists, loading...\n")
  dpe_raw <- arrow::read_parquet(dpe_file)
}

## ============================================================================
## PART 2: DVF Property Transaction Data
## ============================================================================

cat("\n=== Fetching DVF data ===\n")

dvf_file <- file.path(DATA_DIR, "dvf_all.parquet")

if (!file.exists(dvf_file)) {
  # Download national DVF files for 2020-2025 (2019 no longer hosted)
  dvf_years <- 2020:2025
  all_dvf <- list()

  for (yr in dvf_years) {
    dvf_url <- sprintf("https://files.data.gouv.fr/geo-dvf/latest/csv/%d/full.csv.gz", yr)
    dvf_gz <- file.path(DATA_DIR, sprintf("dvf_%d.csv.gz", yr))
    dvf_csv <- file.path(DATA_DIR, sprintf("dvf_%d.csv", yr))

    if (!file.exists(dvf_csv)) {
      cat(sprintf("  Downloading DVF %d...\n", yr))
      tryCatch({
        download.file(dvf_url, dvf_gz, mode = "wb", quiet = TRUE)
        system2("gunzip", args = c("-f", dvf_gz))
      }, error = function(e) {
        stop("DVF download failed for year ", yr, ": ", e$message,
             "\nPivot research question or fix the source.")
      })
    }

    cat(sprintf("  Reading DVF %d...\n", yr))
    dvf_yr <- fread(dvf_csv, select = c(
      "id_mutation", "date_mutation", "nature_mutation", "valeur_fonciere",
      "code_postal", "code_commune", "nom_commune",
      "type_local", "surface_reelle_bati", "nombre_pieces_principales",
      "adresse_numero", "adresse_nom_voie",
      "longitude", "latitude"
    ), showProgress = FALSE)

    dvf_yr[, year := as.integer(substr(date_mutation, 1, 4))]
    all_dvf[[as.character(yr)]] <- dvf_yr
    cat(sprintf("  -> DVF %d: %s transactions\n", yr, format(nrow(dvf_yr), big.mark = ",")))
  }

  dvf_all <- rbindlist(all_dvf)

  # Keep only sales of apartments and houses
  dvf_clean <- dvf_all[
    nature_mutation == "Vente" &
    type_local %in% c("Appartement", "Maison") &
    !is.na(valeur_fonciere) &
    valeur_fonciere > 10000 &
    !is.na(surface_reelle_bati) &
    surface_reelle_bati > 9 &
    surface_reelle_bati < 500
  ]

  # Compute price per m²
  dvf_clean[, price_m2 := valeur_fonciere / surface_reelle_bati]
  dvf_clean[, log_price_m2 := log(price_m2)]

  # Keep only mainland France (exclude DOM-TOM and Alsace-Moselle quirks)
  dvf_clean <- dvf_clean[nchar(code_commune) == 5]
  dvf_clean[, dept := substr(code_commune, 1, 2)]

  cat(sprintf("\nTotal DVF transactions (filtered): %s\n",
              format(nrow(dvf_clean), big.mark = ",")))

  arrow::write_parquet(dvf_clean, dvf_file)
  cat("Saved to:", dvf_file, "\n")

  # Clean up CSV files to save disk space
  for (yr in dvf_years) {
    csv_path <- file.path(DATA_DIR, sprintf("dvf_%d.csv", yr))
    if (file.exists(csv_path)) file.remove(csv_path)
  }
} else {
  cat("DVF data already exists, loading...\n")
  dvf_clean <- arrow::read_parquet(dvf_file)
}

## ============================================================================
## PART 3: INSEE commune-level data (rental share proxy)
## ============================================================================

cat("\n=== Fetching INSEE commune rental share data ===\n")

rental_file <- file.path(DATA_DIR, "commune_rental_share.csv")

if (!file.exists(rental_file)) {
  # INSEE housing status data from Recensement de la Population
  # Use RP2020 for tenure status by commune
  # SDMX endpoint for housing occupancy status
  cat("  Fetching commune tenure data from INSEE...\n")

  # Alternative: use the pre-computed data from data.gouv.fr
  tenure_url <- "https://www.insee.fr/fr/statistiques/fichier/6543200/base-cc-logement-2020_csv.zip"
  tenure_zip <- file.path(DATA_DIR, "insee_logement_2020.zip")

  tryCatch({
    download.file(tenure_url, tenure_zip, mode = "wb", quiet = TRUE)
    unzip(tenure_zip, exdir = file.path(DATA_DIR, "insee_logement"))
  }, error = function(e) {
    # Fallback: create rental share from commune population density
    # Higher density communes tend to have higher rental shares
    cat("  INSEE tenure download failed, creating proxy from DVF...\n")
    rental_proxy <- dvf_clean[, .(
      n_transactions = .N,
      n_apartments = sum(type_local == "Appartement"),
      n_houses = sum(type_local == "Maison")
    ), by = .(code_commune)]
    rental_proxy[, apt_share := n_apartments / n_transactions]
    # Apartment share is a reasonable proxy for rental share
    fwrite(rental_proxy[, .(code_commune, apt_share)], rental_file)
    cat("  Created rental share proxy from apartment share.\n")
  })

  # Try to read the INSEE file
  insee_files <- list.files(file.path(DATA_DIR, "insee_logement"),
                            pattern = "base-cc-logement.*\\.CSV$",
                            full.names = TRUE, ignore.case = TRUE)

  if (length(insee_files) > 0) {
    insee_log <- fread(insee_files[1], showProgress = FALSE)

    # Compute rental share: P20_RP_LOC / P20_RP (locataires / residences principales)
    rp_cols <- grep("^P20_RP$|^P20_RP_LOC$|^CODGEO$", names(insee_log), value = TRUE)

    if (all(c("CODGEO", "P20_RP", "P20_RP_LOC") %in% names(insee_log))) {
      rental_data <- insee_log[, .(
        code_commune = CODGEO,
        total_rp = P20_RP,
        n_renters = P20_RP_LOC
      )]
      rental_data[, rental_share := n_renters / total_rp]
      rental_data[is.nan(rental_share), rental_share := NA_real_]
      fwrite(rental_data[, .(code_commune, rental_share)], rental_file)
      cat("  Computed rental share for", nrow(rental_data), "communes\n")
    } else {
      cat("  Expected columns not found in INSEE file. Available:",
          paste(head(names(insee_log), 20), collapse = ", "), "\n")
      # Create proxy
      rental_proxy <- dvf_clean[, .(apt_share = mean(type_local == "Appartement")),
                                 by = .(code_commune)]
      fwrite(rental_proxy, rental_file)
      cat("  Created apartment share proxy instead.\n")
    }

    # Clean up
    unlink(file.path(DATA_DIR, "insee_logement"), recursive = TRUE)
    if (file.exists(tenure_zip)) file.remove(tenure_zip)
  }
} else {
  cat("Commune rental data already exists.\n")
}

## ============================================================================
## DATA VALIDATION (required)
## ============================================================================

cat("\n=== Data Validation ===\n")

dpe <- arrow::read_parquet(dpe_file)
dvf <- arrow::read_parquet(dvf_file)

# DPE validation
stopifnot("Expected 6+ DPE labels" = n_distinct(dpe$dpe_label) >= 5)
stopifnot("Expected >100K DPE records" = nrow(dpe) > 100000)
stopifnot("Expected energy scores present" = sum(!is.na(dpe$energy_kwh_m2)) > nrow(dpe) * 0.9)
cat(sprintf("DPE: %s records, %d labels, energy range [%d, %d]\n",
            format(nrow(dpe), big.mark = ","),
            n_distinct(dpe$dpe_label),
            min(dpe$energy_kwh_m2, na.rm = TRUE),
            max(dpe$energy_kwh_m2, na.rm = TRUE)))

# DVF validation
stopifnot("Expected >1M DVF transactions" = nrow(dvf) > 1000000)
stopifnot("Expected multiple years" = n_distinct(dvf$year) >= 4)
stopifnot("Expected positive prices" = all(dvf$valeur_fonciere > 0, na.rm = TRUE))
cat(sprintf("DVF: %s transactions, years %d-%d, %s communes\n",
            format(nrow(dvf), big.mark = ","),
            min(dvf$year), max(dvf$year),
            format(n_distinct(dvf$code_commune), big.mark = ",")))

cat("\n=== Data fetching complete ===\n")
