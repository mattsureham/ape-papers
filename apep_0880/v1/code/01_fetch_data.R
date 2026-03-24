## 01_fetch_data.R — Fetch UN Comtrade bilateral trade data for CRMA minerals
## APEP paper apep_0880
## Data source: UN Comtrade Public Preview API (comtradeapi.un.org)
## Strategy: fetch EU-aggregate (reporter=97) first; if unavailable, use Germany (276)

source("00_packages.R")

cat("=== Fetching UN Comtrade Data for CRMA Minerals ===\n")

# ---------------------------------------------------------------
# HS codes for CRMA strategic minerals + control commodities
# ---------------------------------------------------------------
minerals <- tribble(
  ~hs_code, ~mineral,        ~crma_status, ~china_dep,
  "280530", "Rare earths",   "strategic",  TRUE,
  "283691", "Lithium carb.", "strategic",  FALSE,
  "261000", "Chromium",      "strategic",  FALSE,
  "250410", "Graphite",      "strategic",  TRUE,
  "750110", "Nickel mattes", "strategic",  FALSE,
  "260200", "Manganese",     "strategic",  FALSE,
  "260500", "Cobalt ores",   "strategic",  FALSE,
  "810411", "Magnesium",     "strategic",  TRUE,
  "261100", "Tungsten",      "strategic",  TRUE,
  "261400", "Titanium",      "strategic",  FALSE,
  "261510", "Zirconium",     "strategic",  FALSE,
  "280450", "Boron",         "strategic",  FALSE,
  "281110", "Fluorspar/HF",  "strategic",  TRUE,
  "260900", "Tin ores",      "strategic",  FALSE,
  "810210", "Molybdenum",    "strategic",  FALSE,
  "811220", "Beryllium",     "strategic",  FALSE,
  "260300", "Copper ores",   "control",    FALSE,
  "260111", "Iron ore",      "control",    FALSE,
  "151190", "Palm oil",      "control",    FALSE,
  "090111", "Coffee",        "control",    FALSE
)

years <- 2018:2024

# ---------------------------------------------------------------
# Comtrade Public Preview API — single reporter per call
# ---------------------------------------------------------------
fetch_comtrade <- function(reporter, yr, hs_code) {
  # NOTE: omit partnerCode to get all bilateral flows (partnerCode=0 = world agg only)
  url <- sprintf(
    "https://comtradeapi.un.org/public/v1/preview/C/A/HS?reporterCode=%d&period=%d&cmdCode=%s&flowCode=M",
    reporter, yr, hs_code
  )
  resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    raw <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
    if (!is.null(parsed) && !is.null(parsed$data) && is.data.frame(parsed$data) && nrow(parsed$data) > 0) {
      return(as_tibble(parsed$data))
    }
  }
  return(NULL)
}

# ---------------------------------------------------------------
# Fetch: try Germany (276) as primary reporter (largest EU importer)
# ---------------------------------------------------------------
all_data <- list()

for (i in seq_len(nrow(minerals))) {
  hs <- minerals$hs_code[i]
  mineral_name <- minerals$mineral[i]
  cat(sprintf("[%d/%d] %s (HS %s): ", i, nrow(minerals), mineral_name, hs))

  mineral_records <- 0
  for (yr in years) {
    df <- fetch_comtrade(276, yr, hs)  # Germany

    if (is.null(df) || nrow(df) == 0) {
      # Try France as backup
      df <- fetch_comtrade(250, yr, hs)
    }

    if (!is.null(df) && nrow(df) > 0) {
      df$hs_code <- hs
      df$mineral <- mineral_name
      all_data[[length(all_data) + 1]] <- df
      mineral_records <- mineral_records + nrow(df)
    }

    Sys.sleep(0.8)
  }
  cat(sprintf("%d records\n", mineral_records))
}

total <- sum(sapply(all_data, nrow))
cat(sprintf("\n=== Total records: %d ===\n", total))

if (total < 50) {
  stop("FATAL: Could not fetch sufficient Comtrade data. Cannot proceed.")
}

df_raw <- bind_rows(all_data)
cat(sprintf("Combined data frame: %d rows, %d cols\n", nrow(df_raw), ncol(df_raw)))
cat("Columns:", paste(names(df_raw), collapse = ", "), "\n")

saveRDS(df_raw, "../data/comtrade_raw.rds")
saveRDS(minerals, "../data/mineral_metadata.rds")
cat("Saved to data/comtrade_raw.rds and mineral_metadata.rds\n")
cat("=== Data fetch complete ===\n")
