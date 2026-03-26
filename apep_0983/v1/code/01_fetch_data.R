# 01_fetch_data.R — Download Steuerfuss, population, and enterprise data
source("code/00_packages.R")

# Helper: query BFS PXWeb API (json-stat2 format)
query_pxweb <- function(table_path, query_list) {
  url <- paste0("https://www.pxweb.bfs.admin.ch/api/v1/de/", table_path)
  query_list$response <- list(format = "json-stat2")
  json_body <- toJSON(query_list, auto_unbox = TRUE)
  resp <- POST(url, body = json_body, content_type_json(), timeout(120))
  stopifnot("BFS PXWeb query failed" = status_code(resp) == 200)
  fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
}

# Helper: convert json-stat2 to data.table
jstat2_to_dt <- function(jstat) {
  dims <- unlist(jstat$id)
  sizes <- unlist(jstat$size)
  values <- unlist(jstat$value)

  # Build grid of dimension labels
  dim_labels <- list()
  for (d in dims) {
    cats <- jstat$dimension[[d]]$category
    idx_order <- names(cats$index)
    if (is.null(idx_order)) idx_order <- names(cats$label)
    dim_labels[[d]] <- unlist(cats$label[idx_order])
  }

  grid <- do.call(CJ, rev(dim_labels))
  setnames(grid, rev(dims))
  setcolorder(grid, dims)
  grid[, value := values]
  grid
}

# ==============================================================================
# 1. Zurich Steuerfuss (2012-2026)
# ==============================================================================
cat("=== Downloading Zurich Steuerfuss ===\n")
zh_url <- "https://www.web.statistik.zh.ch/ogd/data/steuerfuesse/kanton_zuerich_stf_timeseries.csv"
resp <- GET(zh_url, write_disk("data/zh_steuerfuss_timeseries.csv", overwrite = TRUE))
stopifnot("ZH Steuerfuss download failed" = status_code(resp) == 200)
zh_stf <- fread("data/zh_steuerfuss_timeseries.csv", encoding = "UTF-8")
cat("  Rows:", nrow(zh_stf), "| Municipalities:", length(unique(zh_stf$BFSNR)),
    "| Years:", paste(range(zh_stf$YEAR), collapse = "-"), "\n")

# ==============================================================================
# 2. Basel-Landschaft Steuerfuss (1975-2026)
# ==============================================================================
cat("\n=== Downloading BL Steuerfuss ===\n")
bl_url <- "https://data.bl.ch/explore/dataset/10580/download?format=csv&use_labels=true&delimiter=%3B"
resp <- GET(bl_url, write_disk("data/bl_steuerfuss.csv", overwrite = TRUE))
stopifnot("BL Steuerfuss download failed" = status_code(resp) == 200)
bl_stf <- fread("data/bl_steuerfuss.csv", sep = ";", encoding = "UTF-8")
cat("  Rows:", nrow(bl_stf), "| Years:", paste(range(bl_stf$jahr, na.rm = TRUE), collapse = "-"), "\n")

# ==============================================================================
# 3. BL Population (dataset 10040: 1980-2025)
# ==============================================================================
cat("\n=== Downloading BL Population ===\n")
resp <- GET("https://data.bl.ch/explore/dataset/10040/download?format=csv&use_labels=true&delimiter=%3B",
            write_disk("data/bl_population.csv", overwrite = TRUE), timeout(30))
stopifnot("BL population download failed" = status_code(resp) == 200)
bl_pop_raw <- fread("data/bl_population.csv", sep = ";", encoding = "UTF-8")
cat("  Rows:", nrow(bl_pop_raw), "| Years:", paste(range(bl_pop_raw$jahr), collapse = "-"), "\n")

# ==============================================================================
# 4. BFS Population via PXWeb (ZH + BL municipalities, 2010-2024)
# ==============================================================================
cat("\n=== Querying BFS PXWeb for population ===\n")

