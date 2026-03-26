# 01_fetch_data.R — Fetch DPE diagnostic data from ADEME open API
# apep_1024: France DPE Rental Ban Bunching
#
# Data source: ADEME DPE open data (dpe03existant)
# API: https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines
# No authentication required.
# Range queries use _gte/_lte suffixes on field names.

source("00_packages.R")

BASE_URL <- "https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines"

FIELDS <- paste0(
  "conso_5_usages_par_m2_ep,",
  "etiquette_dpe,",
  "date_etablissement_dpe,",
  "code_postal_ban,",
  "code_insee_ban,",
  "surface_habitable_immeuble,",
  "type_batiment,",
  "periode_construction,",
  "emission_ges_5_usages_par_m2"
)

fetch_dpe_range <- function(conso_min, conso_max, page_size = 10000, max_pages = 200) {
  all_records <- list()
  page <- 1
  next_url <- NULL

  cat(sprintf("Fetching DPE records: %d-%d kWh/m2...\n", conso_min, conso_max))

  # Build initial URL
  initial_url <- sprintf(
    "%s?size=%d&select=%s&conso_5_usages_par_m2_ep_gte=%d&conso_5_usages_par_m2_ep_lte=%d",
    BASE_URL, page_size, FIELDS, conso_min, conso_max
  )
  current_url <- initial_url

  repeat {
    resp <- GET(current_url, timeout(120))
    if (status_code(resp) != 200) {
      cat(sprintf("  HTTP %d on page %d. Stopping.\n", status_code(resp), page))
      break
    }

    json <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(json, flatten = TRUE)
    results <- parsed$results

    if (is.null(results) || nrow(results) == 0) {
      cat(sprintf("  No more results after page %d.\n", page))
      break
    }

    all_records[[page]] <- as.data.table(results)
    n_fetched <- sum(sapply(all_records, nrow))
    total <- parsed$total
    cat(sprintf("  Page %d: %d records (total fetched: %d / %d)\n",
                page, nrow(results), n_fetched, total))

    if (n_fetched >= total || page >= max_pages) break

    # Follow the 'next' URL directly (handles encoding correctly)
    if (!is.null(parsed$`next`) && nchar(parsed$`next`) > 0) {
      current_url <- parsed$`next`
    } else {
      break
    }
    page <- page + 1
    Sys.sleep(0.3)
  }

  dt <- rbindlist(all_records, fill = TRUE)
  cat(sprintf("  Total fetched for range [%d, %d]: %d records\n\n",
              conso_min, conso_max, nrow(dt)))
  return(dt)
}

# --- Fetch data in targeted windows around thresholds ---
# Focus on ±60 kWh/m2 around each regulatory threshold
# Cap at 80 pages (800K records) per range — sufficient for bunching

cat("=== Fetching F/G threshold region (360-480 kWh/m2) ===\n")
dt_fg <- fetch_dpe_range(360, 480, max_pages = 30)

cat("=== Fetching E/F threshold region (270-390 kWh/m2) ===\n")
dt_ef <- fetch_dpe_range(270, 390, max_pages = 30)

cat("=== Fetching D/E threshold region (190-310 kWh/m2) ===\n")
dt_de <- fetch_dpe_range(190, 310, max_pages = 30)

cat("=== Fetching B/C placebo region (50-170 kWh/m2) ===\n")
dt_bc <- fetch_dpe_range(50, 170, max_pages = 30)

cat("=== Fetching high-G tail (480-700 kWh/m2) ===\n")
dt_high <- fetch_dpe_range(480, 700, max_pages = 20)

# Combine all data
dt_all <- rbindlist(list(dt_fg, dt_ef, dt_de, dt_bc, dt_high), fill = TRUE)

# Remove _score column if present
if ("_score" %in% names(dt_all)) dt_all[, `_score` := NULL]

# Remove duplicates from overlapping ranges
dt_all <- unique(dt_all)

cat(sprintf("\n=== TOTAL UNIQUE RECORDS: %d ===\n", nrow(dt_all)))

# Validate: must have real data
stopifnot("No data fetched from ADEME API" = nrow(dt_all) > 0)
stopifnot("Missing consumption variable" = "conso_5_usages_par_m2_ep" %in% names(dt_all))

# Quick summary
cat("\nLabel distribution:\n")
print(table(dt_all$etiquette_dpe, useNA = "ifany"))

cat("\nConsumption summary:\n")
print(summary(dt_all$conso_5_usages_par_m2_ep))

cat("\nYear distribution:\n")
dt_all[, year := substr(date_etablissement_dpe, 1, 4)]
print(table(dt_all$year, useNA = "ifany"))

# Save raw data
fwrite(dt_all, "../data/dpe_raw.csv")
cat("\nSaved to data/dpe_raw.csv\n")
