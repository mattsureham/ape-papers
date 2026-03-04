## 01_fetch_data.R — Download DVF data (hybrid: API 2014-2019 + bulk 2020-2025)
## apep_0499: Action Cœur de Ville and Property Markets
##
## Strategy:
##   1. Download ACV city list
##   2. Load DVF bulk CSV (2020-2025), sample controls
##   3. Fast parallel fetch from Cerema API for 2014-2019
##   4. Harmonize and combine

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================
# 1. Download ACV city list
# ==============================================================
cat("Downloading ACV city list...\n")
acv_url <- "https://static.data.gouv.fr/resources/programme-action-coeur-de-ville/20250924-154200/liste-acv-com2025-20250704.csv"
acv_file <- file.path(data_dir, "acv_cities.csv")
if (!file.exists(acv_file)) {
  download.file(acv_url, acv_file, quiet = TRUE)
}
acv <- read_csv(acv_file, show_col_types = FALSE)
cat(sprintf("ACV cities: %d communes, %d programs\n", nrow(acv), n_distinct(acv$id_acv)))

acv_codes <- unique(acv$insee_com)
acv_deps <- unique(substr(acv_codes, 1, 2))

# ==============================================================
# 2. Load DVF bulk data (2020-2025)
# ==============================================================
cat("Loading DVF bulk data...\n")
dvf_gz <- file.path(data_dir, "dvf.csv.gz")

if (!file.exists(dvf_gz)) {
  dvf_url <- "https://static.data.gouv.fr/resources/demandes-de-valeurs-foncieres-geolocalisees/20251105-140205/dvf.csv.gz"
  download.file(dvf_url, dvf_gz, mode = "wb", quiet = FALSE)
}

dvf_bulk <- fread(cmd = paste("gunzip -c", dvf_gz), showProgress = TRUE)

# Build commune code
if ("code_commune" %in% names(dvf_bulk)) {
  sample_val <- as.character(dvf_bulk$code_commune[1])
  if (nchar(sample_val) == 5) {
    dvf_bulk[, commune_full := as.character(code_commune)]
  } else if ("code_departement" %in% names(dvf_bulk)) {
    dvf_bulk[, commune_full := paste0(sprintf("%02s", code_departement),
                                       sprintf("%03s", code_commune))]
  }
} else if ("code_insee" %in% names(dvf_bulk)) {
  dvf_bulk[, commune_full := as.character(code_insee)]
}

dvf_bulk <- dvf_bulk[substr(commune_full, 1, 2) %in% acv_deps]
cat(sprintf("Bulk data filtered: %d rows\n", nrow(dvf_bulk)))

# Sample controls: 3 per département
set.seed(42)
all_communes <- unique(dvf_bulk$commune_full)
ctrl_dt <- data.table(commune = setdiff(all_communes, acv_codes),
                      dep = substr(setdiff(all_communes, acv_codes), 1, 2))
ctrl_sample <- ctrl_dt[, .SD[sample(.N, min(.N, 3))], by = dep]
control_codes <- ctrl_sample$commune

analysis_communes <- c(acv_codes, control_codes)
cat(sprintf("Analysis communes: %d ACV + %d control = %d total\n",
            length(acv_codes), length(control_codes), length(analysis_communes)))

dvf_bulk <- dvf_bulk[commune_full %in% analysis_communes]

# Free memory from the raw bulk data
gc()

# ==============================================================
# 3. Fast parallel API fetch for 2014-2019
# ==============================================================
api_cache <- file.path(data_dir, "dvf_api_2014_2019.rds")

