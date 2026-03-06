# ==============================================================================
# 01_fetch_data.R — Fetch all data sources for FTTH-Polarization analysis
# APEP apep_0536
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 1. ARCEP FTTH Deployment — Department × Quarter
# Source: data.gouv.fr "Le marche du haut et tres haut debit fixe (deploiements)"
# The observatory Excel files contain department-level quarterly FTTH stats
# ==============================================================================

cat("=== Fetching ARCEP FTTH deployment data ===\n")

# We fetch the latest observatory file which contains historical quarterly data
# in multiple tabs (national + by zone + by department)
arcep_url <- "https://static.data.gouv.fr/resources/le-marche-du-haut-et-tres-haut-debit-fixe-deploiements/20251209-164140/2025t3-obs-hd-thd-deploiement-vf.xlsx"

arcep_file <- file.path(data_dir, "arcep_ftth_deployment.xlsx")
tryCatch({
  download.file(arcep_url, arcep_file, mode = "wb", quiet = TRUE)
  cat("  ARCEP observatory file downloaded:", file.size(arcep_file), "bytes\n")
}, error = function(e) stop("ARCEP deployment data unavailable: ", e$message,
                            "\nThis is the core treatment variable. Cannot proceed."))

# Also fetch the community-sourced FTTH panel (2017-2025) for robustness
ftth_panel_url <- "https://www.data.gouv.fr/api/1/datasets/r/0728767b-4d26-4f56-88c4-6d6369ed4ecf"
ftth_panel_file <- file.path(data_dir, "ftth_panel_2017_2025.csv")
tryCatch({
  download.file(ftth_panel_url, ftth_panel_file, mode = "wb", quiet = TRUE)
  cat("  FTTH panel (2017-2025) downloaded:", file.size(ftth_panel_file), "bytes\n")
}, error = function(e) {
  warning("FTTH panel download failed: ", e$message, "\nWill rely on ARCEP observatory only.")
})

# ==============================================================================
# 2. Election Results — All elections, commune level
# Source: data.gouv.fr "Donnees des elections agregees"
# ==============================================================================

cat("\n=== Fetching election results ===\n")

# General results (turnout, blank/null votes by bureau de vote)
elections_general_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.csv"
elections_general_file <- file.path(data_dir, "elections_general_results.csv")
tryCatch({
  download.file(elections_general_url, elections_general_file, mode = "wb", quiet = TRUE)
  cat("  Election general results downloaded:", file.size(elections_general_file), "bytes\n")
}, error = function(e) stop("Election general results unavailable: ", e$message,
                            "\nThis is the core outcome data. Cannot proceed."))

# Candidate results (votes per candidate per bureau de vote)
elections_cand_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.csv"
elections_cand_file <- file.path(data_dir, "elections_candidats_results.csv")
tryCatch({
  download.file(elections_cand_url, elections_cand_file, mode = "wb", quiet = TRUE)
  cat("  Election candidate results downloaded:", file.size(elections_cand_file), "bytes\n")
}, error = function(e) stop("Election candidate results unavailable: ", e$message,
                            "\nThis is the core outcome data. Cannot proceed."))

# Political nuances dictionary
nuances_url <- "https://static.data.gouv.fr/resources/donnees-des-elections-agregees/20260216-092608/nuances-politiques.csv"
nuances_file <- file.path(data_dir, "nuances_politiques.csv")
tryCatch({
  download.file(nuances_url, nuances_file, mode = "wb", quiet = TRUE)
  cat("  Political nuances dictionary downloaded\n")
}, error = function(e) warning("Nuances file failed: ", e$message))

# ==============================================================================
# 3. GDELT — French news articles mentioning misinformation/conspiracy themes
# We use the GDELT DOC API to query French-language articles
# Geolocated to France, filtered by misinformation/conspiracy keywords
# ==============================================================================

cat("\n=== Fetching GDELT data (exploratory) ===\n")

# GDELT DOC API — query French articles mentioning misinformation themes
# The API returns up to 250 articles per query with geographic metadata
# We query month by month for the analysis period

gdelt_dir <- file.path(data_dir, "gdelt")
dir.create(gdelt_dir, recursive = TRUE, showWarnings = FALSE)

# Define search terms (French misinformation/conspiracy vocabulary)
search_terms <- c(
  "desinformation",
  "complotisme",
  "fake news",
  "infox",
  "theorie du complot",
  "complotiste",
  "antivax",
  "conspirationnisme"
)

# Fact-checking brands
factcheck_terms <- c(
  "Les Decodeurs",
  "CheckNews",
  "AFP Factuel",
  "Desintox",
  "fact-checking"
)

# GDELT DOC 2.0 API base URL
gdelt_base <- "https://api.gdeltproject.org/api/v2/doc/doc"

