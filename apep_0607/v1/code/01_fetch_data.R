# 01_fetch_data.R — Fetch agricultural and land cover data
# APEP Working Paper apep_0607
#
# Data sources:
#   1. IBGE SIDRA API — PAM (crop area/production) and PPM (cattle herd)
#   2. MapBiomas Collection 9 — Municipality-level land cover statistics

source("00_packages.R")

# ============================================================
# Helper: Fetch IBGE SIDRA API data (with batching)
# ============================================================
fetch_sidra <- function(table, variable, territorial_level = "6",
                        classification = NULL, categories = NULL,
                        periods = NULL) {
  base_url <- "https://apisidra.ibge.gov.br/values"
  url <- paste0(base_url, "/t/", table, "/n", territorial_level, "/all")
  url <- paste0(url, "/v/", variable)
  if (!is.null(periods)) {
    url <- paste0(url, "/p/", paste(periods, collapse = ","))
  } else {
    url <- paste0(url, "/p/all")
  }
  if (!is.null(classification) && !is.null(categories)) {
    url <- paste0(url, "/c", classification, "/", paste(categories, collapse = ","))
  }

  cat("Fetching:", url, "\n")
  resp <- httr::GET(url, httr::timeout(300))
  if (httr::status_code(resp) != 200) {
    stop("SIDRA API returned status ", httr::status_code(resp),
         "\nURL: ", url,
         "\nBody: ", httr::content(resp, "text"))
  }
  data <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  if (nrow(data) > 1) {
    col_names <- as.character(data[1, ])
    data <- data[-1, ]
    names(data) <- col_names
  }
  return(as_tibble(data))
}

# Batched fetch: split years into chunks to stay under 50k row limit
fetch_sidra_batched <- function(table, variable, years, batch_size = 3, ...) {
  year_batches <- split(years, ceiling(seq_along(years) / batch_size))
  results <- list()
  for (i in seq_along(year_batches)) {
    cat("  Batch", i, "of", length(year_batches), ": years",
        paste(year_batches[[i]], collapse = ","), "\n")
    batch <- fetch_sidra(table = table, variable = variable,
                         periods = as.character(year_batches[[i]]), ...)
    results[[i]] <- batch
    Sys.sleep(1)  # Rate limiting
  }
  bind_rows(results)
}

# ============================================================
# 1. Fetch Soybean Planted Area (IBGE PAM, Table 5457)
# ============================================================
cat("\n=== Fetching Soybean Planted Area ===\n")
soy_area <- fetch_sidra_batched(
  table = "5457", variable = "216",
  years = 2006:2020, batch_size = 3,
  classification = "782", categories = "40124"
)
cat("Soybean area rows:", nrow(soy_area), "\n")
if (nrow(soy_area) == 0) stop("FATAL: No soybean area data returned from SIDRA API")
saveRDS(soy_area, "../data/raw_soy_area.rds")

# ============================================================
# 2. Fetch Total Temporary Crop Area (IBGE PAM, Table 1612)
# ============================================================
cat("\n=== Fetching Total Temporary Crop Area ===\n")
temp_crop <- fetch_sidra_batched(
  table = "1612", variable = "109",
  years = 2006:2020, batch_size = 3
)
cat("Temp crop area rows:", nrow(temp_crop), "\n")
if (nrow(temp_crop) == 0) stop("FATAL: No temporary crop data returned")
saveRDS(temp_crop, "../data/raw_temp_crop_area.rds")

# ============================================================
# 3. Fetch Soybean Production Value (IBGE PAM, Table 5457)
# ============================================================
cat("\n=== Fetching Soybean Production Value ===\n")
soy_value <- fetch_sidra_batched(
  table = "5457", variable = "214",
  years = 2006:2020, batch_size = 3,
  classification = "782", categories = "40124"
)
cat("Soybean value rows:", nrow(soy_value), "\n")
if (nrow(soy_value) == 0) stop("FATAL: No soybean value data returned")
saveRDS(soy_value, "../data/raw_soy_value.rds")

# ============================================================
# 4. Fetch Cattle Herd (IBGE PPM, Table 3939)
# ============================================================
cat("\n=== Fetching Cattle Herd Data ===\n")
cattle <- fetch_sidra_batched(
  table = "3939", variable = "105",
  years = 2006:2020, batch_size = 3,
  classification = "79", categories = "2670"
)
cat("Cattle rows:", nrow(cattle), "\n")
if (nrow(cattle) == 0) stop("FATAL: No cattle data returned")
saveRDS(cattle, "../data/raw_cattle.rds")

# ============================================================
# 5. Fetch Soybean Production Quantity (tons)
# ============================================================
cat("\n=== Fetching Soybean Production Quantity ===\n")
soy_prod <- fetch_sidra_batched(
  table = "5457", variable = "215",
  years = 2006:2020, batch_size = 3,
  classification = "782", categories = "40124"
)
cat("Soybean production rows:", nrow(soy_prod), "\n")
if (nrow(soy_prod) == 0) stop("FATAL: No soybean production data returned")
saveRDS(soy_prod, "../data/raw_soy_production.rds")

# ============================================================
# 6. Download MapBiomas Municipality-Level Land Cover Statistics
# ============================================================
cat("\n=== Downloading MapBiomas Municipality Statistics ===\n")

mapbiomas_url <- "https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_9/statistics/mapbiomas_brazil_col_coverage_biome_state_municipality.xlsx"
mapbiomas_file <- "../data/mapbiomas_municipalities.xlsx"

if (!file.exists(mapbiomas_file)) {
  cat("Downloading MapBiomas data (~68 MB)...\n")
  download_result <- tryCatch({
    download.file(mapbiomas_url, mapbiomas_file, mode = "wb", timeout = 600)
    TRUE
  }, error = function(e) {
    cat("Primary URL failed:", e$message, "\n")
    cat("Trying alternative URL...\n")
    FALSE
  })

  if (!download_result) {
    # Try alternative MapBiomas URL patterns
    alt_urls <- c(
      "https://brasil.mapbiomas.org/wp-content/uploads/sites/4/2024/08/TABELA-MUNICIPIOS-MAPBIOMAS-COL9.xlsx",
      "https://brasil.mapbiomas.org/wp-content/uploads/sites/4/2024/12/TABELA-MUNICIPIOS-MAPBIOMAS-COL9.xlsx"
    )
    for (alt_url in alt_urls) {
      cat("Trying:", alt_url, "\n")
      dl_ok <- tryCatch({
        download.file(alt_url, mapbiomas_file, mode = "wb", timeout = 600)
        TRUE
      }, error = function(e) FALSE)
      if (dl_ok) break
    }
    if (!file.exists(mapbiomas_file)) {
      stop("FATAL: Cannot download MapBiomas data")
    }
  }
  cat("MapBiomas download complete. Size:", file.size(mapbiomas_file), "bytes\n")
} else {
  cat("MapBiomas file already exists. Size:", file.size(mapbiomas_file), "bytes\n")
}

cat("\n=== All data fetched successfully ===\n")
cat("Files saved in data/:\n")
print(list.files("../data/", pattern = "\\.(rds|xlsx)$"))
