## =============================================================================
## 01_fetch_data.R — Data Acquisition for Lex Weber Rental Market Study
## Paper: Protecting Landscapes, Punishing Renters (apep_0567)
## =============================================================================
## Sources:
##   1. Vacancy data (Leerwohnungszählung) — BFS SSE (SDMX) API: DF_LWZ_1
##   2. Population data (STATPOP) — BFS PXWeb API
##   3. Employment data (STATENT) — BFS PXWeb API
##   4. Second-home shares (ARE Wohnungsinventar) — geo.admin.ch
##   5. Building permits — BFS PXWeb API (non-critical)
##   6. Municipal correspondence table — AGVCH mutations API
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## -- Helper: browser-like HTTP headers ----------------------------------------
http_get <- function(url, ...) {
  GET(url, add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    `Accept` = "application/json, text/csv, */*"
  ), timeout(120), config(followlocation = TRUE), ...)
}

## =============================================================================
## 1. VACANCY DATA (Leerwohnungszählung) — BFS SSE API
##    Dataset: DF_LWZ_1 (municipality-level vacancy counts and rates, 1995-2025)
##    Uses BFS R package's bfs_get_sse_data() with dimension filters.
## =============================================================================
cat("\n=== 1. Fetching vacancy data (Leerwohnungszählung) via BFS SSE ===\n")

library(BFS)

## 1A: Get vacancy counts (total, all types)
cat("  Fetching vacancy counts (MEASURE_DIMENSION=V)...\n")
vac_counts <- tryCatch({
  bfs_get_sse_data("DF_LWZ_1", language = "de",
    query = list(WOHN_ANZAHL = "_T", LEERWOHN_TYP = "_T", MEASURE_DIMENSION = "V"))
}, error = function(e) stop("FATAL: BFS SSE vacancy count fetch failed: ", e$message))
vac_counts <- as.data.table(vac_counts)
cat("  Vacancy counts:", nrow(vac_counts), "rows\n")

## 1B: Get vacancy rates (percentage)
cat("  Fetching vacancy rates (MEASURE_DIMENSION=PC)...\n")
vac_rates <- tryCatch({
  bfs_get_sse_data("DF_LWZ_1", language = "de",
    query = list(WOHN_ANZAHL = "_T", LEERWOHN_TYP = "_T", MEASURE_DIMENSION = "PC"))
}, error = function(e) stop("FATAL: BFS SSE vacancy rate fetch failed: ", e$message))
vac_rates <- as.data.table(vac_rates)
cat("  Vacancy rates:", nrow(vac_rates), "rows\n")

## 1C: Build name-to-code crosswalk from SSE metadata
cat("  Building municipality code crosswalk from SSE metadata...\n")
meta <- as.data.table(bfs_get_sse_metadata("DF_LWZ_1"))
gde_codes <- meta[code == "GR_KT_GDE", .(geo_name = valueText, bfs_nr = as.integer(value))]
# Keep only valid municipality codes (1-6999)
gde_codes <- gde_codes[bfs_nr >= 1 & bfs_nr <= 6999]
cat("  Municipality codes mapped:", nrow(gde_codes), "\n")

## 1D: Merge codes with data
vacancy <- merge(
  vac_counts[, .(year = as.integer(TIME_PERIOD), geo_name = GR_KT_GDE, vacant_count = value)],
  vac_rates[, .(year = as.integer(TIME_PERIOD), geo_name = GR_KT_GDE, vacancy_rate = value)],
  by = c("year", "geo_name"), all = TRUE
)
vacancy <- merge(vacancy, gde_codes, by = "geo_name", all.x = TRUE)
cat("  Combined vacancy data:", nrow(vacancy), "rows\n")
cat("  With BFS codes:", sum(!is.na(vacancy$bfs_nr)), "rows\n")
cat("  Year range:", min(vacancy$year), "-", max(vacancy$year), "\n")
cat("  Municipalities:", uniqueN(vacancy$bfs_nr[!is.na(vacancy$bfs_nr)]), "\n")