# Function to query GDELT for a time range and search terms
query_gdelt <- function(terms, start_date, end_date, mode = "timelinevol") {
  query_str <- paste0('("', paste(terms, collapse = '" OR "'), '")')

  params <- list(
    query = paste0(query_str, " sourcelang:fra sourcecountry:FR"),
    mode = mode,
    startdatetime = format(start_date, "%Y%m%d%H%M%S"),
    enddatetime = format(end_date, "%Y%m%d%H%M%S"),
    format = "csv"
  )

  url <- paste0(gdelt_base, "?", paste(names(params), sapply(params, URLencode, reserved = TRUE), sep = "=", collapse = "&"))

  tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
      if (nchar(content_text) > 50) {
        return(fread(text = content_text))
      }
    }
    return(NULL)
  }, error = function(e) {
    message("  GDELT query failed: ", e$message)
    return(NULL)
  })
}

# Query GDELT for misinformation timeline (volume over time)
# Use timelinevol mode — returns daily volume of matching articles
cat("  Querying GDELT misinformation timeline...\n")
gdelt_misinfo <- query_gdelt(
  search_terms,
  start_date = as.Date("2015-01-01"),
  end_date = as.Date("2024-12-31"),
  mode = "timelinevol"
)

if (!is.null(gdelt_misinfo) && nrow(gdelt_misinfo) > 0) {
  fwrite(gdelt_misinfo, file.path(gdelt_dir, "gdelt_misinfo_timeline.csv"))
  cat("  GDELT misinformation timeline:", nrow(gdelt_misinfo), "rows\n")
} else {
  cat("  WARNING: GDELT misinformation timeline empty. Will try alternative queries.\n")
}

# Query GDELT for fact-checking timeline
cat("  Querying GDELT fact-checking timeline...\n")
gdelt_factcheck <- query_gdelt(
  factcheck_terms,
  start_date = as.Date("2015-01-01"),
  end_date = as.Date("2024-12-31"),
  mode = "timelinevol"
)

if (!is.null(gdelt_factcheck) && nrow(gdelt_factcheck) > 0) {
  fwrite(gdelt_factcheck, file.path(gdelt_dir, "gdelt_factcheck_timeline.csv"))
  cat("  GDELT fact-checking timeline:", nrow(gdelt_factcheck), "rows\n")
} else {
  cat("  WARNING: GDELT fact-checking timeline empty.\n")
}

# Query GDELT for geographic distribution (tonechart gives location data)
cat("  Querying GDELT geographic distribution...\n")
gdelt_geo <- query_gdelt(
  search_terms,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2024-12-31"),
  mode = "timelinevol"
)

if (!is.null(gdelt_geo) && nrow(gdelt_geo) > 0) {
  fwrite(gdelt_geo, file.path(gdelt_dir, "gdelt_geo_misinfo.csv"))
  cat("  GDELT geographic data:", nrow(gdelt_geo), "rows\n")
} else {
  cat("  WARNING: GDELT geographic data empty.\n")
}

cat("  GDELT note: DOC API provides national-level timelines.\n")
cat("  Department-level variation requires GKG bulk data or BigQuery.\n")
cat("  GDELT results are EXPLORATORY — paper stands on elections alone.\n")

# ==============================================================================
# 4. INSEE — Department-level demographics and economic controls
# Source: INSEE BDM/SDMX API
# ==============================================================================

cat("\n=== Fetching INSEE controls ===\n")

# INSEE BDM SDMX endpoint for department-level unemployment (taux de chomage)
# Series: CHOMAGE-TRIM-DEPT
insee_base <- "https://api.insee.fr/sdmx-ws/rest"

# Department-level quarterly unemployment rate
# BDM identifier: 001688371 to 001688466 (one per department)
# Use the bulk series endpoint
chomage_url <- paste0(insee_base, "/data/CHOMAGE-TRIM-DEPT?startPeriod=2012-Q1&endPeriod=2024-Q4")

insee_chomage_file <- file.path(data_dir, "insee_unemployment_dept.xml")
tryCatch({
  resp <- httr::GET(chomage_url, httr::timeout(60),
                    httr::add_headers(Accept = "application/vnd.sdmx.data+csv;version=1.0.0"))
  if (httr::status_code(resp) == 200) {
    content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    writeLines(content_text, file.path(data_dir, "insee_unemployment_dept.csv"))
    cat("  INSEE unemployment data downloaded\n")
  } else {
    cat("  INSEE SDMX returned status:", httr::status_code(resp), "\n")
    cat("  Will use alternative source for unemployment data.\n")
  }
}, error = function(e) {
  cat("  INSEE SDMX query failed:", e$message, "\n")
  cat("  Will fetch unemployment data from data.gouv.fr alternative.\n")
})

# Alternative: fetch department-level unemployment from data.gouv.fr
# Published by INSEE as "Taux de chomage localise par departement"
chomage_alt_url <- "https://www.data.gouv.fr/api/1/datasets/r/8e3b97c9-42c7-4603-99b7-8e0eae8f35c5"
chomage_alt_file <- file.path(data_dir, "chomage_dept_datagouv.csv")
tryCatch({
  download.file(chomage_alt_url, chomage_alt_file, mode = "wb", quiet = TRUE)
  if (file.exists(chomage_alt_file) && file.size(chomage_alt_file) > 100) {
    cat("  Alternative unemployment data downloaded:", file.size(chomage_alt_file), "bytes\n")
  }
}, error = function(e) cat("  Alternative unemployment also failed:", e$message, "\n"))

