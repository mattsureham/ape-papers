## 01_fetch_data.R — Fetch DVF transactions, QPV (2015) boundaries, and ZUS list
## All data from data.gouv.fr (open data)

source("00_packages.R")
if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. Download QPV 2015 shapefile ───────────────────────────────────────────
cat("=== Downloading QPV 2015 boundaries ===\n")
qpv_dir <- file.path(data_dir, "qpv")
dir.create(qpv_dir, showWarnings = FALSE)

qpv_rds <- file.path(data_dir, "qpv_2015.rds")
if (!file.exists(qpv_rds)) {
  # Direct URL for 2015 QPV shapefile from data.gouv.fr
  qpv_url <- "https://static.data.gouv.fr/resources/quartiers-prioritaires-de-la-politique-de-la-ville-qpv/20180110-144945/qp-politiquedelaville-shp.zip"
  qpv_tmp <- tempfile(fileext = ".zip")
  cat("  URL:", qpv_url, "\n")
  download.file(qpv_url, qpv_tmp, mode = "wb", quiet = FALSE)
  unzip(qpv_tmp, exdir = qpv_dir)

  # Use METROPOLITAN France shapefile specifically (already in Lambert-93)
  metro_shp <- file.path(qpv_dir, "QP_METROPOLE_LB93.shp")
  if (!file.exists(metro_shp)) {
    # Fallback: search for it
    shp_files <- list.files(qpv_dir, pattern = "METROPOLE.*\\.shp$",
                            full.names = TRUE, recursive = TRUE)
    if (length(shp_files) == 0) stop("No metropolitan QPV shapefile found")
    metro_shp <- shp_files[1]
  }

  qpv <- st_read(metro_shp, quiet = TRUE)
  # Ensure Lambert-93 (EPSG:2154)
  crs_epsg <- st_crs(qpv)$epsg
  if (is.na(crs_epsg) || crs_epsg != 2154) qpv <- st_transform(qpv, 2154)
  saveRDS(qpv, qpv_rds)
  cat("QPV 2015 zones loaded and saved:", nrow(qpv), "polygons\n")
} else {
  qpv <- readRDS(qpv_rds)
  cat("QPV 2015 loaded from cache:", nrow(qpv), "polygons\n")
}

cat("QPV columns:", paste(names(qpv), collapse = ", "), "\n")
stopifnot("Expected 1000+ QPV zones" = nrow(qpv) >= 1000)

# ── 2. Download ZUS list (Excel) for zone classification ─────────────────────
cat("\n=== Downloading ZUS list ===\n")
zus_list_file <- file.path(data_dir, "zus_list.xlsx")
if (!file.exists(zus_list_file)) {
  zus_url <- "https://sig.ville.gouv.fr/uploads/doc/ZUS_FR_SGCIV_20100701.xls"
  zus_tmp <- tempfile(fileext = ".xls")
  download.file(zus_url, zus_tmp, mode = "wb", quiet = FALSE)
  file.copy(zus_tmp, zus_list_file)
}

# ── 3. Classify QPV zones as gained vs retained ─────────────────────────────
cat("\n=== Classifying QPV zones ===\n")

# Read ZUS list (skip 8 header rows)
zus_list <- readxl::read_xls(zus_list_file, skip = 8,
  col_names = c("region", "departement", "commune", "code_zus",
                "quartier", "type", "type2"))
zus_list <- zus_list[!is.na(zus_list$code_zus) &
                     nchar(zus_list$code_zus) >= 5 &
                     zus_list$code_zus != "CodeQuart", ]
cat("ZUS zones loaded:", nrow(zus_list), "\n")

# Extract unique ZUS commune names (split multi-commune entries)
zus_communes_raw <- unlist(strsplit(as.character(zus_list$commune), ", "))
zus_communes <- unique(tolower(trimws(zus_communes_raw)))
cat("Unique ZUS communes:", length(zus_communes), "\n")

# For each QPV zone, check if ANY of its communes had a former ZUS
qpv$had_zus <- sapply(seq_len(nrow(qpv)), function(i) {
  communes_i <- unlist(strsplit(tolower(trimws(as.character(qpv$COMMUNE_QP[i]))), ", "))
  any(communes_i %in% zus_communes)
})

qpv$zone_type <- ifelse(qpv$had_zus, "retained", "gained")
n_gained <- sum(qpv$zone_type == "gained")
n_retained <- sum(qpv$zone_type == "retained")
cat("\nClassification result:\n")
cat("  Gained QPV (new, commune had no ZUS):", n_gained, "\n")
cat("  Retained (commune had former ZUS):", n_retained, "\n")
stopifnot("Expected both gained and retained" = n_gained >= 100 && n_retained >= 100)

# Assign boundary IDs
qpv$boundary_id <- paste0(ifelse(qpv$zone_type == "gained", "G_", "R_"),
                          seq_len(nrow(qpv)))

