# 01b_assign_huc12.R — Assign HUC-12 to each facility via USGS WBD API
source("00_packages.R")

facilities <- readRDS("../data/facilities_raw.rds")
facilities[, lat := as.numeric(FAC_LAT)]
facilities[, lon := as.numeric(FAC_LONG)]
facilities <- facilities[!is.na(lat) & !is.na(lon)]

# Check for cached results
cache_file <- "../data/facility_huc12.rds"
if (file.exists(cache_file)) {
  cached <- readRDS(cache_file)
  cat("Loaded cached HUC-12 assignments:", nrow(cached), "\n")
  done_ids <- cached$NPDES_ID
} else {
  cached <- data.table()
  done_ids <- character(0)
}

# Focus on major facilities for V1 (core sample for consistent DMR reporting)
facilities <- facilities[CWP_MAJOR_MINOR_TYPE_FLAG == "M"]
cat("Major facilities:", nrow(facilities), "\n")

# Facilities still needing HUC-12
todo <- facilities[!(NPDES_ID %in% done_ids)]
cat("Facilities to look up:", nrow(todo), "\n")

if (nrow(todo) == 0) {
  cat("All facilities have HUC-12 assignments.\n")
  q("no")
}

# Batch lookup via USGS WBD API
# The point query endpoint handles one point at a time
# Rate limit: ~2-3 requests/second is safe

lookup_huc12 <- function(lat, lon) {
  url <- paste0("https://hydro.nationalmap.gov/arcgis/rest/services/wbd/MapServer/6/query",
                "?geometry=", lon, ",", lat,
                "&geometryType=esriGeometryPoint",
                "&inSR=4326",
                "&spatialRel=esriSpatialRelIntersects",
                "&outFields=huc12,name",
                "&f=json",
                "&returnGeometry=false")
  res <- tryCatch(httr::GET(url, httr::timeout(15)), error = function(e) NULL)
  if (is.null(res) || httr::status_code(res) != 200) return(NA_character_)
  parsed <- tryCatch(jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8")),
                     error = function(e) NULL)
  if (is.null(parsed) || is.null(parsed$features) || nrow(parsed$features$attributes) == 0) {
    return(NA_character_)
  }
  parsed$features$attributes$huc12[1]
}

# Process in chunks of 500, saving after each chunk
chunk_size <- 500
n_chunks <- ceiling(nrow(todo) / chunk_size)
results_list <- if (nrow(cached) > 0) list(cached) else list()

for (i in seq_len(n_chunks)) {
  start_idx <- (i - 1) * chunk_size + 1
  end_idx <- min(i * chunk_size, nrow(todo))
  chunk <- todo[start_idx:end_idx]

  cat("Chunk", i, "/", n_chunks, "(", nrow(chunk), "facilities)...")

  huc12_vals <- character(nrow(chunk))
  for (j in seq_len(nrow(chunk))) {
    huc12_vals[j] <- lookup_huc12(chunk$lat[j], chunk$lon[j])
    if (j %% 50 == 0) cat(".")
    Sys.sleep(0.35)  # Rate limit
  }

  chunk_result <- data.table(
    NPDES_ID = chunk$NPDES_ID,
    huc12 = huc12_vals
  )
  results_list[[length(results_list) + 1]] <- chunk_result

  # Save checkpoint
  all_results <- rbindlist(results_list, fill = TRUE)
  saveRDS(all_results, cache_file)

  n_found <- sum(!is.na(huc12_vals))
  cat(" done (", n_found, "/", nrow(chunk), "found)\n")
}

all_results <- rbindlist(results_list, fill = TRUE)
cat("\nTotal HUC-12 assignments:", sum(!is.na(all_results$huc12)), "/", nrow(all_results), "\n")
saveRDS(all_results, cache_file)
cat("Saved facility_huc12.rds\n")