# Department-level population
# Source: INSEE estimation de population
pop_url <- "https://www.data.gouv.fr/api/1/datasets/r/f3c1e0da-c7f0-4f80-8e63-34d00e6280cd"
pop_file <- file.path(data_dir, "population_dept.csv")
tryCatch({
  download.file(pop_url, pop_file, mode = "wb", quiet = TRUE)
  if (file.exists(pop_file) && file.size(pop_file) > 100) {
    cat("  Population data downloaded:", file.size(pop_file), "bytes\n")
  }
}, error = function(e) cat("  Population download failed:", e$message, "\n"))

# ==============================================================================
# 5. Copper closure lots — ARCEP schedule
# ==============================================================================

cat("\n=== Fetching copper closure schedule ===\n")

# The copper closure plan is published by ARCEP as a trajectory file
# We'll extract lot assignments from the ARCEP page
# For now, hard-code the lot structure from ARCEP's published schedule:
copper_lots <- data.table(
  lot = c(1, 2, 3, 4, 5),
  n_communes = c(162, 2623, 2097, 6843, 10488),
  commercial_closure = as.Date(c("2024-01-31", "2026-01-31", "2027-01-31", "2028-01-31", "2029-01-31")),
  technical_closure = as.Date(c("2025-01-31", "2027-01-31", "2028-01-31", "2029-01-31", "2030-01-31"))
)
fwrite(copper_lots, file.path(data_dir, "copper_closure_lots.csv"))
cat("  Copper closure lot schedule saved (5 lots, 22,213 communes total)\n")

# Try to fetch the detailed commune-level trajectory file from ARCEP
copper_trajectory_url <- "https://www.data.gouv.fr/api/1/datasets/r/1b8e5f78-a4e7-4626-9c4e-3e9ac2e7e8e5"
copper_traj_file <- file.path(data_dir, "copper_trajectory_communes.csv")
tryCatch({
  download.file(copper_trajectory_url, copper_traj_file, mode = "wb", quiet = TRUE)
  if (file.exists(copper_traj_file) && file.size(copper_traj_file) > 100) {
    cat("  Copper trajectory (commune-level) downloaded:", file.size(copper_traj_file), "bytes\n")
  }
}, error = function(e) {
  cat("  Copper trajectory download failed:", e$message, "\n")
  cat("  Will use lot-level schedule only.\n")
})

# ==============================================================================
# 6. Deployment zone classification
# ==============================================================================

cat("\n=== Fetching deployment zone data ===\n")

# ARCEP zone classifications: Zone Tres Dense, AMII, RIP
# These determine who deploys fiber and the regulatory timeline
# Available from ARCEP open data
zone_url <- "https://www.data.gouv.fr/api/1/datasets/r/5b46bf0c-e2dc-4c2e-8d3f-ae3d7c36c0c3"
zone_file <- file.path(data_dir, "deployment_zones.csv")
tryCatch({
  download.file(zone_url, zone_file, mode = "wb", quiet = TRUE)
  if (file.exists(zone_file) && file.size(zone_file) > 100) {
    cat("  Deployment zone data downloaded:", file.size(zone_file), "bytes\n")
  }
}, error = function(e) {
  cat("  Zone data download failed:", e$message, "\n")
  cat("  Will construct zone classification from ARCEP observatory.\n")
})

# ==============================================================================
# DATA VALIDATION
# ==============================================================================

cat("\n=== Data Validation ===\n")

# Core requirement 1: ARCEP FTTH deployment data exists
stopifnot("ARCEP FTTH deployment file must exist" = file.exists(arcep_file))
stopifnot("ARCEP FTTH file must be non-empty" = file.size(arcep_file) > 1000)

# Core requirement 2: Election data exists
stopifnot("Election general results must exist" = file.exists(elections_general_file))
stopifnot("Election candidate results must exist" = file.exists(elections_cand_file))
stopifnot("Election files must be non-empty" = file.size(elections_general_file) > 1000)
stopifnot("Election candidate file must be non-empty" = file.size(elections_cand_file) > 1000)

cat("\nData validation PASSED.\n")
cat("Core data files present:\n")
cat("  ARCEP FTTH deployment:", file.size(arcep_file), "bytes\n")
cat("  Election general results:", file.size(elections_general_file), "bytes\n")
cat("  Election candidate results:", file.size(elections_cand_file), "bytes\n")

# List all downloaded files
cat("\nAll data files:\n")
all_files <- list.files(data_dir, recursive = TRUE)
for (f in all_files) {
  cat("  ", f, ":", file.size(file.path(data_dir, f)), "bytes\n")
}

cat("\n01_fetch_data.R complete.\n")