if (file.exists(api_cache)) {
  cat("Loading cached API data...\n")
  dvf_api_all <- readRDS(api_cache)
} else {
  cat("\nFetching 2014-2019 from Cerema API (parallel)...\n")

  base_url <- "https://apidf-preprod.cerema.fr/dvf_opendata/mutations/"

  # Step 1: Get counts for all communes (fast: 1 record per request)
  cat("  Getting mutation counts...\n")
  count_urls <- paste0(base_url, "?code_insee=", analysis_communes,
                       "&anneemut_min=2014&anneemut_max=2019&page_size=1")

  count_reqs <- lapply(count_urls, function(u) {
    request(u) |> req_timeout(30) |> req_error(is_error = function(resp) FALSE)
  })

  # Fetch counts in parallel batches
  counts <- integer(length(analysis_communes))
  batch_sz <- 20
  n_batches <- ceiling(length(count_reqs) / batch_sz)

  for (b in seq_len(n_batches)) {
    idx <- ((b-1)*batch_sz + 1):min(b*batch_sz, length(count_reqs))
    resps <- req_perform_parallel(count_reqs[idx], on_error = "continue")
    for (j in seq_along(idx)) {
      tryCatch({
        body <- resp_body_json(resps[[j]])
        counts[idx[j]] <- body$count %||% 0L
      }, error = function(e) {
        counts[idx[j]] <<- 0L
      })
    }
    if (b %% 5 == 0) cat(sprintf("    Counts: %d/%d batches\n", b, n_batches))
  }

  cat(sprintf("  Total mutations to fetch: %d across %d communes\n",
              sum(counts), sum(counts > 0)))

  # Step 2: Build all page URLs
  cat("  Building page URLs...\n")
  page_urls <- character(0)
  page_commune <- character(0)

  for (i in seq_along(analysis_communes)) {
    if (counts[i] == 0) next
    n_pages <- ceiling(min(counts[i], 10000) / 500)  # Cap at 10K per commune
    for (p in seq_len(n_pages)) {
      page_urls <- c(page_urls,
        paste0(base_url, "?code_insee=", analysis_communes[i],
               "&anneemut_min=2014&anneemut_max=2019&page_size=500&page=", p))
      page_commune <- c(page_commune, analysis_communes[i])
    }
  }

  cat(sprintf("  Total API pages to fetch: %d\n", length(page_urls)))

  # Step 3: Fetch all pages in parallel batches
  cat("  Fetching pages...\n")
  all_mutations <- vector("list", length(page_urls))
  fetch_batch <- 15  # Concurrent requests per batch
  n_fetch_batches <- ceiling(length(page_urls) / fetch_batch)

  for (b in seq_len(n_fetch_batches)) {
    idx <- ((b-1)*fetch_batch + 1):min(b*fetch_batch, length(page_urls))

    reqs <- lapply(page_urls[idx], function(u) {
      request(u) |> req_timeout(45) |> req_error(is_error = function(resp) FALSE)
    })

    resps <- req_perform_parallel(reqs, on_error = "continue")

    for (j in seq_along(idx)) {
      tryCatch({
        body <- resp_body_json(resps[[j]])
        results <- body$results
        if (length(results) > 0) {
          rows <- lapply(results, function(r) {
            data.table(
              commune_full = if (length(r$l_codinsee) > 0) r$l_codinsee[[1]] else NA_character_,
              date_mutation = as.character(r$datemut %||% NA),
              nature_mutation = as.character(r$libnatmut %||% NA),
              valeur_fonciere = as.numeric(r$valeurfonc %||% NA),
              code_type_bien = as.character(r$codtypbien %||% NA),
              lib_type_bien = as.character(r$libtypbien %||% NA),
              surface_reelle_bati = as.numeric(r$sbati %||% NA),
              surface_terrain = as.numeric(r$sterr %||% NA),
              year = as.integer(r$anneemut %||% NA),
              vefa = as.logical(r$vefa %||% FALSE)
            )
          })
          all_mutations[[idx[j]]] <- rbindlist(rows)
        }
      }, error = function(e) NULL)
    }

    if (b %% 10 == 0 || b == n_fetch_batches) {
      n_total <- sum(sapply(all_mutations, function(x) if(!is.null(x)) nrow(x) else 0L))
      cat(sprintf("    Batch %d/%d | %d mutations fetched\n", b, n_fetch_batches, n_total))
    }

    # Save checkpoint every 50 batches
    if (b %% 50 == 0) {
      partial <- rbindlist(all_mutations[!sapply(all_mutations, is.null)])
      saveRDS(partial, file.path(data_dir, "dvf_api_partial.rds"))
    }
  }

  dvf_api_all <- rbindlist(all_mutations[!sapply(all_mutations, is.null)])
  saveRDS(dvf_api_all, api_cache)
  cat(sprintf("\nAPI fetch complete: %d mutations\n", nrow(dvf_api_all)))
}