saveRDS(qpv, file.path(data_dir, "qpv_classified.rds"))
cat("Classified QPV saved\n")

# ── 4. Identify departments with QPV zones ───────────────────────────────────
cat("\n=== Identifying relevant departments ===\n")

# Extract department codes from QPV CODE_QP (format: QP044012 → dept 44)
dept_raw <- substr(gsub("^QP", "", qpv$CODE_QP), 1, 3)
# Handle 3-digit codes with leading zero (e.g., "044" → "44")
# Keep Corsica codes "02A", "02B" as-is
dept_codes <- character(length(dept_raw))
for (i in seq_along(dept_raw)) {
  d <- dept_raw[i]
  if (grepl("^0[0-9]{2}$", d)) {
    dept_codes[i] <- sub("^0", "", d)
  } else {
    dept_codes[i] <- d
  }
}
# Remove overseas (97x, 98x) and NAs
dept_codes <- dept_codes[!grepl("^9[789]", dept_codes)]
dept_codes <- dept_codes[nchar(dept_codes) >= 2]
depts_needed <- sort(unique(dept_codes))
cat("Departments with QPV zones:", length(depts_needed), "\n")
cat("Sample:", paste(head(depts_needed, 15), collapse = ", "), "...\n")
stopifnot("Expected departments" = length(depts_needed) >= 30)

# ── 5. Download DVF data ────────────────────────────────────────────────────
cat("\n=== Downloading DVF transactions ===\n")
dvf_dir <- file.path(data_dir, "dvf")
dir.create(dvf_dir, showWarnings = FALSE)

years <- 2014:2024
base_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv"

for (yr in years) {
  yr_file <- file.path(dvf_dir, paste0("dvf_", yr, ".csv"))
  if (file.exists(yr_file)) {
    cat("  Year", yr, "already downloaded\n")
    next
  }

  cat("  Downloading year", yr, "...")
  yr_dfs <- list()
  n_downloaded <- 0

  for (dept in depts_needed) {
    dept_url <- paste0(base_url, "/", yr, "/departements/", dept, ".csv.gz")
    dept_tmp <- tempfile(fileext = ".csv.gz")

    dl_ok <- tryCatch({
      download.file(dept_url, dept_tmp, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      dept_url2 <- paste0(base_url, "/", yr, "/departements/", dept, ".csv")
      tryCatch({
        download.file(dept_url2, dept_tmp, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e2) FALSE)
    })

    if (dl_ok && file.size(dept_tmp) > 100) {
      df_dept <- tryCatch({
        fread(dept_tmp, showProgress = FALSE)
      }, error = function(e) NULL)

      if (!is.null(df_dept) && nrow(df_dept) > 0) {
        wanted <- c("id_mutation", "date_mutation", "nature_mutation",
                     "valeur_fonciere", "code_postal", "code_commune",
                     "code_departement", "type_local", "surface_reelle_bati",
                     "nombre_pieces_principales", "latitude", "longitude")
        available <- intersect(names(df_dept), wanted)
        df_dept <- df_dept[, ..available]
        yr_dfs[[length(yr_dfs) + 1]] <- df_dept
        n_downloaded <- n_downloaded + 1
      }
    }
    if (file.exists(dept_tmp)) file.remove(dept_tmp)
  }

  if (length(yr_dfs) > 0) {
    yr_combined <- rbindlist(yr_dfs, fill = TRUE)
    fwrite(yr_combined, yr_file)
    cat(" done.", format(nrow(yr_combined), big.mark = ","),
        "rows from", n_downloaded, "depts\n")
  } else {
    cat(" WARNING: no data for year", yr, "\n")
  }
}

# ── 6. Validate ─────────────────────────────────────────────────────────────
cat("\n=== Validation ===\n")
dvf_files <- list.files(dvf_dir, pattern = "dvf_\\d{4}\\.csv$", full.names = TRUE)
total_rows <- 0
for (f in sort(dvf_files)) {
  n <- as.integer(system(paste("wc -l <", shQuote(f)), intern = TRUE))
  cat("  ", basename(f), ":", format(n, big.mark = ","), "rows\n")
  total_rows <- total_rows + n
}
cat("\nTotal DVF rows:", format(total_rows, big.mark = ","), "\n")
stopifnot("Expected DVF data for multiple years" = length(dvf_files) >= 4)
stopifnot("Expected substantial DVF data" = total_rows > 100000)

cat("\n=== Data fetch complete ===\n")
cat("QPV 2015 zones:", nrow(qpv),
    "(gained:", n_gained, "retained:", n_retained, ")\n")
cat("DVF files:", length(dvf_files), "years\n")
cat("Total DVF rows:", format(total_rows, big.mark = ","), "\n")
