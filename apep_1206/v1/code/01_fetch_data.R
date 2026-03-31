# 01_fetch_data.R — Fetch STATENT + Steuerfuss + Population data
# Paper: Shell Games at the Municipal Border (apep_1206)
source("code/00_packages.R")

cat("=== Fetching Swiss municipal data ===\n")

# --- Helper: parse json-stat2 response into data.table ---
jstat2_to_dt <- function(raw_json) {
  jstat <- fromJSON(raw_json, simplifyVector = FALSE)
  dims <- as.character(jstat$id)
  # Handle NULLs in value array (missing data for some cells)
  vals <- sapply(jstat$value, function(x) if (is.null(x)) NA_real_ else x)

  label_lists <- lapply(dims, function(d) {
    cats <- jstat$dimension[[d]]$category
    idx <- unlist(cats$index)
    lab <- unlist(cats$label)
    if (is.null(names(idx))) {
      lab[order(idx)]
    } else {
      lab[names(sort(idx))]
    }
  })
  names(label_lists) <- dims

  # expand.grid preserves order (last dim varies fastest) — matches json-stat2
  grid <- as.data.table(expand.grid(rev(label_lists), stringsAsFactors = FALSE))
  setnames(grid, rev(dims))
  setcolorder(grid, dims)
  grid[, value := vals]
  return(grid)
}

# --- Helper: query PXWeb with batching ---
query_pxweb_batched <- function(api_url, year_codes, geo_codes,
                                 sector_code, unit_codes,
                                 batch_size = 50, sleep_sec = 0.5) {
  all_results <- list()
  n_batches <- ceiling(length(geo_codes) / batch_size)

  for (i in seq_len(n_batches)) {
    start <- (i - 1) * batch_size + 1
    end <- min(i * batch_size, length(geo_codes))
    batch <- geo_codes[start:end]

    query_body <- list(
      query = list(
        list(code = "Jahr",
             selection = list(filter = "item", values = as.list(year_codes))),
        list(code = "Gemeinde",
             selection = list(filter = "item", values = as.list(batch))),
        list(code = "Wirtschaftssektor",
             selection = list(filter = "item", values = as.list(sector_code))),
        list(code = "Beobachtungseinheit",
             selection = list(filter = "item", values = as.list(unit_codes)))
      ),
      response = list(format = "json-stat2")
    )

    resp <- POST(api_url,
                 body = toJSON(query_body, auto_unbox = TRUE),
                 content_type_json(),
                 timeout(180))

    if (status_code(resp) != 200) {
      stop(sprintf("PXWeb batch %d/%d failed: HTTP %d", i, n_batches, status_code(resp)))
    }

    dt <- jstat2_to_dt(content(resp, "text", encoding = "UTF-8"))
    all_results[[i]] <- dt

    cat(sprintf("  Batch %d/%d: %d rows\n", i, n_batches, nrow(dt)))
    if (i < n_batches) Sys.sleep(sleep_sec)
  }

  rbindlist(all_results)
}

# ============================================================
# 1. STATENT: Establishments and Employment by municipality
# ============================================================
cat("\n--- 1. Fetching STATENT metadata ---\n")
statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_102/px-x-0602010000_102.px"

meta_resp <- GET(statent_url, timeout(30))
stopifnot(status_code(meta_resp) == 200)
meta <- content(meta_resp, "parsed")

# Extract dimension codes
cat("Dimensions:\n")
for (v in meta$variables) {
  cat(sprintf("  %s: %d values\n", v$code, length(v$values)))
}

# Get municipality codes (filter to 4-digit numeric = actual municipalities)
geo_var <- meta$variables[[which(sapply(meta$variables, function(x) x$code) == "Gemeinde")]]
geo_codes <- unlist(geo_var$values)
geo_labels <- unlist(geo_var$valueTexts)

# Filter to actual municipalities (4-digit BFS numbers, exclude aggregates)
mun_mask <- nchar(geo_codes) <= 4 & as.numeric(geo_codes) >= 1 & as.numeric(geo_codes) <= 6999
mun_codes <- geo_codes[mun_mask]
cat(sprintf("Municipal codes: %d\n", length(mun_codes)))

# Get year codes
year_var <- meta$variables[[which(sapply(meta$variables, function(x) x$code) == "Jahr")]]
year_codes <- unlist(year_var$values)
cat(sprintf("Years available: %s to %s\n", min(year_codes), max(year_codes)))

# Get sector codes
sector_var <- meta$variables[[which(sapply(meta$variables, function(x) x$code) == "Wirtschaftssektor")]]
sector_codes <- unlist(sector_var$values)
sector_labels <- unlist(sector_var$valueTexts)
cat("Sectors:\n")
for (j in seq_along(sector_codes)) {
  cat(sprintf("  %s: %s\n", sector_codes[j], sector_labels[j]))
}

