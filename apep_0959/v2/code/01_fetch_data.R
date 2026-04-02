## 01_fetch_data.R — Fetch CMS nursing home data via direct CSV download
## V2: Uses CMS Provider Data Catalog metastore to find current download URLs

source("00_packages.R")

cat("=== Fetching CMS Nursing Home Data ===\n")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ================================================================
# Helper: resolve current download URL from CMS metastore
# ================================================================
get_cms_url <- function(dataset_id) {
  meta_url <- sprintf("https://data.cms.gov/provider-data/api/1/metastore/schemas/dataset/items/%s", dataset_id)
  meta <- tryCatch({
    tmp <- tempfile()
    download.file(meta_url, tmp, quiet = TRUE, method = "libcurl")
    jsonlite::fromJSON(tmp)
  }, error = function(e) NULL)
  if (!is.null(meta) && length(meta$distribution) > 0) {
    return(meta$distribution$downloadURL[1])
  }
  return(NULL)
}

fetch_csv <- function(dataset_id, output_file, desc) {
  filepath <- file.path(data_dir, output_file)

  if (file.exists(filepath) && file.size(filepath) > 1000) {
    cat(sprintf("  [CACHED] %s\n", desc))
    return(fread(filepath))
  }

  url <- get_cms_url(dataset_id)
  if (is.null(url)) stop(sprintf("FATAL: Could not resolve download URL for %s", dataset_id))

  cat(sprintf("  Downloading %s...\n  URL: %s\n", desc, url))
  download.file(url, filepath, mode = "wb", quiet = FALSE, method = "libcurl")

  dt <- fread(filepath)
  cat(sprintf("  Loaded: %d rows, %d cols\n", nrow(dt), ncol(dt)))
  return(dt)
}

# ================================================================
# Fetch all datasets
# ================================================================

# Provider Information (current snapshot with PBJ staffing data)
provider <- fetch_csv("4pq5-n9py", "NH_ProviderInfo.csv", "Provider Information")

# Health Deficiency Citations (historical panel — core data)
deficiencies <- fetch_csv("r5ix-sfxw", "NH_HealthCitations.csv", "Health Deficiency Citations")

# Quality Measures
quality <- fetch_csv("djen-97ju", "NH_QualityMsr.csv", "Quality Measures")

# ================================================================
# VALIDATION
# ================================================================
cat("\n=== Data Validation ===\n")

stopifnot("Provider data must have >10000 facilities" = nrow(provider) > 10000)
stopifnot("Deficiency data must have >100000 records" = nrow(deficiencies) > 100000)

cat(sprintf("Provider Info: %d facilities, %d columns\n", nrow(provider), ncol(provider)))
cat(sprintf("Health Deficiencies: %d records\n", nrow(deficiencies)))
cat(sprintf("Quality Measures: %d records\n", nrow(quality)))

# Standardize column names
setnames(provider, make.names(colnames(provider)))
setnames(deficiencies, make.names(colnames(deficiencies)))
setnames(quality, make.names(colnames(quality)))

# ================================================================
# TREATMENT MAPPING
# ================================================================
cat("\n=== Treatment Mapping ===\n")

mandate_info <- data.table(
  state = c("CT", "RI", "CA", "AZ", "WA", "NY",
            "FL", "IL", "AR", "OR", "PA", "MA"),
  mandate_year = c(2017L, 2017L, 2018L, 2019L, 2019L, 2022L,
                   2002L, 2010L, 2014L, 2015L, 2016L, 2016L),
  hprd_floor = c(NA, NA, 3.5, NA, NA, 3.5,
                 3.6, NA, NA, NA, NA, NA),
  mandate_type = c("updated", "updated", "updated", "new", "updated", "new",
                   "always", "always", "always", "always", "always", "always"),
  notes = c("Updated existing ratio requirements",
            "Updated existing ratio requirements",
            "AB 2079: 3.5 total HPRD",
            "New quantitative staffing floor",
            "Updated existing staffing standards",
            "Safe Staffing Act: 3.5 HPRD, 2.2 CNA floor",
            "Statute 400.23: 3.6 total HPRD",
            "Updated 2010", "Updated 2014", "Updated 2015",
            "Updated 2016", "Updated 2016")
)

did_cohorts <- mandate_info[mandate_year >= 2017]
cat(sprintf("DiD treatment cohorts: %d states\n", nrow(did_cohorts)))
print(did_cohorts[, .(state, mandate_year, notes)])

# Save
fwrite(mandate_info, file.path(data_dir, "mandate_info.csv"))
saveRDS(provider, file.path(data_dir, "provider.rds"))
saveRDS(deficiencies, file.path(data_dir, "deficiencies.rds"))
saveRDS(quality, file.path(data_dir, "quality.rds"))

cat("\n=== Data fetch complete ===\n")
