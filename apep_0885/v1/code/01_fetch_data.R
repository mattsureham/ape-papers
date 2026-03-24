## 01_fetch_data.R — Fetch BFS data via PXWeb API
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## Helper: BFS PXWeb API query
## ============================================================================

bfs_query <- function(table_id, query_body, max_retries = 3) {
  url <- paste0(
    "https://www.pxweb.bfs.admin.ch/api/v1/de/",
    table_id, "/", table_id, ".px"
  )
  payload <- list(query = query_body, response = list(format = "json"))
  for (attempt in 1:max_retries) {
    resp <- httr::POST(
      url = url,
      body = jsonlite::toJSON(payload, auto_unbox = TRUE),
      httr::content_type_json(),
      httr::add_headers(Accept = "application/json")
    )
    if (httr::status_code(resp) == 200) {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      return(jsonlite::fromJSON(txt, simplifyVector = FALSE))
    }
    cat("  Attempt", attempt, "status", httr::status_code(resp), "\n")
    if (attempt < max_retries) Sys.sleep(2^attempt)
  }
  stop("BFS query failed for ", table_id, ". Status: ", httr::status_code(resp))
}

parse_pxweb <- function(parsed) {
  col_codes <- sapply(parsed$columns, function(c) c$code)
  rows <- parsed$data
  if (length(rows) == 0) stop("No data returned from PXWeb")

  df_list <- lapply(rows, function(r) {
    key_vals <- unlist(r$key)
    data_vals <- unlist(r$values)
    c(key_vals, data_vals)
  })
  mat <- do.call(rbind, df_list)
  df <- as.data.frame(mat, stringsAsFactors = FALSE)
  names(df) <- col_codes
  df
}

## ============================================================================
## 1. Construction Expenditure by Canton (1994–2023)
## Table: px-x-0904010000_201
## We fetch canton-level aggregates for the main DiD
## ============================================================================

cat("=== Fetching Construction Expenditure by Canton (1994-2023) ===\n")

# Canton codes from the table
canton_codes <- c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR",
                  "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG",
                  "TI", "VD", "VS", "NE", "GE", "JU")

# Fetch in year batches to stay under PXWeb limits
fetch_canton_construction <- function(years, cantons) {
  query <- list(
    list(code = "Grossregion (<<) / Kanton (-) / Gemeinde (......)",
         selection = list(filter = "item", values = as.list(cantons))),
    list(code = "Art der Auftraggeber",
         selection = list(filter = "item", values = list("0"))),  # Total
    list(code = "Art der Bauwerke",
         selection = list(filter = "item", values = list("0", "6011"))),  # Total + Hochbau
    list(code = "Art der Arbeiten",
         selection = list(filter = "item", values = list("0", "4", "1"))),  # Total, Investment, Neubau
    list(code = "Beobachtungseinheit",
         selection = list(filter = "item", values = list("kost_j"))),
    list(code = "Jahr",
         selection = list(filter = "item", values = as.list(years)))
  )
  parsed <- bfs_query("px-x-0904010000_201", query)
  parse_pxweb(parsed)
}

years_all <- as.character(1994:2023)
construction_dfs <- list()
batch_size <- 10

for (i in seq(1, length(years_all), by = batch_size)) {
  batch <- years_all[i:min(i + batch_size - 1, length(years_all))]
  cat("  Fetching years", batch[1], "-", tail(batch, 1), "...\n")
  df <- fetch_canton_construction(batch, canton_codes)
  construction_dfs[[length(construction_dfs) + 1]] <- df
  cat("    Got", nrow(df), "rows\n")
  Sys.sleep(1)
}

construction_raw <- do.call(rbind, construction_dfs)
cat("Total canton construction rows:", nrow(construction_raw), "\n")
saveRDS(construction_raw, file.path(DATA_DIR, "construction_canton_raw.rds"))

## ============================================================================
## 2. Construction Expenditure by Municipality — Ticino + Controls
## Fetch municipal-level for Ticino, GR, VS, UR municipalities
## ============================================================================

cat("\n=== Fetching Construction Expenditure by Municipality (Ticino + Controls) ===\n")

