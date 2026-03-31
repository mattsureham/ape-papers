## 01_fetch_data.R — Fetch Registro Nacional de Sociedades from datos.jus.gob.ar
## apep_1203: Argentina SAS Firm Registration Ban

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── CKAN API: discover resources ──────────────────────────────────────────────

base_url <- "https://datos.jus.gob.ar"

# The dataset slug for Registro Nacional de Sociedades
# Try the CKAN package_show API first
cat("Querying CKAN API for firm registry datasets...\n")

# Search for sociedad/sociedades datasets
search_url <- paste0(base_url, "/api/3/action/package_search?q=sociedades&rows=20")
resp <- httr::GET(search_url, httr::timeout(30))
if (httr::status_code(resp) != 200) {
  stop("CKAN search failed with status ", httr::status_code(resp))
}
search_results <- httr::content(resp, as = "parsed")

# Find the relevant dataset
datasets <- search_results$result$results
cat("Found", length(datasets), "datasets matching 'sociedades'\n")

# Print dataset names to identify the right one
for (ds in datasets) {
  cat("  -", ds$name, ":", ds$title, "\n")
}

# Look for the Registro Nacional de Sociedades or similar
target_ds <- NULL
for (ds in datasets) {
  title_lower <- tolower(ds$title)
  name_lower <- tolower(ds$name)
  if (grepl("registro.*sociedades|sociedades.*registro|inscripci.*societ",
            paste(title_lower, name_lower))) {
    target_ds <- ds
    break
  }
}

# If not found by title, try broader search
if (is.null(target_ds)) {
  cat("Trying broader search terms...\n")
  search_url2 <- paste0(base_url, "/api/3/action/package_search?q=registro+nacional+sociedades&rows=20")
  resp2 <- httr::GET(search_url2, httr::timeout(30))
  if (httr::status_code(resp2) == 200) {
    search_results2 <- httr::content(resp2, as = "parsed")
    for (ds in search_results2$result$results) {
      cat("  -", ds$name, ":", ds$title, "\n")
      if (is.null(target_ds)) target_ds <- ds
    }
  }
}

# If still nothing, try listing all datasets
if (is.null(target_ds)) {
  cat("Trying package list...\n")
  list_url <- paste0(base_url, "/api/3/action/package_list")
  resp3 <- httr::GET(list_url, httr::timeout(30))
  if (httr::status_code(resp3) == 200) {
    all_names <- httr::content(resp3, as = "parsed")$result
    soc_names <- grep("socied|registro|inscripci", unlist(all_names),
                      value = TRUE, ignore.case = TRUE)
    cat("Matching dataset names:\n")
    for (nm in soc_names) cat("  -", nm, "\n")

    if (length(soc_names) > 0) {
      pkg_url <- paste0(base_url, "/api/3/action/package_show?id=", soc_names[1])
      resp4 <- httr::GET(pkg_url, httr::timeout(30))
      if (httr::status_code(resp4) == 200) {
        target_ds <- httr::content(resp4, as = "parsed")$result
      }
    }
  }
}

if (is.null(target_ds)) {
  stop("Could not find firm registry dataset on datos.jus.gob.ar. ",
       "API may have changed structure.")
}

cat("\nTarget dataset:", target_ds$title, "\n")
cat("Resources:", length(target_ds$resources), "\n")

# ── Download resources (CSV/ZIP files by year) ───────────────────────────────

all_frames <- list()

for (res in target_ds$resources) {
  res_name <- res$name %||% res$description %||% "unnamed"
  res_url <- res$url
  res_format <- tolower(res$format %||% "")

  cat("Resource:", res_name, "| Format:", res_format, "| URL:", res_url, "\n")

  if (!(res_format %in% c("csv", "zip", "xlsx"))) {
    cat("  Skipping non-data format\n")
    next
  }

  # Determine local filename
  fname <- basename(res_url)
  if (nchar(fname) < 3) fname <- paste0(res_name, ".", res_format)
  local_path <- file.path(data_dir, fname)

  # Download
  if (!file.exists(local_path)) {
    cat("  Downloading", fname, "...\n")
    dl <- tryCatch(
      httr::GET(res_url, httr::write_disk(local_path, overwrite = TRUE),
                httr::timeout(120)),
      error = function(e) {
        cat("  Download error:", conditionMessage(e), "\n")
        NULL
      }
    )
    if (is.null(dl) || httr::status_code(dl) != 200) {
      cat("  Failed to download (status:",
          if (!is.null(dl)) httr::status_code(dl) else "error", ")\n")
      if (file.exists(local_path)) file.remove(local_path)
      next
    }
    cat("  Downloaded:", round(file.size(local_path) / 1e6, 1), "MB\n")
  } else {
    cat("  Already exists:", round(file.size(local_path) / 1e6, 1), "MB\n")
  }

  # Parse CSV or ZIP
  if (res_format == "zip") {
    tmp_dir <- tempdir()
    unzipped <- tryCatch(unzip(local_path, exdir = tmp_dir), error = function(e) NULL)
    if (is.null(unzipped)) {
      cat("  Failed to unzip\n")
      next
    }
    csv_files <- grep("\\.csv$", unzipped, value = TRUE, ignore.case = TRUE)
    for (cf in csv_files) {
      cat("  Reading CSV from ZIP:", basename(cf), "\n")
      df <- tryCatch(
        data.table::fread(cf, encoding = "Latin-1"),
        error = function(e) {
          tryCatch(data.table::fread(cf, encoding = "UTF-8"),
                   error = function(e2) NULL)
        }
      )
      if (!is.null(df) && nrow(df) > 0) {
        all_frames[[length(all_frames) + 1]] <- df
        cat("    Rows:", nrow(df), "| Cols:", ncol(df), "\n")
      }
    }
  } else if (res_format == "csv") {
    df <- tryCatch(
      data.table::fread(local_path, encoding = "Latin-1"),
      error = function(e) {
        tryCatch(data.table::fread(local_path, encoding = "UTF-8"),
                 error = function(e2) NULL)
      }
    )
    if (!is.null(df) && nrow(df) > 0) {
      all_frames[[length(all_frames) + 1]] <- df
      cat("  Rows:", nrow(df), "| Cols:", ncol(df), "\n")
    }
  }
}

