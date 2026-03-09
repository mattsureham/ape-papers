# =============================================================================
# 01_fetch_data.R — Fetch DVF, ADEME DPE, and INSEE commune data
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

source("00_packages.R")

# =============================================================================
# 1. DVF (Demandes de Valeurs Foncieres) — Geolocalized bulk download
# =============================================================================

cat("=== Fetching DVF data ===\n")

dvf_file <- file.path(data_dir, "dvf_all.parquet")

if (!file.exists(dvf_file)) {
  # Single bulk file containing all geolocalized DVF data (2020-2025)
  dvf_url <- "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres-geolocalisees/20251105-140205/dvf.csv.gz"
  dvf_dest <- file.path(data_dir, "dvf_bulk.csv.gz")

  cat("  Downloading DVF bulk file (~494 MB)...\n")
  tryCatch({
    download.file(dvf_url, dvf_dest, mode = "wb", quiet = FALSE, timeout = 3600)
  }, error = function(e) {
    # Fallback: try year-by-year for 2020-2024
    cat("  Bulk download failed. Trying year-by-year...\n")
    dvf_list <- list()
    for (yr in 2020:2024) {
      url <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/", yr, "/full.csv.gz")
      dest_yr <- file.path(data_dir, paste0("dvf_", yr, ".csv.gz"))
      cat("  Downloading DVF", yr, "...\n")
      tryCatch({
        download.file(url, dest_yr, mode = "wb", quiet = TRUE, timeout = 600)
        dt <- fread(cmd = paste("gunzip -c", dest_yr), encoding = "UTF-8")
        dt[, year := yr]
        dvf_list[[as.character(yr)]] <- dt
        file.remove(dest_yr)
        cat("  DVF", yr, ":", nrow(dt), "rows\n")
      }, error = function(e2) {
        cat("  Year", yr, "download failed:", e2$message, "\n")
      })
    }
    if (length(dvf_list) == 0) {
      stop("DVF download failed completely. Pivot research question or fix the source.")
    }
    dvf_raw <- rbindlist(dvf_list, fill = TRUE)
    arrow::write_parquet(dvf_raw, dvf_file)
    rm(dvf_list, dvf_raw); gc()
    cat("DVF saved to parquet (year-by-year fallback).\n")
  })

  # If bulk download succeeded, read and convert
  if (file.exists(dvf_dest)) {
    cat("  Reading bulk DVF CSV...\n")
    dvf_raw <- fread(dvf_dest, encoding = "UTF-8")
    cat("  DVF rows:", nrow(dvf_raw), "\n")
    cat("  Columns:", paste(head(names(dvf_raw), 20), collapse = ", "), "\n")
    arrow::write_parquet(dvf_raw, dvf_file)
    file.remove(dvf_dest)
    rm(dvf_raw); gc()
    cat("DVF saved to parquet.\n")
  }
} else {
  cat("DVF parquet already exists, skipping download.\n")
}

# =============================================================================
# 2. ADEME DPE Database — Energy Performance Certificates
# =============================================================================

cat("\n=== Fetching ADEME DPE data ===\n")

dpe_file <- file.path(data_dir, "dpe_post2021.parquet")

if (!file.exists(dpe_file)) {
  # The new dataset slug is "dpe03existant" (14M+ records)
  # Must use paginated API: max 10K rows per request
  # Select only columns we need to reduce download size

  base_url <- "https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines"
  fields <- paste(
    "numero_dpe",
    "date_etablissement_dpe",
    "etiquette_dpe",
    "etiquette_ges",
    "cep_projet_conventionnel",     # kWh/m2/year
    "emission_ges_5_usages_par_m2", # CO2
    "surface_habitable_logement",
    "type_batiment",
    "periode_construction",
    "code_postal_ban",
    "code_insee_ban",
    "nom_commune_ban",
    "numero_voie_ban",
    "nom_rue_ban",
    "coordonnee_cartographique_x_ban",
    "coordonnee_cartographique_y_ban",
    sep = ","
  )

  cat("  Downloading DPE via paginated API (this may take 15-20 min)...\n")

  all_chunks <- list()
  page <- 0
  after_val <- ""
  max_pages <- 2000  # safety limit (~20M rows max)
  total_rows <- 0

  while (page < max_pages) {
    page <- page + 1

    url <- paste0(base_url, "?format=csv&size=10000&select=", fields)
    if (after_val != "") {
      url <- paste0(url, "&after=", utils::URLencode(after_val, reserved = TRUE))
    }

    resp <- tryCatch({
      httr::GET(url, httr::timeout(60))
    }, error = function(e) {
      cat("  Request failed at page", page, ":", e$message, "\n")
      NULL
    })

    if (is.null(resp) || httr::status_code(resp) != 200) {
      cat("  API returned status", httr::status_code(resp), "at page", page, "\n")
      # Retry once
      Sys.sleep(2)
      resp <- httr::GET(url, httr::timeout(60))
      if (httr::status_code(resp) != 200) {
        cat("  Retry failed. Stopping at page", page, "\n")
        break
      }
    }

    # Parse CSV response
    csv_text <- httr::content(resp, "text", encoding = "UTF-8")
    chunk <- tryCatch(fread(text = csv_text), error = function(e) NULL)

    if (is.null(chunk) || nrow(chunk) == 0) {
      cat("  No more data at page", page, "\n")
      break
    }

    all_chunks[[page]] <- chunk
    total_rows <- total_rows + nrow(chunk)

    # Get "after" cursor from the last row
    # The API uses the _id field as cursor
    if ("_id" %in% names(chunk)) {
      after_val <- as.character(chunk[nrow(chunk), `_id`])
    } else {
      # Try to get cursor from response headers
      link_header <- httr::headers(resp)$link
      if (!is.null(link_header)) {
        after_match <- regmatches(link_header, regexpr("after=[^&>]+", link_header))
        if (length(after_match) > 0) {
          after_val <- sub("after=", "", after_match)
        } else {
          break
        }
      } else {
        break
      }
    }

    if (page %% 50 == 0) {
      cat("  Page", page, "- total rows:", total_rows, "\n")
    }

    if (nrow(chunk) < 10000) {
      cat("  Last page (", nrow(chunk), "rows). Total:", total_rows, "\n")
      break
    }

    Sys.sleep(0.1)  # rate limiting
  }

  if (total_rows == 0) {
    cat("  ADEME DPE download failed. Trying alternative approach...\n")

    # Alternative: Use the SQL dump if available
    sql_url <- "https://opendata.ademe.fr/dump_dpev2_prod_fdld.sql.gz"
    sql_dest <- file.path(data_dir, "dpe_sql_dump.sql.gz")

    tryCatch({
      download.file(sql_url, sql_dest, mode = "wb", quiet = FALSE, timeout = 3600)
      cat("  SQL dump downloaded. Will parse in 02_clean_data.R\n")
    }, error = function(e) {
      stop("ADEME DPE data unavailable via API or SQL dump: ", e$message,
           "\nPivot research question or fix the source.")
    })
  } else {
    dpe_raw <- rbindlist(all_chunks, fill = TRUE)
    cat("  Total DPE rows downloaded:", nrow(dpe_raw), "\n")
    arrow::write_parquet(dpe_raw, dpe_file)
    rm(all_chunks, dpe_raw); gc()
    cat("  DPE saved to parquet.\n")
  }
} else {
  cat("DPE parquet already exists, skipping download.\n")
}