# Get metadata for municipality codes
meta_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0904010000_201/px-x-0904010000_201.px"
meta_resp <- httr::GET(meta_url, httr::add_headers(Accept = "application/json"))
meta <- jsonlite::fromJSON(httr::content(meta_resp, as = "text", encoding = "UTF-8"),
                            simplifyVector = FALSE)

# Extract all municipality codes
geo_var <- meta$variables[[1]]
all_geo_codes <- sapply(geo_var$values, identity)
all_geo_texts <- sapply(geo_var$valueTexts, identity)

# Identify Ticino municipalities (BFS codes 5001-5399 + TI canton)
# and control municipalities (GR = Graubünden, VS = Valais, UR = Uri)
geo_df <- data.frame(code = all_geo_codes, text = all_geo_texts, stringsAsFactors = FALSE)

# Ticino municipalities have codes starting with 5 (district 50-53)
# GR municipalities: codes starting with 37-39
# VS municipalities: codes starting with 60-62
# UR municipalities: codes starting with 12

# Filter for cantonal and select municipal codes
ticino_codes <- geo_df$code[grepl("^5[0-3]", geo_df$code)]
gr_codes <- geo_df$code[grepl("^3[7-9]", geo_df$code)]
vs_codes <- geo_df$code[grepl("^6[0-2]", geo_df$code)]
ur_codes <- geo_df$code[grepl("^12", geo_df$code)]

cat("  Ticino municipalities:", length(ticino_codes), "\n")
cat("  Graubünden municipalities:", length(gr_codes), "\n")
cat("  Valais municipalities:", length(vs_codes), "\n")
cat("  Uri municipalities:", length(ur_codes), "\n")

all_muni_codes <- c(ticino_codes, gr_codes, vs_codes, ur_codes)
cat("  Total municipalities:", length(all_muni_codes), "\n")

# Fetch municipal construction in batches
fetch_muni_construction <- function(years, muni_codes) {
  query <- list(
    list(code = "Grossregion (<<) / Kanton (-) / Gemeinde (......)",
         selection = list(filter = "item", values = as.list(muni_codes))),
    list(code = "Art der Auftraggeber",
         selection = list(filter = "item", values = list("0"))),
    list(code = "Art der Bauwerke",
         selection = list(filter = "item", values = list("0"))),  # Total only for muni
    list(code = "Art der Arbeiten",
         selection = list(filter = "item", values = list("0"))),  # Total
    list(code = "Beobachtungseinheit",
         selection = list(filter = "item", values = list("kost_j"))),
    list(code = "Jahr",
         selection = list(filter = "item", values = as.list(years)))
  )
  parsed <- bfs_query("px-x-0904010000_201", query)
  parse_pxweb(parsed)
}

# We need to batch municipalities too (max ~5000 cells per query)
# 300 munis × 1 × 1 × 1 × 1 × 10 years = 3000 cells per batch
muni_constr_dfs <- list()
year_batches <- split(years_all, ceiling(seq_along(years_all) / 10))

for (yb in year_batches) {
  # Also batch municipalities if needed
  muni_batches <- split(all_muni_codes, ceiling(seq_along(all_muni_codes) / 200))
  for (mb in muni_batches) {
    cat("  Munis:", length(mb), "× Years:", length(yb), "...\n")
    tryCatch({
      df <- fetch_muni_construction(yb, mb)
      muni_constr_dfs[[length(muni_constr_dfs) + 1]] <- df
      cat("    Got", nrow(df), "rows\n")
    }, error = function(e) {
      cat("    WARNING: Batch failed:", e$message, "\n")
    })
    Sys.sleep(1)
  }
}

if (length(muni_constr_dfs) > 0) {
  construction_muni_raw <- do.call(rbind, muni_constr_dfs)
  cat("Total municipal construction rows:", nrow(construction_muni_raw), "\n")
  saveRDS(construction_muni_raw, file.path(DATA_DIR, "construction_muni_raw.rds"))
} else {
  stop("FATAL: No municipal construction data retrieved")
}

