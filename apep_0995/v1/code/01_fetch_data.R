## 01_fetch_data.R — Fetch election results and EPCI composition
## apep_0986: Forced EPCI Mergers and RN Voting
## ALL DATA IS REAL — NO SIMULATIONS, NO FALLBACKS

source("00_packages.R")
data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. Commune-to-EPCI mapping from geo.api.gouv.fr (supports historical dates)
## ============================================================================
cat("\n=== Fetching commune-to-EPCI mapping ===\n")

fetch_communes <- function(date_str) {
  url <- paste0("https://geo.api.gouv.fr/communes?fields=code,nom,population,",
                "codeDepartement,codeRegion,codeEpci&limit=50000&date=", date_str)
  cat("  Fetching communes for date:", date_str, "\n")
  resp <- httr::GET(url, httr::timeout(120))
  httr::stop_for_status(resp, paste("fetch communes for", date_str))
  dt <- as.data.table(jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8")))
  cat("  Downloaded", nrow(dt), "communes\n")
  dt
}

## Pre-reform (2016) and post-reform (2017) commune-EPCI mapping
communes_2016 <- fetch_communes("2016-12-31")
communes_2017 <- fetch_communes("2017-01-02")

## Also get EPCI details (name, population) for treatment intensity
fetch_epcis <- function(date_str) {
  url <- paste0("https://geo.api.gouv.fr/epcis?fields=nom,population&limit=5000&date=", date_str)
  cat("  Fetching EPCIs for date:", date_str, "\n")
  resp <- httr::GET(url, httr::timeout(120))
  httr::stop_for_status(resp, paste("fetch EPCIs for", date_str))
  dt <- as.data.table(jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8")))
  cat("  Downloaded", nrow(dt), "EPCIs\n")
  dt
}

epcis_2016 <- fetch_epcis("2016-12-31")
epcis_2017 <- fetch_epcis("2017-01-02")

cat(sprintf("  EPCIs: %d (2016) -> %d (2017). Net reduction: %d\n",
            nrow(epcis_2016), nrow(epcis_2017),
            nrow(epcis_2016) - nrow(epcis_2017)))

## Save intermediate
fwrite(communes_2016, file.path(data_dir, "communes_2016.csv"))
fwrite(communes_2017, file.path(data_dir, "communes_2017.csv"))
fwrite(epcis_2016, file.path(data_dir, "epcis_2016.csv"))
fwrite(epcis_2017, file.path(data_dir, "epcis_2017.csv"))

## ============================================================================
## 2. Election Data — Commune-level results from data.gouv.fr
## ============================================================================
cat("\n=== Fetching Election Data ===\n")

## Helper: search and download from data.gouv.fr
search_datagouv <- function(query, n = 10) {
  url <- paste0("https://www.data.gouv.fr/api/1/datasets/?q=",
                URLencode(query), "&page_size=", n)
  resp <- httr::GET(url, httr::timeout(60))
  httr::stop_for_status(resp, paste("search data.gouv.fr for:", query))
  httr::content(resp, as = "parsed")$data
}

download_resource <- function(url, dest) {
  if (file.exists(dest)) {
    cat("  Already cached:", basename(dest), "\n")
    return(invisible(TRUE))
  }
  cat("  Downloading:", substr(url, 1, 80), "...\n")
  resp <- httr::GET(url, httr::write_disk(dest, overwrite = TRUE),
                    httr::timeout(300))
  httr::stop_for_status(resp, paste("download", basename(dest)))
  cat("  Saved:", basename(dest), "(", file.size(dest), "bytes)\n")
  invisible(TRUE)
}

## Presidential elections — search for each year's commune-level 1st round results
## FN/RN candidates by year:
## 2002: LE PEN Jean-Marie  | 2007: LE PEN Jean-Marie  | 2012: LE PEN Marine
## 2017: LE PEN Marine      | 2022: LE PEN Marine

elections_meta <- list(
  list(year = 2002, type = "presidentielle", query = "resultats presidentielle 2002",
       candidate = "LE PEN", first_name = "Jean-Marie"),
  list(year = 2007, type = "presidentielle", query = "resultats presidentielle 2007",
       candidate = "LE PEN", first_name = "Jean-Marie"),
  list(year = 2012, type = "presidentielle", query = "resultats presidentielle 2012",
       candidate = "LE PEN", first_name = "Marine"),
  list(year = 2017, type = "presidentielle", query = "presidentielle 2017 1er tour commune",
       candidate = "LE PEN", first_name = "Marine"),
  list(year = 2022, type = "presidentielle", query = "presidentielle 2022 1er tour commune",
       candidate = "LE PEN", first_name = "Marine"),
  list(year = 2014, type = "europeenne", query = "europeennes 2014 resultats commune"),
  list(year = 2019, type = "europeenne", query = "europeennes 2019 resultats commune"),
  list(year = 2024, type = "europeenne", query = "europeennes 2024 resultats commune")
)

election_files <- list()

for (elec in elections_meta) {
  cat(sprintf("\n--- %s %d ---\n", elec$type, elec$year))
  dest <- file.path(data_dir, sprintf("election_%s_%d.csv", elec$type, elec$year))

  if (file.exists(dest)) {
    cat("  Already cached\n")
    election_files[[length(election_files) + 1]] <- list(
      year = elec$year, type = elec$type, path = dest
    )
    next
  }

  results <- search_datagouv(elec$query, n = 10)
  cat("  Found", length(results), "datasets\n")

  found <- FALSE
  for (ds in results) {
    title <- tolower(ds$title %||% "")
    ## Match: must contain the year
    if (!grepl(as.character(elec$year), title)) next

    ## Get full dataset with all resources
    ds_full <- tryCatch({
      resp <- httr::GET(paste0("https://www.data.gouv.fr/api/1/datasets/", ds$id, "/"),
                        httr::timeout(30))
      httr::stop_for_status(resp)
      httr::content(resp, as = "parsed")
    }, error = function(e) NULL)
    if (is.null(ds_full)) next

    cat("  Checking dataset:", ds_full$title, "(", length(ds_full$resources), "resources)\n")

    ## Find commune-level CSV resource
    for (r in ds_full$resources) {
      rname <- tolower(r$title %||% "")
      rurl <- tolower(r$url %||% "")

      is_commune <- grepl("commune", rname) || grepl("commune", rurl)
      is_csv <- grepl("csv|txt", tolower(r$format %||% "")) ||
        grepl("\\.(csv|txt)$", rurl)
      is_xlsx <- grepl("xlsx|xls", tolower(r$format %||% "")) ||
        grepl("\\.(xlsx|xls)$", rurl)
      ## For presidential: avoid 2nd round
      is_bad <- grepl("2e|2nd|second|tour.?2|t2", rname)

      if ((is_commune || is_csv || is_xlsx) && !is_bad) {
        ext <- tools::file_ext(r$url)
        if (ext == "") ext <- "csv"
        tmp_dest <- file.path(data_dir, sprintf("election_%s_%d_raw.%s",
                                                  elec$type, elec$year, ext))
        ok <- tryCatch({
          download_resource(r$url, tmp_dest)
          TRUE
        }, error = function(e) {
          cat("  Download failed:", e$message, "\n")
          FALSE
        })
        if (ok && file.size(tmp_dest) > 1000) {
          file.rename(tmp_dest, dest)
          election_files[[length(election_files) + 1]] <- list(
            year = elec$year, type = elec$type, path = dest
          )
          found <- TRUE
          break
        }
      }
    }
    if (found) break
  }

  if (!found) {
    cat(sprintf("  WARNING: Could not find data for %s %d\n", elec$type, elec$year))
  }
}

## ============================================================================
## 3. Commune characteristics — population from INSEE
## ============================================================================
cat("\n=== Fetching commune population (INSEE COG) ===\n")

## The COG data is available from INSEE
cog_url <- "https://www.insee.fr/fr/statistiques/fichier/7766585/cog_ensemble_2024_csv.zip"
cog_dest <- file.path(data_dir, "cog_2024.zip")
download_resource(cog_url, cog_dest)

if (file.exists(cog_dest)) {
  unzip(cog_dest, exdir = file.path(data_dir, "cog_2024"))
  cat("  Unzipped COG data\n")
}

## ============================================================================
## 4. Summary and validation
## ============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat("Commune-EPCI mapping: 2016 (", nrow(communes_2016), "communes) and 2017 (",
    nrow(communes_2017), "communes)\n")
cat("EPCI details: 2016 (", nrow(epcis_2016), ") and 2017 (", nrow(epcis_2017), ")\n")
cat("Election files downloaded:", length(election_files), "\n")
for (ef in election_files) {
  cat(sprintf("  %s %d: %s (%s bytes)\n", ef$type, ef$year,
              basename(ef$path), format(file.size(ef$path), big.mark = ",")))
}

## List all files in data directory
cat("\nAll files in data/:\n")
files <- list.files(data_dir, recursive = TRUE)
for (f in files) {
  cat(sprintf("  %s (%s)\n", f, format(file.size(file.path(data_dir, f)), big.mark = ",")))
}

## Validate minimum requirements
if (nrow(communes_2016) < 30000 || nrow(communes_2017) < 30000) {
  stop("FATAL: Too few communes downloaded from geo.api.gouv.fr")
}
cat("\nMinimum data requirements met.\n")