fwrite(vacancy, file.path(data_dir, "vacancy_municipal.csv"))
cat("  Saved vacancy_municipal.csv\n")

## =============================================================================
## 2. POPULATION DATA (Demografische Bilanz)
##    BFS PXWeb table px-x-0102020000_201 — population by municipality, 1981-2024
##    Dimension: "Bestand am 1. Januar" for stock population
##    URL requires folder/table.px format for PXWeb API
## =============================================================================
cat("\n=== 2. Fetching population data (Demografische Bilanz) ===\n")

pxweb_base <- "https://www.pxweb.bfs.admin.ch/api/v1/de/"
pop_url <- paste0(pxweb_base, "px-x-0102020000_201/px-x-0102020000_201.px")

pop_meta_resp <- tryCatch(http_get(pop_url), error = function(e) NULL)
if (is.null(pop_meta_resp) || status_code(pop_meta_resp) != 200)
  stop("FATAL: Cannot access population table px-x-0102020000_201")

pop_meta <- fromJSON(content(pop_meta_resp, "text", encoding = "UTF-8"))
cat("  Table:", pop_meta$title, "\n")

# Query year by year: total nationality, total gender, stock population (Bestand)
# Geo column code from metadata
geo_code <- pop_meta$variables$code[2]  # "Kanton (-) / Bezirk (>>) / Gemeinde (......)"
years <- as.character(1995:2024)

pop_chunks <- list()
for (yr in years) {
  q <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = list(yr))),
      list(code = geo_code, selection = list(filter = "all", values = list("*"))),
      list(code = pop_meta$variables$code[3],  # Staatsangehörigkeit
           selection = list(filter = "item", values = list("0"))),
      list(code = pop_meta$variables$code[4],  # Geschlecht
           selection = list(filter = "item", values = list("0"))),
      list(code = pop_meta$variables$code[5],  # Demografische Komponente
           selection = list(filter = "item", values = list("0")))  # Bestand am 1. Januar
    ),
    response = list(format = "csv")
  )
  resp <- tryCatch(
    POST(pop_url, body = toJSON(q, auto_unbox = TRUE),
         content_type_json(), timeout(120)),
    error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    raw <- content(resp, "raw")
    txt <- iconv(rawToChar(raw), from = "Windows-1252", to = "UTF-8")
    pop_chunks[[yr]] <- fread(text = txt, header = TRUE)
    if (yr %in% c("1995", "2000", "2010", "2020", "2024"))
      cat("    Year", yr, ":", nrow(pop_chunks[[yr]]), "rows\n")
  }
  Sys.sleep(0.2)
}

if (length(pop_chunks) == 0)
  stop("FATAL: Cannot fetch population data from BFS.")

pop_raw <- rbindlist(pop_chunks, fill = TRUE)
cat("  Population data:", nrow(pop_raw), "rows\n")
fwrite(pop_raw, file.path(data_dir, "statpop_municipal.csv"))

## =============================================================================
## 3. EMPLOYMENT DATA (STATENT)
##    BFS R package bfs_get_data — px-x-0602010000_102
##    Employment by municipality and NOGA sector (2011-present)
## =============================================================================
cat("\n=== 3. Fetching STATENT employment data ===\n")

cat("  Downloading STATENT sectoral data via BFS R package...\n")
statent_sector <- tryCatch({
  df <- bfs_get_data("px-x-0602010000_102", language = "de")
  as.data.table(df)
}, error = function(e) {
  stop("FATAL: Cannot fetch STATENT employment data: ", e$message)
})
cat("  STATENT data:", nrow(statent_sector), "rows,", ncol(statent_sector), "cols\n")
cat("  Columns:", paste(names(statent_sector), collapse = ", "), "\n")
fwrite(statent_sector, file.path(data_dir, "statent_sector.csv"))
cat("  Saved statent_sector.csv\n")

