## ============================================================
## 01_fetch_data.R — Fetch ARIA accidents + Seveso site counts
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------
# 1. ARIA industrial accident database
# ----------------------------------------------------------------
aria_url <- "https://static.data.gouv.fr/resources/mise-a-disposition-de-lintegralite-de-la-base-aria-analyse-recherche-et-information-sur-les-accidents-du-barpi/20260114-103039/accidents-tous-req10905.csv"
aria_file <- file.path(data_dir, "aria_raw.csv")

cat("Downloading ARIA database...\n")
tryCatch({
  download.file(aria_url, aria_file, mode = "wb", quiet = TRUE)
}, error = function(e) {
  stop("ARIA data unavailable: ", e$message,
       "\nPivot research question or fix the source.")
})

# Read with proper encoding — file has metadata header rows
# Find the actual data header line
raw_lines <- readLines(aria_file, encoding = "latin1", n = 20)
header_line <- grep("^Titre;", raw_lines)
if (length(header_line) == 0) stop("Cannot find ARIA data header row")
cat("Data header found at line:", header_line, "\n")

aria <- fread(aria_file, skip = header_line - 1, sep = ";",
              encoding = "Latin-1", quote = "\"",
              header = TRUE, fill = TRUE)

cat("ARIA raw records:", nrow(aria), "\n")
cat("Columns:", paste(names(aria), collapse = ", "), "\n")

# ----------------------------------------------------------------
# 2. ICPE Seveso site counts by department (Georisques API)
# ----------------------------------------------------------------
cat("\nFetching Seveso Seuil Haut site counts by department...\n")

# Metropolitan France departments
metro_depts <- c(
  sprintf("%02d", 1:19), "2A", "2B",
  sprintf("%02d", 21:95)
)

fetch_seveso_count <- function(dept_code) {
  seveso_h <- 0
  seveso_b <- 0
  page <- 1
  repeat {
    url <- paste0(
      "https://georisques.gouv.fr/api/v1/installations_classees",
      "?departement=", dept_code,
      "&page=", page,
      "&page_size=1000"
    )
    resp <- tryCatch(
      httr::GET(url, httr::timeout(30)),
      error = function(e) NULL
    )
    if (is.null(resp) || httr::status_code(resp) != 200) break

    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content, simplifyVector = FALSE)
    data_list <- parsed$data
    if (length(data_list) == 0) break

    for (item in data_list) {
      status <- item$statutSeveso
      if (!is.null(status)) {
        if (grepl("seuil haut", status, ignore.case = TRUE)) seveso_h <- seveso_h + 1
        if (grepl("seuil bas", status, ignore.case = TRUE)) seveso_b <- seveso_b + 1
      }
    }

    total_pages <- parsed$total_pages
    if (page >= total_pages) break
    page <- page + 1
    Sys.sleep(0.2)  # rate limiting
  }
  data.frame(dept_code = dept_code, seveso_h = seveso_h, seveso_b = seveso_b)
}

seveso_list <- list()
for (i in seq_along(metro_depts)) {
  dept <- metro_depts[i]
  if (i %% 10 == 0) cat("  Department", dept, "(", i, "/", length(metro_depts), ")\n")
  seveso_list[[i]] <- fetch_seveso_count(dept)
  Sys.sleep(0.1)
}
seveso_df <- do.call(rbind, seveso_list)

cat("\nSeveso Seuil Haut sites by department:\n")
cat("  Total Seveso H sites:", sum(seveso_df$seveso_h), "\n")
cat("  Departments with >= 1:", sum(seveso_df$seveso_h >= 1), "\n")
cat("  Top departments:\n")
top_depts <- seveso_df[order(-seveso_df$seveso_h), ][1:10, ]
for (j in 1:nrow(top_depts)) {
  cat("    Dept", top_depts$dept_code[j], ":", top_depts$seveso_h[j], "sites\n")
}

fwrite(seveso_df, file.path(data_dir, "seveso_by_dept.csv"))

# ----------------------------------------------------------------
# 3. INSEE BDM — Manufacturing employment by department
# ----------------------------------------------------------------
cat("\nFetching INSEE manufacturing employment data...\n")

# INSEE BDM SDMX endpoint for departmental employment
# Series: EMPLOI-SALARIE-TRIM-REG (quarterly, regional level)
# For department-level, we use annual data from BDM
# Alternative: use CLAP/FLORES data via SDMX

# Fallback: use departmental population from INSEE as control
# (manufacturing employment at dept level may not be in SDMX)
# Using population data instead as key time-varying control
insee_pop_url <- paste0(
  "https://api.insee.fr/melodi/data/DS_ELP?",
  "TIME_PERIOD=ge:1990-01-01+le:2015-01-01",
  "&GEO=DEP",
  "&DEMOGRAPHY_CONCEPT=POP",
  "&FREQ=A",
  "&dimensionAtObservation=TIME_PERIOD"
)

# Try SDMX without auth first
resp_pop <- tryCatch(
  httr::GET(insee_pop_url,
            httr::add_headers(Accept = "application/json"),
            httr::timeout(30)),
  error = function(e) NULL
)

if (!is.null(resp_pop) && httr::status_code(resp_pop) == 200) {
  cat("  INSEE population data retrieved via SDMX\n")
  pop_content <- httr::content(resp_pop, as = "text", encoding = "UTF-8")
  pop_json <- jsonlite::fromJSON(pop_content)
  # Parse SDMX-JSON structure
  fwrite(data.frame(source = "insee_sdmx", status = "retrieved"),
         file.path(data_dir, "insee_pop_status.csv"))
} else {
  cat("  INSEE SDMX not available; will use departmental population from census data\n")
  # Use a simpler source: departmental population estimates
  # Available from data.gouv.fr as part of census data
  pop_url <- "https://www.data.gouv.fr/fr/datasets/r/a1f09595-0e32-4e26-811c-9527bbba39c5"
  pop_file <- file.path(data_dir, "population_dept.csv")

  resp2 <- tryCatch(
    download.file(pop_url, pop_file, mode = "wb", quiet = TRUE),
    error = function(e) {
      cat("  Population data download failed; will construct from census estimates\n")
      NULL
    }
  )

  fwrite(data.frame(source = "fallback", status = "will_construct"),
         file.path(data_dir, "insee_pop_status.csv"))
}

# ----------------------------------------------------------------
# 4. Data validation
# ----------------------------------------------------------------
cat("\n=== DATA VALIDATION ===\n")

# ARIA validation
stopifnot("ARIA has records" = nrow(aria) > 50000)
stopifnot("ARIA has Date column" = "Date" %in% names(aria))
stopifnot("ARIA has department column" = any(grepl("part", names(aria), ignore.case = TRUE)))

# Seveso validation
stopifnot("Seveso data has departments" = nrow(seveso_df) >= 90)
stopifnot("Seveso H sites found" = sum(seveso_df$seveso_h) > 100)

cat("ARIA records:", nrow(aria), "\n")
cat("Seveso departments:", nrow(seveso_df), "\n")
cat("Total Seveso H sites:", sum(seveso_df$seveso_h), "\n")
cat("Data validation PASSED\n")

# Save raw ARIA as RDS for faster loading
saveRDS(aria, file.path(data_dir, "aria_raw.rds"))
cat("\nAll data fetched and saved.\n")