# Fetch: total across all sectors + sectoral breakdown (secondary vs tertiary)
# Unit codes: 1 = establishments, 2 = employment
cat("\n--- 1a. Fetching total STATENT (all sectors) ---\n")
statent_total <- query_pxweb_batched(
  statent_url, year_codes, mun_codes,
  sector_code = "999",  # Total
  unit_codes = c("1", "2"),
  batch_size = 50
)

cat(sprintf("Total STATENT rows: %d\n", nrow(statent_total)))

# Fetch sector-specific data (secondary = 2, tertiary = 3)
cat("\n--- 1b. Fetching sectoral STATENT ---\n")
# Sector codes confirmed from metadata: 2 = Sekundärer Sektor, 3 = Tertiärer Sektor
sector_2_code <- "2"
sector_3_code <- "3"
cat(sprintf("Secondary sector code: %s\n", sector_2_code))
cat(sprintf("Tertiary sector code: %s\n", sector_3_code))

statent_sectors <- query_pxweb_batched(
  statent_url, year_codes, mun_codes,
  sector_code = c(sector_2_code, sector_3_code),
  unit_codes = c("1", "2"),
  batch_size = 40
)

cat(sprintf("Sectoral STATENT rows: %d\n", nrow(statent_sectors)))

# Save raw STATENT
fwrite(statent_total, "data/statent_total_raw.csv")
fwrite(statent_sectors, "data/statent_sectors_raw.csv")

# ============================================================
# 2. Steuerfuss (Corporate tax multiplier) by municipality
# ============================================================
cat("\n--- 2. Fetching Steuerfuss data ---\n")

# 2a. Zurich canton
cat("  Fetching ZH Steuerfuss...\n")
zh_stf_url <- "https://www.web.statistik.zh.ch/ogd/data/steuerfuesse/kanton_zuerich_stf_timeseries.csv"
zh_file <- "data/zh_steuerfuss.csv"
download.file(zh_stf_url, zh_file, mode = "w", quiet = TRUE)
zh_stf <- fread(zh_file)
cat(sprintf("  ZH Steuerfuss: %d rows, cols: %s\n", nrow(zh_stf), paste(names(zh_stf), collapse = ", ")))

# 2b. Basel-Landschaft
cat("  Fetching BL Steuerfuss...\n")
bl_stf_url <- "https://data.bl.ch/explore/dataset/10580/download?format=csv&use_labels=true&delimiter=%3B"
bl_file <- "data/bl_steuerfuss.csv"
bl_resp <- GET(bl_stf_url, timeout(60))
stopifnot(status_code(bl_resp) == 200)
writeLines(content(bl_resp, "text", encoding = "UTF-8"), bl_file)
bl_stf <- fread(bl_file, sep = ";")
cat(sprintf("  BL Steuerfuss: %d rows, cols: %s\n", nrow(bl_stf), paste(names(bl_stf), collapse = ", ")))

# 2c. Try ESTV (Federal Tax Administration) for nationwide Steuerfuss
cat("  Trying ESTV nationwide tax burden data...\n")

# ESTV publishes Steuerbelastung tables on opendata.swiss
estv_ckan_url <- "https://opendata.swiss/api/3/action/package_show?id=steuerbelastung-in-den-gemeinden"
estv_resp <- GET(estv_ckan_url, timeout(30))

if (status_code(estv_resp) == 200) {
  estv_pkg <- content(estv_resp, "parsed")
  resources <- estv_pkg$result$resources
  cat(sprintf("  ESTV dataset found: %d resources\n", length(resources)))

  # Look for CSV/Excel resources with tax rate data
  for (r in resources) {
    cat(sprintf("    - %s (%s): %s\n", r$name %||% "unnamed", r$format %||% "?", substr(r$url %||% "", 1, 80)))
  }
} else {
  cat("  ESTV CKAN lookup failed, using cantonal sources only.\n")
}

# 2d. Try BFS PXWeb for nationwide Steuerfuss
cat("  Trying BFS PXWeb for tax data...\n")
# BFS table for municipal finance: je-d-18.04.02.01
tax_tables <- c(
  "px-x-1804020000_101/px-x-1804020000_101.px",
  "px-x-1804020000_102/px-x-1804020000_102.px"
)

for (tbl in tax_tables) {
  tax_url <- paste0("https://www.pxweb.bfs.admin.ch/api/v1/de/", tbl)
  tax_resp <- GET(tax_url, timeout(15))
  if (status_code(tax_resp) == 200) {
    tax_meta <- content(tax_resp, "parsed")
    cat(sprintf("  Found tax table: %s\n", tbl))
    for (v in tax_meta$variables) {
      cat(sprintf("    %s: %d values (%s)\n", v$code, length(v$values),
                  paste(head(unlist(v$valueTexts), 3), collapse = ", ")))
    }
    break
  }
}