cat(sprintf("API data: %d rows, years %d-%d\n",
            nrow(dvf_api_all), min(dvf_api_all$year), max(dvf_api_all$year)))

# ==============================================================
# 4. Harmonize and combine
# ==============================================================
cat("\nHarmonizing...\n")

dvf_api_all[, code_type_local := fcase(
  substr(code_type_bien, 1, 2) == "11", 1L,
  substr(code_type_bien, 1, 2) == "12", 2L,
  substr(code_type_bien, 1, 2) == "13", 3L,
  substr(code_type_bien, 1, 2) == "14", 4L,
  substr(code_type_bien, 1, 1) == "2", NA_integer_,
  default = NA_integer_
)]

dvf_api_all[, code_nature_culture := fifelse(
  substr(code_type_bien, 1, 1) == "2", "land", NA_character_
)]

api_harmonized <- dvf_api_all[, .(
  commune_full, date_mutation, nature_mutation, valeur_fonciere,
  code_type_local, code_nature_culture,
  surface_reelle_bati, surface_terrain, year,
  source = "api_2014_2019"
)]

# CRITICAL: Aggregate bulk data to mutation level
# Bulk DVF has multiple rows per transaction (one per lot/parcel)
# API data is already at mutation (transaction) level
# Must aggregate to match granularity
dvf_bulk[, year := as.integer(substr(date_mutation, 1, 4))]

cat("Aggregating bulk data to mutation level...\n")
cat(sprintf("  Bulk rows before: %d\n", nrow(dvf_bulk)))

bulk_mutations <- dvf_bulk[, .(
  commune_full = commune_full[1],
  date_mutation = as.character(date_mutation[1]),
  nature_mutation = as.character(nature_mutation[1]),
  valeur_fonciere = as.numeric(valeur_fonciere[1]),
  code_type_local = as.integer(na.omit(code_type_local)[1]),
  code_nature_culture = {
    cnc <- as.character(na.omit(code_nature_culture))
    if (length(cnc) > 0) cnc[1] else NA_character_
  },
  surface_reelle_bati = sum(as.numeric(surface_reelle_bati), na.rm = TRUE),
  surface_terrain = max(as.numeric(surface_terrain), na.rm = TRUE),
  year = year[1]
), by = id_mutation]

bulk_mutations[surface_reelle_bati == 0, surface_reelle_bati := NA_real_]
bulk_mutations[is.infinite(surface_terrain) | surface_terrain == 0,
               surface_terrain := NA_real_]

cat(sprintf("  Bulk mutations after: %d\n", nrow(bulk_mutations)))

bulk_harmonized <- bulk_mutations[, .(
  commune_full, date_mutation, nature_mutation, valeur_fonciere,
  code_type_local, code_nature_culture,
  surface_reelle_bati, surface_terrain, year,
  source = "bulk_2020_2025"
)]

dvf_combined <- rbind(api_harmonized, bulk_harmonized)
dvf_combined[, acv := commune_full %in% acv_codes]

cat(sprintf("Combined: %d rows (%d API + %d bulk)\n",
            nrow(dvf_combined),
            sum(dvf_combined$source == "api_2014_2019"),
            sum(dvf_combined$source == "bulk_2020_2025")))
cat(sprintf("Years: %d-%d | ACV: %d | Control: %d\n",
            min(dvf_combined$year), max(dvf_combined$year),
            sum(dvf_combined$acv), sum(!dvf_combined$acv)))

# ==============================================================
# 5. Save
# ==============================================================
saveRDS(dvf_combined, file.path(data_dir, "dvf_filtered.rds"))
saveRDS(acv, file.path(data_dir, "acv_info.rds"))
saveRDS(data.table(commune = analysis_communes,
                   acv = analysis_communes %in% acv_codes,
                   dep = substr(analysis_communes, 1, 2)),
        file.path(data_dir, "analysis_communes.rds"))

rm(dvf_bulk); gc()

cat("\n=== DATA FETCH COMPLETE ===\n")
