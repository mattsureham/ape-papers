# 01_fetch_data.R — Fetch all data for apep_0822
# Colombia Familias en Accion: Municipality-level long-run effects

setwd(file.path(dirname(sys.frame(1)$ofile %||% "."), "."))
source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

safe_download <- function(name, fun, ...) {
  cat(sprintf("=== Fetching %s ===\n", name))
  tryCatch({
    dat <- fun(...)
    cat(sprintf("  Success: %d rows x %d cols\n", nrow(dat), ncol(dat)))
    cat(sprintf("  Cols: %s\n", paste(names(dat), collapse = ", ")))
    dat
  }, error = function(e) {
    cat(sprintf("  FAILED: %s\n", conditionMessage(e)))
    NULL
  })
}

# ===========================================================================
# DIVIPOLA code table
# ===========================================================================
divipola <- safe_download("DIVIPOLA codes", divipola_table)
if (!is.null(divipola)) saveRDS(divipola, file.path(data_dir, "divipola.rds"))

# ===========================================================================
# 2018 Census datasets from ColOpenData
# ===========================================================================
census_datasets <- list(
  census_households = "DANE_CNPVH_2018_3HM",      # households by head type
  census_population = "DANE_CNPVPD_2018_1PM",      # population by age/sex
  census_literacy   = "DANE_CNPVPD_2018_16PM",     # literacy rates
  census_education  = "DANE_CNPVPD_2018_17PM",     # education attainment (alt)
  census_employment = "DANE_CNPVPS_2018_5PM",      # economic activity
  census_services   = "DANE_CNPVV_2018_8VM",       # public services
  census_housing    = "DANE_CNPVV_2018_7VM",       # housing floor materials
  census_stratum    = "DANE_CNPVV_2018_10VM"       # energy stratum
)

for (nm in names(census_datasets)) {
  dat <- safe_download(nm, download_demographic, census_datasets[[nm]])
  if (!is.null(dat)) saveRDS(dat, file.path(data_dir, paste0(nm, ".rds")))
}

# ===========================================================================
# datos.gov.co API calls for FeA and historical data
# ===========================================================================
cat("\n=== Searching datos.gov.co for historical data ===\n")

api_datasets <- list(
  list(
    name = "nbi_municipal",
    urls = c(
      "https://www.datos.gov.co/resource/9gp7-gm3u.json?$limit=50000",
      "https://www.datos.gov.co/resource/x8h8-6n9q.json?$limit=50000"
    )
  ),
  list(
    name = "pop_projections",
    urls = c(
      "https://www.datos.gov.co/resource/y2n9-g953.json?$limit=50000",
      "https://www.datos.gov.co/resource/csb9-eamk.json?$limit=50000",
      "https://www.datos.gov.co/resource/cg4w-dwrw.json?$limit=50000"
    )
  ),
  list(
    name = "fea_beneficiaries",
    urls = c(
      "https://www.datos.gov.co/resource/qy8q-ri29.json?$limit=50000",
      "https://www.datos.gov.co/resource/74zb-anis.json?$limit=50000",
      "https://www.datos.gov.co/resource/wqsr-u2w2.json?$limit=50000"
    )
  )
)

for (ds in api_datasets) {
  found <- FALSE
  for (url in ds$urls) {
    cat(sprintf("  Trying %s from %s...\n", ds$name, url))
    resp <- tryCatch(
      httr::GET(url, httr::timeout(30)),
      error = function(e) NULL
    )
    if (!is.null(resp) && httr::status_code(resp) == 200) {
      dat <- tryCatch(
        jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")),
        error = function(e) NULL
      )
      if (!is.null(dat) && is.data.frame(dat) && nrow(dat) > 0) {
        cat(sprintf("  Found %s: %d rows\n", ds$name, nrow(dat)))
        cat(sprintf("  Cols: %s\n", paste(names(dat), collapse = ", ")))
        saveRDS(dat, file.path(data_dir, paste0(ds$name, ".rds")))
        found <- TRUE
        break
      }
    }
  }
  if (!found) cat(sprintf("  %s: no data found\n", ds$name))
}

# ===========================================================================
# Try Socrata SODA API search for FeA/MFA coverage
# ===========================================================================
cat("\n=== Searching datos.gov.co catalog for FeA datasets ===\n")

# Search the Socrata discovery API
discovery_url <- paste0(
  "https://api.us.socrata.com/api/catalog/v1?",
  "domains=www.datos.gov.co&",
  "q=familias%20accion&",
  "limit=10"
)
disc_resp <- tryCatch(
  httr::GET(discovery_url, httr::timeout(30)),
  error = function(e) NULL
)
if (!is.null(disc_resp) && httr::status_code(disc_resp) == 200) {
  disc_data <- jsonlite::fromJSON(httr::content(disc_resp, "text", encoding = "UTF-8"))
  if (!is.null(disc_data$results)) {
    cat("Found", nrow(disc_data$results), "FeA-related datasets\n")
    for (i in seq_len(min(nrow(disc_data$results), 5))) {
      res <- disc_data$results[i, ]
      cat(sprintf("  [%s] %s\n", res$resource$id, res$resource$name))
    }
  }
}

# Search for MPI data
cat("\n=== Searching for MPI (IPM) data ===\n")
mpi_discovery_url <- paste0(
  "https://api.us.socrata.com/api/catalog/v1?",
  "domains=www.datos.gov.co&",
  "q=indice%20pobreza%20multidimensional%20municipal&",
  "limit=10"
)
mpi_resp <- tryCatch(
  httr::GET(mpi_discovery_url, httr::timeout(30)),
  error = function(e) NULL
)
if (!is.null(mpi_resp) && httr::status_code(mpi_resp) == 200) {
  mpi_disc <- jsonlite::fromJSON(httr::content(mpi_resp, "text", encoding = "UTF-8"))
  if (!is.null(mpi_disc$results)) {
    cat("Found", nrow(mpi_disc$results), "MPI-related datasets\n")
    for (i in seq_len(min(nrow(mpi_disc$results), 5))) {
      res <- mpi_disc$results[i, ]
      cat(sprintf("  [%s] %s\n", res$resource$id, res$resource$name))
    }
  }
}

# ===========================================================================
# SUMMARY
# ===========================================================================
cat("\n\n========== DATA FETCHING SUMMARY ==========\n")
files <- list.files(data_dir, pattern = "\\.rds$")
cat("Total files saved:", length(files), "\n")
for (f in files) {
  obj <- readRDS(file.path(data_dir, f))
  cat(sprintf("  %-30s %7d rows x %2d cols\n", f, nrow(obj), ncol(obj)))
}
