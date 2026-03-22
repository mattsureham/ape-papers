## 01_fetch_data.R — Fetch and verify all data sources
## apep_0736: Who Counts the Dead?

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ─────────────────────────────────────────────────────────────────────
# 1. CDC COMEC — County medicolegal death investigation classifications
# ─────────────────────────────────────────────────────────────────────
cat("Fetching CDC COMEC MDI classifications...\n")
comec_url <- "https://www.cdc.gov/nchs/comec/County-Death-Investigation-System-2018-1-9-2024.csv"
comec_file <- file.path(data_dir, "cdc_comec_mdi.csv")

if (!file.exists(comec_file)) {
  resp <- httr::GET(comec_url, httr::write_disk(comec_file, overwrite = TRUE))
  stopifnot("COMEC download failed" = httr::status_code(resp) == 200)
}

comec <- read_csv(comec_file, show_col_types = FALSE)
cat(sprintf("COMEC loaded: %d counties\n", nrow(comec)))

# Validate: expect ~3,143 counties
stopifnot("COMEC should have ~3000+ counties" = nrow(comec) >= 3000)

# ─────────────────────────────────────────────────────────────────────
# 2. NCHS Model-Based Drug Overdose Death Rates by County
# ─────────────────────────────────────────────────────────────────────
cat("Fetching NCHS model-based drug overdose county data...\n")
model_url <- "https://data.cdc.gov/resource/rpvx-m2md.csv?$limit=65000"
model_file <- file.path(data_dir, "nchs_model_drug_overdose.csv")

if (!file.exists(model_file)) {
  resp <- httr::GET(model_url, httr::write_disk(model_file, overwrite = TRUE))
  stopifnot("Model-based overdose download failed" = httr::status_code(resp) == 200)
}

model_od <- read_csv(model_file, show_col_types = FALSE)
cat(sprintf("Model-based OD loaded: %d county-year obs, years %s-%s\n",
            nrow(model_od), min(model_od$year), max(model_od$year)))

# Validate: expect ~60K observations
stopifnot("Model-based OD should have 50K+ rows" = nrow(model_od) >= 50000)

# ─────────────────────────────────────────────────────────────────────
# 3. County Adjacency File (Census Bureau)
# ─────────────────────────────────────────────────────────────────────
cat("Fetching Census county adjacency file...\n")
adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
adj_file <- file.path(data_dir, "county_adjacency.txt")

if (!file.exists(adj_file)) {
  resp <- httr::GET(adj_url, httr::write_disk(adj_file, overwrite = TRUE))
  stopifnot("County adjacency download failed" = httr::status_code(resp) == 200)
}

cat("County adjacency file downloaded.\n")

# ─────────────────────────────────────────────────────────────────────
# 4. ACS County Demographics (Census API)
# ─────────────────────────────────────────────────────────────────────
cat("Fetching ACS county demographics...\n")
acs_file <- file.path(data_dir, "acs_county_demographics.csv")

if (!file.exists(acs_file)) {
  census_key <- Sys.getenv("CENSUS_API_KEY")
  stopifnot("CENSUS_API_KEY not set" = nchar(census_key) > 0)

  acs_vars <- "B01003_001E,B17001_002E,B19013_001E,B02001_002E,B02001_003E"
  acs_url <- paste0(
    "https://api.census.gov/data/2021/acs/acs5?get=NAME,", acs_vars,
    "&for=county:*&key=", census_key
  )
  resp <- httr::GET(acs_url)
  stopifnot("Census ACS download failed" = httr::status_code(resp) == 200)

  acs_json <- httr::content(resp, as = "text", encoding = "UTF-8")
  acs_mat <- jsonlite::fromJSON(acs_json)
  acs_df <- as.data.frame(acs_mat[-1, ], stringsAsFactors = FALSE)
  names(acs_df) <- acs_mat[1, ]
  write_csv(acs_df, acs_file)
}

acs <- read_csv(acs_file, show_col_types = FALSE)
cat(sprintf("ACS demographics loaded: %d counties\n", nrow(acs)))

cat("\n=== All data fetched successfully ===\n")