## ============================================================================
## 3. HESTA Tourism by Canton (2005–2025)
## Table: px-x-1003020000_102
## ============================================================================

cat("\n=== Fetching HESTA Canton Tourism (2005-2025) ===\n")

hesta_query <- list(
  list(code = "Jahr",
       selection = list(filter = "item",
                        values = as.list(as.character(2005:2025)))),
  list(code = "Monat",
       selection = list(filter = "item", values = list("YYYY"))),  # Annual
  list(code = "Kanton",
       selection = list(filter = "all", values = list("*"))),
  list(code = "Herkunftsland",
       selection = list(filter = "item",
                        values = list("00", "1", "11", "14"))),
  # Total, Swiss, German, Italian
  list(code = "Indikator",
       selection = list(filter = "item", values = list("2")))  # Overnights
)

hesta_parsed <- bfs_query("px-x-1003020000_102", hesta_query)
hesta_canton_raw <- parse_pxweb(hesta_parsed)
cat("HESTA canton rows:", nrow(hesta_canton_raw), "\n")
saveRDS(hesta_canton_raw, file.path(DATA_DIR, "hesta_canton_raw.rds"))

## ============================================================================
## 4. HESTA Tourism by Municipality (2013–2025)
## Table: px-x-1003020000_101
## ============================================================================

cat("\n=== Fetching HESTA Municipal Tourism (2013-2025) ===\n")

# Fetch annual totals by municipality, total + Swiss tourists
hesta_muni_query <- list(
  list(code = "Jahr",
       selection = list(filter = "item",
                        values = as.list(as.character(2013:2025)))),
  list(code = "Monat",
       selection = list(filter = "item", values = list("YYYY"))),
  list(code = "Gemeinde",
       selection = list(filter = "all", values = list("*"))),
  list(code = "Herkunftsland",
       selection = list(filter = "item", values = list("00", "1"))),
  list(code = "Indikator",
       selection = list(filter = "item", values = list("2")))
)

hesta_muni_parsed <- bfs_query("px-x-1003020000_101", hesta_muni_query)
hesta_muni_raw <- parse_pxweb(hesta_muni_parsed)
cat("HESTA municipal rows:", nrow(hesta_muni_raw), "\n")
saveRDS(hesta_muni_raw, file.path(DATA_DIR, "hesta_muni_raw.rds"))

## ============================================================================
## 5. Cantonal Reference Data
## ============================================================================

cantonal_pop <- data.frame(
  canton_abbr = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR",
                  "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG",
                  "TI", "VD", "VS", "NE", "GE", "JU"),
  canton_id = as.character(1:26),
  canton_name = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                  "Nidwalden", "Glarus", "Zug", "Fribourg",
                  "Solothurn", "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
                  "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen", "Graubünden",
                  "Aargau", "Thurgau",
                  "Ticino", "Vaud", "Valais", "Neuchâtel", "Genève", "Jura"),
  pop_2015 = c(1487969, 1026513, 403397, 36145, 155863, 37378,
               42556, 40147, 124007, 311914,
               269441, 198206, 285624, 80769, 54954, 15984, 499065, 197550,
               663462, 270709,
               354375, 784822, 339060, 178107, 490578, 73122),
  is_ticino = c(0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 1,0,0,0,0,0),
  is_alpine_control = c(0,0,0,1,0,0,0,0,0,0, 0,0,0,0,0,0,0,1,0,0, 0,0,1,0,0,0),
  stringsAsFactors = FALSE
)
saveRDS(cantonal_pop, file.path(DATA_DIR, "cantonal_pop.rds"))

## ============================================================================
## Summary
## ============================================================================

cat("\n=== Data Fetch Summary ===\n")
cat("Construction (canton):", nrow(construction_raw), "rows\n")
cat("Construction (municipal):", nrow(construction_muni_raw), "rows\n")
cat("HESTA tourism (canton):", nrow(hesta_canton_raw), "rows\n")
cat("HESTA tourism (municipal):", nrow(hesta_muni_raw), "rows\n")
cat("Cantonal reference: 26 cantons\n")
cat("\nAll data saved to:", normalizePath(DATA_DIR), "\n")