## =============================================================================
## 4. SECOND-HOME SHARES (ARE Wohnungsinventar)
##    geo.admin.ch identify API — bounding box queries for current ZWA snapshot
## =============================================================================
cat("\n=== 4. Fetching second-home share data (ARE Wohnungsinventar) ===\n")

layer <- "ch.are.wohnungsinventar-zweitwohnungsanteil"

# Use bounding boxes in LV95 (EPSG:2056)
all_features <- list()
boxes <- list(
  c(2485000, 1075000, 2580000, 1150000),
  c(2580000, 1075000, 2660000, 1150000),
  c(2660000, 1075000, 2835000, 1150000),
  c(2485000, 1150000, 2580000, 1200000),
  c(2580000, 1150000, 2660000, 1200000),
  c(2660000, 1150000, 2835000, 1200000),
  c(2485000, 1200000, 2580000, 1295000),
  c(2580000, 1200000, 2660000, 1295000),
  c(2660000, 1200000, 2835000, 1295000)
)

for (bi in seq_along(boxes)) {
  box <- boxes[[bi]]
  resp <- tryCatch(
    GET("https://api3.geo.admin.ch/rest/services/api/MapServer/identify",
        query = list(
          geometryType = "esriGeometryEnvelope",
          geometry = paste(box, collapse = ","),
          sr = 2056, layers = paste0("all:", layer),
          returnGeometry = "false", limit = 3000, tolerance = 0
        ), timeout(60)),
    error = function(e) { cat("    Box", bi, "error:", e$message, "\n"); NULL })
  if (!is.null(resp) && status_code(resp) == 200) {
    d <- content(resp, "parsed")
    if (!is.null(d$results)) {
      all_features <- c(all_features, d$results)
      cat("    Box", bi, ":", length(d$results), "features\n")
    }
  }
  Sys.sleep(0.5)
}

if (length(all_features) > 0) {
  zwa_current <- rbindlist(lapply(all_features, function(f) {
    a <- f$attributes
    data.table(
      gemeinde_nr    = a$gemeinde_nummer %||% a$gde_no %||% NA_integer_,
      gemeinde_name  = a$gemeinde_name %||% a$gde_name %||% NA_character_,
      total_dwellings = a$zwg_3150 %||% NA_real_,
      zwa_pct        = a$zwg_3120 %||% NA_real_,
      status         = a$status %||% NA_character_
    )
  }), fill = TRUE)
  zwa_current <- unique(zwa_current, by = "gemeinde_nr")
  n_above <- sum(zwa_current$zwa_pct >= 20, na.rm = TRUE)
  n_below <- sum(zwa_current$zwa_pct < 20, na.rm = TRUE)
  cat("  Current ZWA snapshot:", nrow(zwa_current), "municipalities\n")
  cat("    Above 20% (treated):", n_above, "\n")
  cat("    Below 20% (control):", n_below, "\n")
  fwrite(zwa_current, file.path(data_dir, "zwa_current.csv"))
} else {
  stop("FATAL: Cannot fetch second-home share data from geo.admin.ch.\n",
       "The 20% threshold defines treatment. Cannot proceed.")
}

## =============================================================================
## 5. BUILDING PERMITS / NEW CONSTRUCTION (non-critical)
## =============================================================================
cat("\n=== 5. Fetching building permits (non-critical) ===\n")

tryCatch({
  bau_dt <- bfs_get_data("px-x-0904010000_201", language = "de")
  bau_dt <- as.data.table(bau_dt)
  cat("  Building data:", nrow(bau_dt), "rows\n")
  fwrite(bau_dt, file.path(data_dir, "building_municipal.csv"))
}, error = function(e) {
  cat("  WARNING: No construction data (", e$message, "). Analysis can proceed.\n")
})

## =============================================================================
## 6. MUNICIPAL CORRESPONDENCE TABLE (AGVCH Mutations API)
## =============================================================================
cat("\n=== 6. Fetching municipal correspondence table (AGVCH) ===\n")

