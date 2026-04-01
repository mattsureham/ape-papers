## 01_fetch_data.R — Fetch BFS STATENT municipal employment data via PXWeb API
source("00_packages.R")

cat("=== Fetching BFS STATENT Municipal Data (Table 102) ===\n")

## ---- API configuration ----
api_url_102 <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0602010000_102/px-x-0602010000_102.px"

## ---- Step 1: Get metadata to discover dimension codes ----
cat("Fetching metadata...\n")
meta <- jsonlite::fromJSON(api_url_102)

years_avail  <- meta$variables$values[[1]]
gems_avail   <- meta$variables$values[[2]]
sectors_avail <- meta$variables$values[[3]]
obs_avail    <- meta$variables$values[[4]]

gem_labels   <- setNames(meta$variables$valueTexts[[2]], meta$variables$values[[2]])
sec_labels   <- setNames(meta$variables$valueTexts[[3]], meta$variables$values[[3]])
obs_labels   <- setNames(meta$variables$valueTexts[[4]], meta$variables$values[[4]])

cat("Available years:", paste(years_avail, collapse = ", "), "\n")
cat("Number of municipalities:", length(gems_avail), "\n")
cat("Sectors:", paste(sec_labels, collapse = " | "), "\n")
cat("Observation units:", paste(obs_labels, collapse = " | "), "\n")

## ---- Step 2: Select years 2011-2023 ----
target_years <- as.character(2011:2023)
target_years <- target_years[target_years %in% years_avail]
stopifnot("Need at least 2011-2023" = length(target_years) >= 13)
cat("Selected years:", paste(target_years, collapse = ", "), "\n")

## ---- Step 3: Custom JSON parser for PXWeb ----
parse_pxweb_json <- function(json_text) {
  parsed <- jsonlite::fromJSON(json_text, simplifyVector = FALSE)
  rows <- parsed$data
  if (length(rows) == 0) return(data.table())
  rbindlist(lapply(rows, function(r) {
    as.data.table(c(
      setNames(r$key, paste0("k", seq_along(r$key))),
      setNames(r$values, paste0("v", seq_along(r$values)))
    ))
  }))
}

## ---- Step 4: Fetch data in chunks (API limit ~5000 values/call) ----
## With ~2172 municipalities x 4 sectors x 3 obs_units = ~26K per year
## Must chunk by municipality AND year

chunk_size <- 300  # municipalities per chunk
gem_chunks <- split(gems_avail, ceiling(seq_along(gems_avail) / chunk_size))

cat("Fetching data: ", length(target_years), " years x ", length(gem_chunks), " chunks\n")

all_data <- list()
chunk_counter <- 0

for (yr in target_years) {
  for (i in seq_along(gem_chunks)) {
    chunk_counter <- chunk_counter + 1

    query_body <- list(
      query = list(
        list(code = meta$variables$code[[1]],
             selection = list(filter = "item", values = list(yr))),
        list(code = meta$variables$code[[2]],
             selection = list(filter = "item", values = gem_chunks[[i]])),
        list(code = meta$variables$code[[3]],
             selection = list(filter = "item", values = as.list(sectors_avail))),
        list(code = meta$variables$code[[4]],
             selection = list(filter = "item", values = as.list(obs_avail)))
      ),
      response = list(format = "json")
    )

    resp <- httr::POST(
      api_url_102,
      body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
      httr::content_type_json(),
      httr::timeout(180)
    )

    if (httr::status_code(resp) != 200) {
      cat("  ERROR: chunk", i, "year", yr, "status", httr::status_code(resp), "\n")
      Sys.sleep(1)
      # Retry once
      resp <- httr::POST(
        api_url_102,
        body = jsonlite::toJSON(query_body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(180)
      )
      if (httr::status_code(resp) != 200) {
        stop("API call failed after retry. Year: ", yr, " Chunk: ", i,
             " Status: ", httr::status_code(resp))
      }
    }

    raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    dt <- parse_pxweb_json(raw_text)
    if (nrow(dt) > 0) all_data[[chunk_counter]] <- dt

    if (chunk_counter %% 20 == 0) cat("  Completed", chunk_counter, "chunks\n")
    Sys.sleep(0.3)  # Rate limiting
  }
}

cat("All chunks fetched. Binding...\n")
df_raw <- rbindlist(all_data)
cat("Raw rows:", nrow(df_raw), "\n")

stopifnot("No data returned from API" = nrow(df_raw) > 0)

## ---- Step 5: Rename columns ----
setnames(df_raw, c("k1", "k2", "k3", "k4", "v1"),
         c("year", "gem_id", "sector", "obs_unit", "value"))

df_raw[, year := as.integer(year)]
df_raw[, value := as.numeric(value)]

## Add human-readable labels
df_raw[, gem_name := gem_labels[gem_id]]
df_raw[, sector_name := sec_labels[sector]]
df_raw[, obs_name := obs_labels[obs_unit]]

## ---- Step 6: Save lookups and raw data ----
fwrite(df_raw, "../data/statent_municipal_raw.csv")
cat("Saved: data/statent_municipal_raw.csv (", nrow(df_raw), " rows)\n")

## Save lookup tables
gem_lookup <- data.table(gem_id = names(gem_labels), gem_name = unname(gem_labels))
sec_lookup <- data.table(sector = names(sec_labels), sector_name = unname(sec_labels))
obs_lookup <- data.table(obs_unit = names(obs_labels), obs_name = unname(obs_labels))

fwrite(gem_lookup, "../data/gem_lookup.csv")
fwrite(sec_lookup, "../data/sector_lookup.csv")
fwrite(obs_lookup, "../data/obs_lookup.csv")

## ---- Step 7: Quick validation ----
cat("\n=== Data Validation ===\n")
cat("Years:", sort(unique(df_raw$year)), "\n")
cat("Municipalities:", uniqueN(df_raw$gem_id), "\n")
cat("Sectors:", unique(df_raw$sector_name), "\n")
cat("Obs units:", unique(df_raw$obs_name), "\n")

# Check a known municipality (Zurich = 261)
zurich <- df_raw[gem_id == "261" & year == 2014]
cat("\nZurich 2014 check:\n")
print(zurich[, .(sector_name, obs_name, value)])

cat("\n=== Data fetch complete ===\n")