# ============================================================
# 3. Population by municipality
# ============================================================
cat("\n--- 3. Fetching population data ---\n")
pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102020000_201/px-x-0102020000_201.px"

pop_resp <- GET(pop_url, timeout(30))
if (status_code(pop_resp) == 200) {
  pop_meta <- content(pop_resp, "parsed")
  cat("Population table dimensions:\n")
  for (v in pop_meta$variables) {
    cat(sprintf("  %s: %d values\n", v$code, length(v$values)))
  }

  # Find geo and year variables by position (names vary across tables)
  var_codes <- sapply(pop_meta$variables, function(x) x$code)
  cat("  Variable codes:", paste(var_codes, collapse = ", "), "\n")

  # Geo variable is typically the second one (contains municipality codes)
  geo_idx <- which(grepl("Gemeinde|Kanton|Bezirk", var_codes, ignore.case = TRUE))
  if (length(geo_idx) == 0) geo_idx <- 2
  pop_geo_var <- pop_meta$variables[[geo_idx[1]]]
  pop_geo_code <- pop_geo_var$code
  pop_geo_codes <- unlist(pop_geo_var$values)
  pop_geo_labels <- unlist(pop_geo_var$valueTexts)

  # Filter to municipal codes (6 dots prefix = municipality in BFS labels)
  mun_mask_pop <- grepl("^\\.{6}", pop_geo_labels)
  pop_mun_codes <- pop_geo_codes[mun_mask_pop]
  cat(sprintf("  Municipal geo codes: %d\n", length(pop_mun_codes)))

  # Year variable
  year_idx <- which(var_codes == "Jahr")
  pop_year_codes <- unlist(pop_meta$variables[[year_idx]]$values)
  # Restrict to 2011-2023 to match STATENT
  pop_year_codes <- pop_year_codes[as.numeric(pop_year_codes) >= 2011 & as.numeric(pop_year_codes) <= 2023]

  # Print other dimensions for debugging
  for (v in pop_meta$variables) {
    if (!v$code %in% c("Jahr", pop_geo_code)) {
      cat(sprintf("  Dim %s: %s\n", v$code,
                  paste(head(paste0(unlist(v$values), "=", unlist(v$valueTexts)), 5), collapse = ", ")))
    }
  }

  # Build query: total pop (first value of each filter dim)
  cat("  Fetching population by municipality...\n")
  pop_results <- list()
  pop_batch_size <- 100

  for (i in seq(1, length(pop_mun_codes), pop_batch_size)) {
    batch <- pop_mun_codes[i:min(i + pop_batch_size - 1, length(pop_mun_codes))]

    query_list <- list()
    for (v in pop_meta$variables) {
      if (v$code == "Jahr") {
        query_list[[length(query_list) + 1]] <- list(
          code = v$code,
          selection = list(filter = "item", values = as.list(pop_year_codes))
        )
      } else if (v$code == pop_geo_code) {
        query_list[[length(query_list) + 1]] <- list(
          code = v$code,
          selection = list(filter = "item", values = as.list(batch))
        )
      } else {
        # Use first value (total/aggregate)
        query_list[[length(query_list) + 1]] <- list(
          code = v$code,
          selection = list(filter = "item", values = list(unlist(v$values)[1]))
        )
      }
    }

    body <- list(query = query_list, response = list(format = "json-stat2"))
    resp <- POST(pop_url,
                 body = toJSON(body, auto_unbox = TRUE),
                 content_type_json(),
                 timeout(120))

    if (status_code(resp) == 200) {
      dt <- jstat2_to_dt(content(resp, "text", encoding = "UTF-8"))
      pop_results[[length(pop_results) + 1]] <- dt
      cat(sprintf("  Pop batch %d: %d rows\n",
                  ceiling(i / pop_batch_size), nrow(dt)))
    } else {
      cat(sprintf("  Pop batch %d: HTTP %d\n",
                  ceiling(i / pop_batch_size), status_code(resp)))
    }

    Sys.sleep(0.5)
  }

  if (length(pop_results) > 0) {
    pop_dt <- rbindlist(pop_results, fill = TRUE)
    fwrite(pop_dt, "data/population_raw.csv")
    cat(sprintf("Population data: %d rows saved\n", nrow(pop_dt)))
  }
} else {
  cat("Population table not accessible, will proceed without.\n")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Files in data/:\n"))
for (f in list.files("data/", pattern = "\\.(csv|rds)$")) {
  cat(sprintf("  %s: %s\n", f, format(file.size(file.path("data", f)), big.mark = ",")))
}
