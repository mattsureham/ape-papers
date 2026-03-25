## 01_fetch_data.R — Download Swiss municipal data
## Sources: Canton Zurich Steuerfuss, Jahresrechnungen, BFS STATENT, BFS population

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. Steuerfuss (tax multipliers) ─────────────────────────────────────────
cat("Fetching Steuerfuss time series...\n")
stf_url <- "https://www.web.statistik.zh.ch/ogd/data/steuerfuesse/kanton_zuerich_stf_timeseries.csv"
stf_file <- file.path(data_dir, "steuerfuss_timeseries.csv")
download.file(stf_url, stf_file, quiet = TRUE)
stf <- fread(stf_file)
cat(sprintf("  Steuerfuss: %d rows, %d municipalities, years %d-%d\n",
            nrow(stf), uniqueN(stf$BFSNR), min(stf$YEAR), max(stf$YEAR)))
stopifnot("JUR_PERS" %in% names(stf), nrow(stf) > 100)

# ── 2. Jahresrechnungen (municipal financial accounts) ──────────────────────
cat("Fetching Jahresrechnungen (political municipalities)...\n")
jr_url <- "https://www.web.statistik.zh.ch/ogd/data/KANTON_ZUERICH_gpfi_jahresrechung_politischeGemeinden.csv"
jr_file <- file.path(data_dir, "jahresrechnungen_pol_gemeinden.csv")
download.file(jr_url, jr_file, quiet = TRUE)
jr <- fread(jr_file, fill = TRUE)
cat(sprintf("  Jahresrechnungen: %d rows, %d indicators, years %d-%d\n",
            nrow(jr), uniqueN(jr$INDIKATOR_ID), min(jr$JAHR), max(jr$JAHR)))
stopifnot(nrow(jr) > 10000)

# ── 3. BFS STATENT (establishments by municipality) ─────────────────────────
cat("Fetching STATENT establishment counts via PXWeb...\n")
statent_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_102/px-x-0602010000_102.px"

# First, get metadata to find Zurich municipalities
meta <- httr::GET(statent_url) |> httr::content(as = "text", encoding = "UTF-8") |> jsonlite::fromJSON()
gem_codes <- meta$variables$values[[2]]  # Municipality codes
gem_names <- meta$variables$valueTexts[[2]]  # Municipality names
yr_codes  <- meta$variables$values[[1]]  # Year codes

# Filter to Zurich canton (BFS numbers roughly 0001-0298 for Zurich)
# Zurich municipalities have BFS numbers starting with 0001 to ~0298
zh_mask <- as.integer(gem_codes) >= 1 & as.integer(gem_codes) <= 298
zh_codes <- gem_codes[zh_mask]
cat(sprintf("  Found %d Zurich municipality codes in STATENT\n", length(zh_codes)))

# Query in batches (PXWeb limit ~5000 values per call)
batch_size <- 50
statent_list <- list()
for (i in seq(1, length(zh_codes), by = batch_size)) {
  batch <- zh_codes[i:min(i + batch_size - 1, length(zh_codes))]
  body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = yr_codes)),
      list(code = "Gemeinde", selection = list(filter = "item", values = batch)),
      list(code = "Wirtschaftssektor", selection = list(filter = "item", values = list("999"))),
      list(code = "Beobachtungseinheit", selection = list(filter = "item", values = list("1", "2")))
    ),
    response = list(format = "json")
  )
  resp <- httr::POST(statent_url, body = jsonlite::toJSON(body, auto_unbox = TRUE),
                      httr::content_type_json(), encode = "raw")
  if (httr::status_code(resp) == 200) {
    dat <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    if (!is.null(dat$data)) {
      rows <- dat$data
      dt <- data.table(
        year  = as.integer(sapply(rows$key, `[`, 1)),
        bfsnr = as.integer(sapply(rows$key, `[`, 2)),
        unit  = sapply(rows$key, `[`, 4),
        value = as.numeric(rows$values)
      )
      statent_list[[length(statent_list) + 1]] <- dt
    }
  }
  Sys.sleep(0.3)
}
statent <- rbindlist(statent_list)
statent_wide <- dcast(statent, year + bfsnr ~ unit, value.var = "value")
names(statent_wide)[names(statent_wide) == "1"] <- "establishments"
names(statent_wide)[names(statent_wide) == "2"] <- "employees"
cat(sprintf("  STATENT: %d rows, years %d-%d\n",
            nrow(statent_wide), min(statent_wide$year), max(statent_wide$year)))