# First get metadata to find municipality codes
meta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102010000_101/px-x-0102010000_101.px"
meta_resp <- GET(meta_url, timeout(30))
meta <- fromJSON(content(meta_resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)

geo_var <- meta$variables[[2]]
geo_vals <- unlist(geo_var$values)
year_vals <- unlist(meta$variables[[1]]$values)

# Select 4-digit municipality codes for ZH (1-261) and BL (2761-2849)
is_muni <- nchar(geo_vals) == 4
muni_nums <- as.integer(geo_vals[is_muni])
zh_codes <- geo_vals[is_muni][muni_nums <= 261]
bl_codes <- geo_vals[is_muni][muni_nums >= 2761 & muni_nums <= 2849]
target_codes <- c(zh_codes, bl_codes)
cat("  ZH municipalities:", length(zh_codes), "| BL:", length(bl_codes), "\n")

# Query in batches (50 municipalities at a time to stay within limits)
batch_size <- 50
all_pop <- list()
for (batch_start in seq(1, length(target_codes), batch_size)) {
  batch_end <- min(batch_start + batch_size - 1, length(target_codes))
  batch_codes <- target_codes[batch_start:batch_end]

  query_json <- sprintf(
    '{"query":[{"code":"Jahr","selection":{"filter":"item","values":[%s]}},{"code":"%s","selection":{"filter":"item","values":[%s]}},{"code":"Bev\\u00f6lkerungstyp","selection":{"filter":"item","values":["1"]}},{"code":"Staatsangeh\\u00f6rigkeit (Kategorie)","selection":{"filter":"item","values":["-99999"]}},{"code":"Geschlecht","selection":{"filter":"item","values":["-99999"]}},{"code":"Alter","selection":{"filter":"item","values":["-99999"]}}],"response":{"format":"json-stat2"}}',
    paste0('"', year_vals, '"', collapse = ","),
    geo_var$code,
    paste0('"', batch_codes, '"', collapse = ",")
  )

  resp <- POST(meta_url, body = query_json, content_type_json(), timeout(60))
  if (status_code(resp) == 200) {
    jstat <- fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
    batch_dt <- jstat2_to_dt(jstat)
    all_pop[[length(all_pop) + 1]] <- batch_dt
    cat("  Batch", ceiling(batch_start / batch_size), ": got", nrow(batch_dt), "rows\n")
  } else {
    cat("  Batch", ceiling(batch_start / batch_size), "FAILED:", status_code(resp), "\n")
  }
  Sys.sleep(0.5)
}

pop_dt <- rbindlist(all_pop)
cat("  Total population rows:", nrow(pop_dt), "\n")
fwrite(pop_dt, "data/bfs_population.csv")

# ==============================================================================
# 5. STATENT (establishments by canton + sector) — BFS PXWeb
# ==============================================================================
cat("\n=== Querying BFS STATENT (canton-level as baseline) ===\n")

# STATENT is only available at canton level via PXWeb
# Get metadata
statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_101/px-x-0602010000_101.px"
statent_meta_resp <- GET(statent_url, timeout(30))
statent_meta <- fromJSON(content(statent_meta_resp, as = "text", encoding = "UTF-8"),
                         simplifyVector = FALSE)
cat("  STATENT title:", statent_meta$title, "\n")
for (i in seq_along(statent_meta$variables)) {
  v <- statent_meta$variables[[i]]
  cat("  Var", i, ":", v$code, "(", length(v$values), "values)\n")
  if (length(v$values) <= 10) cat("    ", paste(unlist(v$valueTexts), collapse = ", "), "\n")
}

# ==============================================================================
# 6. ZH Enterprise data via cantonal portal (alternative to BFS STATENT)
# ==============================================================================
cat("\n=== Searching ZH cantonal enterprise data ===\n")

# Try a range of dataset IDs from the ZH statistical office
# We need Arbeitsstätten (establishments) per municipality
found_ent <- FALSE
for (did in c(194, 195, 332, 333, 334, 443, 444, 445, 446, 447, 546, 547, 548, 549, 550,
              551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565)) {
  url <- sprintf("https://www.web.statistik.zh.ch/ogd/data/KANTON_ZUERICH_%d.csv", did)
  resp <- GET(url, write_disk("data/zh_test.csv", overwrite = TRUE), timeout(10))
  if (status_code(resp) == 200) {
    test <- tryCatch(fread("data/zh_test.csv", nrows = 5, encoding = "UTF-8"), error = function(e) NULL)
    if (!is.null(test) && nrow(test) > 0 && "INDIKATOR_NAME" %in% names(test)) {
      ind <- unique(test$INDIKATOR_NAME)
      if (any(grepl("Arbeitsstätten|Betrieb|Besch.ftigt|Vollzeit|Unternehm", ind, ignore.case = TRUE))) {
        cat("  FOUND enterprises in dataset", did, ":", paste(ind, collapse = "; "), "\n")
        file.copy("data/zh_test.csv", "data/zh_enterprises.csv", overwrite = TRUE)
        zh_ent <- fread("data/zh_enterprises.csv", encoding = "UTF-8")
        cat("  Rows:", nrow(zh_ent), "\n")
        found_ent <- TRUE
        break
      }
    }
  }
}
if (!found_ent) cat("  No enterprise dataset found in ZH OGD. Will construct from STATENT canton totals.\n")

# ==============================================================================
# Summary
# ==============================================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("ZH Steuerfuss: OK (", nrow(zh_stf), "rows)\n")
cat("BL Steuerfuss: OK (", nrow(bl_stf), "rows)\n")
cat("BFS Population: OK (", nrow(pop_dt), "rows)\n")
cat("BL Population: OK (", nrow(bl_pop_raw), "rows)\n")
cat("Files:\n")
for (f in list.files("data/", pattern = "\\.csv$")) {
  sz <- file.info(file.path("data", f))$size
  cat(sprintf("  %-40s %7.1f KB\n", f, sz / 1024))
}