## 6A: Full mutation history
mutations_url <- paste0(
  "https://www.agvchapp.bfs.admin.ch/api/communes/mutations",
  "?includeTerritoryExchange=true",
  "&startPeriod=01-01-1990&endPeriod=31-12-2025")

tryCatch({
  resp <- GET(mutations_url, timeout(120))
  if (status_code(resp) != 200)
    stop("AGVCH mutations API returned status ", status_code(resp))
  mutations_raw <- content(resp, as = "text", encoding = "UTF-8")
  mutations <- fread(text = mutations_raw)
  cat("  Downloaded", nrow(mutations), "mutation records\n")
}, error = function(e) {
  stop("Failed to fetch merger data: ", e$message,
       "\nMunicipal mergers are critical for panel harmonization.")
})

mutations[, MutationDate := as.Date(MutationDate, format = "%d.%m.%Y")]
mutations[, mutation_year := year(MutationDate)]

# Build crosswalk: dissolved → successor
dissolved <- mutations[InitialStep == 29]
successors <- mutations[MutationNumber %in% dissolved$MutationNumber &
                          TerminalStep %in% c(21, 26)]
merger_xwalk <- merge(
  dissolved[, .(MutationNumber, dissolved_code = InitialCode,
                dissolved_name = InitialName, merger_year = mutation_year)],
  successors[, .(MutationNumber, successor_code = TerminalCode,
                 successor_name = TerminalName)],
  by = "MutationNumber", allow.cartesian = TRUE)
merger_xwalk <- unique(merger_xwalk)
cat("  Merger crosswalk:", nrow(merger_xwalk), "mappings\n")

fwrite(merger_xwalk, file.path(data_dir, "merger_crosswalk.csv"))
fwrite(mutations, file.path(data_dir, "mutations_full.csv"))

## 6B: Current municipality snapshot
cat("  Fetching current municipality snapshot...\n")
snap_resp <- tryCatch(
  GET("https://www.agvchapp.bfs.admin.ch/api/communes/snapshot?date=01-01-2024",
      timeout(60)),
  error = function(e) { cat("  Snapshot fetch failed\n"); NULL })
if (!is.null(snap_resp) && status_code(snap_resp) == 200) {
  snap_raw <- content(snap_resp, as = "text", encoding = "UTF-8")
  snapshot <- fread(text = snap_raw)
  cat("  Current municipalities:", nrow(snapshot), "\n")
  fwrite(snapshot, file.path(data_dir, "municipality_snapshot_2024.csv"))
}

## =============================================================================
## 7. DATA VALIDATION
## =============================================================================
cat("\n\n=== DATA VALIDATION ===\n")

data_files <- list.files(data_dir, pattern = "\\.(csv|rds)$", full.names = TRUE)
cat("Files in data directory:\n")
for (f in data_files)
  cat(sprintf("  %-45s %10s bytes\n", basename(f),
              format(file.info(f)$size, big.mark = ",")))

# Critical checks
vac <- fread(file.path(data_dir, "vacancy_municipal.csv"), nrows = 10)
stopifnot("Vacancy data must have rows" = nrow(vac) > 0)
cat("  Vacancy data: OK\n")

pop <- fread(file.path(data_dir, "statpop_municipal.csv"), nrows = 10)
stopifnot("Population data must have rows" = nrow(pop) > 0)
cat("  Population data: OK\n")

emp_files <- list.files(data_dir, pattern = "statent", full.names = TRUE)
stopifnot("Employment data must exist" = length(emp_files) > 0)
cat("  Employment data: OK\n")

zwa <- fread(file.path(data_dir, "zwa_current.csv"), nrows = 10)
stopifnot("ZWA data must have rows" = nrow(zwa) > 0)
cat("  Second-home share data: OK\n")

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("All critical datasets fetched successfully.\n")