if (length(all_frames) == 0) {
  stop("No data frames loaded. Check datos.jus.gob.ar API and resource URLs.")
}

cat("\nLoaded", length(all_frames), "data frames total.\n")

# ── Harmonize column names and combine ────────────────────────────────────────

# Print column names of each frame for diagnosis
for (i in seq_along(all_frames)) {
  cat("Frame", i, "cols:", paste(names(all_frames[[i]]), collapse = ", "), "\n")
}

# Standardize to common schema
harmonize_frame <- function(df) {
  nms <- tolower(names(df))
  names(df) <- nms

  # Map common variants
  col_map <- c(
    "cuit" = "cuit",
    "razon_social" = "firm_name",
    "fecha_hora_contrato_social" = "date",
    "fecha_contrato_social" = "date",
    "fecha" = "date",
    "tipo_societario" = "firm_type",
    "tipo" = "firm_type",
    "dom_fiscal_provincia" = "province",
    "provincia" = "province",
    "dom_fiscal_localidad" = "municipality",
    "localidad" = "municipality",
    "actividad_principal" = "activity"
  )

  out <- data.frame(row.names = seq_len(nrow(df)))
  for (target_col in unique(col_map)) {
    source_cols <- names(col_map)[col_map == target_col]
    found <- intersect(source_cols, nms)
    if (length(found) > 0) {
      out[[target_col]] <- as.character(df[[found[1]]])
    } else {
      out[[target_col]] <- NA_character_
    }
  }
  as.data.table(out)
}

combined <- rbindlist(lapply(all_frames, harmonize_frame), fill = TRUE)
cat("Combined dataset:", nrow(combined), "rows\n")

# ── Validate data ─────────────────────────────────────────────────────────────

# Check firm types present
cat("\nFirm types found:\n")
print(table(combined$firm_type, useNA = "ifany"))

# Check date coverage
combined[, date_parsed := as.Date(date, tryFormats = c(
  "%Y-%m-%d", "%d/%m/%Y", "%Y-%m-%d %H:%M:%S", "%d-%m-%Y"
))]

# For dates that failed parsing, try more formats
na_dates <- is.na(combined$date_parsed)
if (any(na_dates)) {
  combined[na_dates, date_parsed := as.Date(
    sub(" .*", "", date),
    tryFormats = c("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y", "%Y%m%d")
  )]
}

cat("\nDate range:", as.character(min(combined$date_parsed, na.rm = TRUE)),
    "to", as.character(max(combined$date_parsed, na.rm = TRUE)), "\n")
cat("Missing dates:", sum(is.na(combined$date_parsed)), "of", nrow(combined), "\n")

# Add year-month
combined[, ym := floor_date(date_parsed, "month")]
combined[, year := year(date_parsed)]

cat("\nRegistrations by year:\n")
print(combined[!is.na(year), .N, by = year][order(year)])

# Province check
cat("\nTop provinces:\n")
print(head(combined[!is.na(province), .N, by = province][order(-N)], 15))

# ── Save raw combined data ────────────────────────────────────────────────────

fwrite(combined, file.path(data_dir, "firms_raw.csv"))
cat("\nSaved firms_raw.csv:", nrow(combined), "rows\n")

# ── Validate presence of SAS ─────────────────────────────────────────────────

sas_count <- sum(grepl("SAS|S\\.A\\.S|SIMPLIFICADA", combined$firm_type, ignore.case = TRUE))
cat("\nSAS-type registrations found:", sas_count, "\n")
if (sas_count == 0) {
  # Check if SAS might be coded differently
  cat("All firm type values:\n")
  print(sort(unique(combined$firm_type)))
  stop("No SAS registrations found. Check firm_type coding.")
}

cat("\n=== Data fetch complete ===\n")