fwrite(statent_wide, file.path(data_dir, "statent_zh.csv"))

# ── 4. BFS Population (demographic balance by municipality) ─────────────────
cat("Fetching population data via PXWeb...\n")
pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102020000_201/px-x-0102020000_201.px"

# Get metadata to find municipality index codes
pop_meta <- httr::GET(pop_url) |> httr::content(as = "text", encoding = "UTF-8") |> jsonlite::fromJSON()
geo_codes <- pop_meta$variables$values[[2]]
geo_names <- pop_meta$variables$valueTexts[[2]]
pop_yr_codes <- pop_meta$variables$values[[1]]

# Extract BFS numbers from "......XXXX Name" format
bfs_from_name <- str_extract(geo_names, "(?<=\\.{6})\\d{4}")
zh_pop_mask <- !is.na(bfs_from_name) & as.integer(bfs_from_name) >= 1 & as.integer(bfs_from_name) <= 298
zh_pop_idx <- geo_codes[zh_pop_mask]
zh_pop_bfs <- as.integer(bfs_from_name[zh_pop_mask])
cat(sprintf("  Found %d Zurich municipalities in population data\n", length(zh_pop_idx)))

# Fetch population in batches
pop_list <- list()
for (i in seq(1, length(zh_pop_idx), by = batch_size)) {
  batch <- zh_pop_idx[i:min(i + batch_size - 1, length(zh_pop_idx))]
  body <- list(
    query = list(
      list(code = "Jahr", selection = list(filter = "item", values = pop_yr_codes)),
      list(code = unbox("Kanton (-) / Bezirk (>>) / Gemeinde (......)"),
           selection = list(filter = "item", values = batch)),
      list(code = unbox("Staatsangehörigkeit (Kategorie)"),
           selection = list(filter = "item", values = list("0"))),
      list(code = "Geschlecht", selection = list(filter = "item", values = list("0"))),
      list(code = unbox("Demografische Komponente"),
           selection = list(filter = "item", values = list("16")))
    ),
    response = list(format = "json")
  )
  resp <- httr::POST(pop_url, body = jsonlite::toJSON(body, auto_unbox = TRUE),
                      httr::content_type_json(), encode = "raw")
  if (httr::status_code(resp) == 200) {
    dat <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    if (!is.null(dat$data)) {
      rows <- dat$data
      dt <- data.table(
        year     = as.integer(sapply(rows$key, `[`, 1)),
        geo_idx  = sapply(rows$key, `[`, 2),
        population = as.numeric(rows$values)
      )
      pop_list[[length(pop_list) + 1]] <- dt
    }
  }
  Sys.sleep(0.3)
}

pop <- rbindlist(pop_list)
# Map geo index back to BFS number
idx_to_bfs <- data.table(geo_idx = zh_pop_idx, bfsnr = zh_pop_bfs)
pop <- merge(pop, idx_to_bfs, by = "geo_idx")[, .(year, bfsnr, population)]
cat(sprintf("  Population: %d rows, years %d-%d\n",
            nrow(pop), min(pop$year), max(pop$year)))
fwrite(pop, file.path(data_dir, "population_zh.csv"))

# ── Validation ──────────────────────────────────────────────────────────────
cat("\n=== DATA FETCH SUMMARY ===\n")
cat(sprintf("Steuerfuss:      %d rows, %d municipalities\n", nrow(stf), uniqueN(stf$BFSNR)))
cat(sprintf("Jahresrechnungen: %d rows, %d entities\n", nrow(jr), uniqueN(jr$KOERPERSCHAFT_NAME)))
cat(sprintf("STATENT:          %d rows, %d municipalities\n", nrow(statent_wide), uniqueN(statent_wide$bfsnr)))
cat(sprintf("Population:       %d rows, %d municipalities\n", nrow(pop), uniqueN(pop$bfsnr)))

stopifnot(nrow(stf) > 100, nrow(jr) > 10000, nrow(statent_wide) > 100, nrow(pop) > 100)
cat("All data fetched successfully.\n")
