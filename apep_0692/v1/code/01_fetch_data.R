# =============================================================================
# 01_fetch_data.R — Fetch QWI data from LEHD and county adjacency
# =============================================================================

source("00_packages.R")

# ── 1. E-Verify mandate states and dates ─────────────────────────────────────
everify_states <- data.table(
  state_fips = c(4L, 49L, 28L, 22L, 1L, 13L, 37L, 47L, 45L, 12L),
  state_abbr = c("AZ", "UT", "MS", "LA", "AL", "GA", "NC", "TN", "SC", "FL"),
  mandate_date = as.Date(c(
    "2008-01-01", "2010-07-01", "2011-07-01", "2011-08-01",
    "2012-04-01", "2012-07-01", "2013-10-01", "2017-01-01",
    "2021-01-01", "2023-07-01"
  ))
)
everify_states[, mandate_year := year(mandate_date)]
everify_states[, mandate_quarter := quarter(mandate_date)]
everify_states[, mandate_yq := mandate_year + (mandate_quarter - 1) / 4]
saveRDS(everify_states, "../data/everify_states.rds")

# ── 2. Download QWI rh county-NAICS data from LEHD ──────────────────────────
cat("Downloading QWI rh data from LEHD...\n")

state_codes <- c(
  "al", "ak", "az", "ar", "ca", "co", "ct", "de", "dc", "fl",
  "ga", "hi", "id", "il", "in", "ia", "ks", "ky", "la", "me",
  "md", "ma", "mi", "mn", "ms", "mo", "mt", "ne", "nv", "nh",
  "nj", "nm", "ny", "nc", "nd", "oh", "ok", "or", "pa", "ri",
  "sc", "sd", "tn", "tx", "ut", "vt", "va", "wa", "wv", "wi", "wy"
)

base_url <- "https://lehd.ces.census.gov/data/qwi/latest_release"
raw_dir <- "../data/raw_qwi"
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

all_qwi <- list()

for (st in state_codes) {
  fname <- paste0("qwi_", st, "_rh_f_gc_ns_op_u.csv.gz")
  url <- file.path(base_url, st, fname)
  local_file <- file.path(raw_dir, fname)

  if (!file.exists(local_file)) {
    cat("  Downloading", st, "...\n")
    tryCatch({
      download.file(url, local_file, quiet = TRUE)
    }, error = function(e) {
      cat("    -> FAILED:", e$message, "\n")
    })
  } else {
    cat("  Already have", st, "\n")
  }

  if (file.exists(local_file)) {
    tryCatch({
      df <- fread(cmd = paste("gzip -dc", local_file), select = c(
        "geography", "industry", "ethnicity", "race",
        "year", "quarter", "Emp", "EmpEnd", "HirA", "Sep", "EarnS", "EmpS"
      ))
      # Filter: race=A0 (all races), ethnicity A1 or A2, year >= 2004
      df <- df[race == "A0" & ethnicity %in% c("A1", "A2") & year >= 2004]
      if (nrow(df) > 0) {
        all_qwi[[st]] <- df
        cat("    ->", format(nrow(df), big.mark = ","), "rows\n")
      }
    }, error = function(e) {
      cat("    -> Parse error:", e$message, "\n")
    })
  }
}

qwi_dt <- rbindlist(all_qwi, fill = TRUE)
cat("\nTotal QWI rows:", format(nrow(qwi_dt), big.mark = ","), "\n")
cat("Unique counties:", length(unique(qwi_dt$geography)), "\n")
cat("Year range:", range(qwi_dt$year), "\n")
cat("Ethnicity distribution:\n")
print(table(qwi_dt$ethnicity))

stopifnot("No QWI data" = nrow(qwi_dt) > 100000)
saveRDS(qwi_dt, "../data/qwi_rh_ns.rds")

# ── 3. Get county adjacency data ─────────────────────────────────────────────
cat("\nFetching county adjacency file...\n")
adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency/county_adjacency2024.txt"
adj_file <- "../data/county_adjacency.txt"
download.file(adj_url, adj_file, quiet = TRUE)
stopifnot(file.exists(adj_file))

adj_raw <- readLines(adj_file)
stopifnot(length(adj_raw) > 100)

adj_records <- list()
current_fips <- NULL

for (line in adj_raw) {
  fields <- strsplit(line, "\t")[[1]]
  if (length(fields) >= 4 && nchar(trimws(fields[2])) > 0) {
    current_fips <- trimws(fields[2])
    neighbor_fips <- trimws(fields[4])
  } else if (length(fields) >= 2) {
    neighbor_fips <- trimws(fields[length(fields)])
  } else {
    next
  }
  if (!is.null(current_fips) && nchar(neighbor_fips) == 5) {
    adj_records[[length(adj_records) + 1]] <- data.table(
      fips = current_fips,
      neighbor_fips = neighbor_fips
    )
  }
}

county_adj <- rbindlist(adj_records)
county_adj <- county_adj[fips != neighbor_fips]
cat("County adjacency pairs:", format(nrow(county_adj), big.mark = ","), "\n")
saveRDS(county_adj, "../data/county_adjacency.rds")

cat("\nAll data fetched successfully.\n")