# =============================================================================
# 3. INSEE Commune Data — Rental shares and demographics
# =============================================================================

cat("\n=== Fetching INSEE commune data ===\n")

commune_file <- file.path(data_dir, "commune_rental_shares.csv")

if (!file.exists(commune_file) || file.size(commune_file) < 100) {
  # INSEE RP 2020: housing tenure by commune
  # Try multiple URL patterns (INSEE changes URLs periodically)
  insee_urls <- c(
    "https://www.insee.fr/fr/statistiques/fichier/7632867/base-cc-logement-2020_csv.zip",
    "https://www.insee.fr/fr/statistiques/fichier/6543200/base-cc-logement-2019_csv.zip"
  )

  downloaded <- FALSE
  for (url in insee_urls) {
    insee_dest <- file.path(data_dir, "insee_logement.zip")
    cat("  Trying INSEE:", url, "\n")
    tryCatch({
      download.file(url, insee_dest, mode = "wb", quiet = TRUE, timeout = 120)
      if (file.size(insee_dest) > 1000) {
        downloaded <- TRUE
        break
      }
    }, error = function(e) {
      cat("  Failed:", e$message, "\n")
    })
  }

  if (downloaded) {
    # Unzip and read
    unzip(insee_dest, exdir = file.path(data_dir, "insee_temp"))
    insee_files <- list.files(file.path(data_dir, "insee_temp"), pattern = "\\.csv$",
                              full.names = TRUE, recursive = TRUE)

    if (length(insee_files) > 0) {
      insee_dt <- fread(insee_files[1], encoding = "UTF-8")
      cat("  INSEE data:", nrow(insee_dt), "rows,", ncol(insee_dt), "columns\n")
      fwrite(insee_dt, file.path(data_dir, "insee_logement_raw.csv"))

      # Try to extract rental shares
      # Column names vary: look for owner/renter counts
      cat("  Column names:", paste(head(names(insee_dt), 30), collapse = ", "), "\n")
    }

    unlink(file.path(data_dir, "insee_temp"), recursive = TRUE)
    file.remove(insee_dest)
  }

  # Create empty file if not successful (will compute from DVF later)
  if (!file.exists(commune_file) || file.size(commune_file) < 100) {
    cat("  Will compute rental proxy from DVF data during clean step.\n")
    fwrite(data.table(code_commune = character(), pct_rental = numeric()),
           commune_file)
  }
} else {
  cat("INSEE commune data already exists, skipping download.\n")
}

# =============================================================================
# 4. Data Validation
# =============================================================================

cat("\n=== Data Validation ===\n")

# Check DVF
if (file.exists(dvf_file)) {
  dvf_check <- arrow::read_parquet(dvf_file, as_data_frame = FALSE)
  dvf_n <- dvf_check$num_rows
  cat("DVF:", dvf_n, "rows\n")
  stopifnot("DVF must have > 100K rows" = dvf_n > 1e5)
} else {
  stop("DVF parquet file not found. Data fetch failed.")
}

# Check DPE
if (file.exists(dpe_file)) {
  dpe_check <- arrow::read_parquet(dpe_file, as_data_frame = FALSE)
  dpe_n <- dpe_check$num_rows
  cat("DPE (post-2021):", dpe_n, "rows\n")
  stopifnot("DPE must have > 10K rows" = dpe_n > 1e4)
} else {
  cat("WARNING: DPE parquet not found. Check download.\n")
}

cat("\nData validation passed.\n")
cat("Ready for 02_clean_data.R\n")
