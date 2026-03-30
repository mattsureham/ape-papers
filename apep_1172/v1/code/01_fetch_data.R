## 01_fetch_data.R — Fetch USDA NASS + BLS data
## apep_1172: Cage-Free Egg Mandates

source("00_packages.R")

# ============================================================
# USDA NASS QuickStats API — monthly egg production by state
# ============================================================

nass_key <- Sys.getenv("USDA_NASS_API_KEY")
stopifnot("USDA_NASS_API_KEY not set" = nchar(nass_key) > 0)

cat("Fetching USDA NASS data...\n")

fetch_nass <- function(commodity, key, extra_params = list()) {
  base_url <- "https://quickstats.nass.usda.gov/api/api_GET/"
  params <- c(list(
    key = key, source_desc = "SURVEY", sector_desc = "ANIMALS & PRODUCTS",
    group_desc = "POULTRY", commodity_desc = commodity,
    freq_desc = "MONTHLY", agg_level_desc = "STATE",
    year__GE = "2010", format = "JSON"
  ), extra_params)
  resp <- GET(base_url, query = params)
  if (status_code(resp) != 200) stop("NASS API returned status ", status_code(resp))
  parsed <- fromJSON(content(resp, as = "text", encoding = "UTF-8"), flatten = TRUE)
  if (is.null(parsed$data) || length(parsed$data) == 0) stop("No data for ", commodity)
  df <- as.data.frame(parsed$data)
  cat("  Fetched", nrow(df), "rows for", commodity, "\n")
  return(df)
}

month_map <- c(
  "JAN" = 1, "FEB" = 2, "MAR" = 3, "APR" = 4,
  "MAY" = 5, "JUN" = 6, "JUL" = 7, "AUG" = 8,
  "SEP" = 9, "OCT" = 10, "NOV" = 11, "DEC" = 12
)

# --- 1. Egg production (EGGS commodity) ---
eggs_raw <- fetch_nass("EGGS", nass_key)

eggs_df <- eggs_raw %>%
  mutate(
    value_clean = as.numeric(gsub(",", "", Value)),
    year = as.integer(year),
    month = month_map[reference_period_desc],
    variable = case_when(
      grepl("EGGS - PRODUCTION, MEASURED IN EGGS", short_desc) ~ "production_eggs",
      grepl("EGGS, TABLE - PRODUCTION, MEASURED IN EGGS", short_desc) ~ "table_production",
      grepl("EGGS, HATCHING - PRODUCTION, MEASURED IN EGGS", short_desc) ~ "hatching_production",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(month), !is.na(variable), !is.na(value_clean)) %>%
  mutate(date = as.Date(paste(year, month, "01", sep = "-"))) %>%
  select(state = state_alpha, state_name, year, month, date, variable, value = value_clean) %>%
  group_by(state, state_name, year, month, date, variable) %>%
  summarise(value = first(value), .groups = "drop")

# --- 2. Layers (fetch specific short_desc values to avoid 413) ---
cat("  Fetching layers inventory...\n")
layers_inv_raw <- fetch_nass("CHICKENS", nass_key,
  extra_params = list(
    short_desc = "CHICKENS, LAYERS - INVENTORY, AVG, MEASURED IN HEAD"
  ))

cat("  Fetching rate of lay...\n")
layers_rate_raw <- fetch_nass("CHICKENS", nass_key,
  extra_params = list(
    short_desc = "CHICKENS, LAYERS - RATE OF LAY, MEASURED IN EGGS / 100 LAYER"
  ))

chickens_raw <- bind_rows(layers_inv_raw, layers_rate_raw)

chickens_df <- chickens_raw %>%
  mutate(
    value_clean = as.numeric(gsub(",", "", Value)),
    year = as.integer(year),
    month = month_map[reference_period_desc],
    variable = case_when(
      grepl("CHICKENS, LAYERS - INVENTORY, AVG", short_desc) ~ "avg_layers",
      grepl("CHICKENS, LAYERS - RATE OF LAY", short_desc) ~ "eggs_per_100",
      grepl("CHICKENS, LAYERS, TABLE - INVENTORY", short_desc) ~ "table_layers",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(month), !is.na(variable), !is.na(value_clean)) %>%
  mutate(date = as.Date(paste(year, month, "01", sep = "-"))) %>%
  select(state = state_alpha, state_name, year, month, date, variable, value = value_clean) %>%
  group_by(state, state_name, year, month, date, variable) %>%
  summarise(value = first(value), .groups = "drop")

# Combine eggs + chickens and pivot wide
combined <- bind_rows(eggs_df, chickens_df) %>%
  pivot_wider(names_from = variable, values_from = value)

cat("\nCombined panel dimensions:", nrow(combined), "state-months\n")
cat("States:", n_distinct(combined$state), "\n")
cat("Columns:", paste(names(combined), collapse = ", "), "\n")

# Rename for clarity (layers in head, production in eggs)
layers_panel <- combined %>%
  rename(
    avg_layers_k = avg_layers  # actually in head; we'll convert to thousands
  ) %>%
  mutate(avg_layers_k = avg_layers_k / 1000)  # Convert to thousands

cat("Date range:", as.character(min(combined$date)), "to", as.character(max(combined$date)), "\n")

stopifnot("No production data fetched" = nrow(layers_panel) > 0)
stopifnot("Fewer than 20 states" = n_distinct(layers_panel$state) >= 20)

# ============================================================
# BLS — Average egg price per dozen (v1 API, no key needed)
# ============================================================

cat("\nFetching BLS egg price data...\n")

egg_series <- c(
  "US" = "APU0000708111",
  "Northeast" = "APU0100708111",
  "Midwest" = "APU0200708111",
  "South" = "APU0300708111"
)
# West (APU0400708111) unavailable in BLS

fetch_bls_v1 <- function(series_id, series_name, start_year, end_year) {
  api_url <- paste0(
    "https://api.bls.gov/publicAPI/v1/timeseries/data/",
    series_id, "?startyear=", start_year, "&endyear=", end_year
  )
  resp <- GET(api_url)
  if (status_code(resp) != 200) { warning("BLS status ", status_code(resp)); return(NULL) }
  parsed <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  if (parsed$status != "REQUEST_SUCCEEDED") { warning("BLS failed: ", parsed$message); return(NULL) }
  series_data <- parsed$Results$series$data
  if (is.null(series_data) || length(series_data) == 0) return(NULL)
  df <- series_data[[1]]
  if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(NULL)
  df %>%
    filter(grepl("^M\\d{2}$", period)) %>%
    mutate(
      year = as.integer(year), month = as.integer(gsub("M", "", period)),
      price = suppressWarnings(as.numeric(value)),
      region = series_name,
      date = as.Date(paste(year, month, "01", sep = "-"))
    ) %>%
    filter(!is.na(price)) %>%
    select(region, year, month, date, price)
}

all_bls <- list()
for (nm in names(egg_series)) {
  cat("  Fetching", nm, "...\n")
  chunk1 <- fetch_bls_v1(egg_series[nm], nm, 2010, 2019)
  Sys.sleep(1)
  chunk2 <- fetch_bls_v1(egg_series[nm], nm, 2020, 2025)
  Sys.sleep(1)
  all_bls[[nm]] <- bind_rows(chunk1, chunk2)
  cat("    ", nm, ":", nrow(all_bls[[nm]]), "rows\n")
}

bls_prices <- bind_rows(all_bls)
cat("BLS price panel:", nrow(bls_prices), "region-months\n")

stopifnot("No BLS price data" = nrow(bls_prices) > 0)

# ============================================================
# Save raw data
# ============================================================

saveRDS(layers_panel, "../data/nass_egg_panel.rds")
saveRDS(bls_prices, "../data/bls_egg_prices.rds")
write_csv(layers_panel, "../data/nass_egg_panel.csv")
write_csv(bls_prices, "../data/bls_egg_prices.csv")

cat("\n=== Data fetch complete ===\n")
cat("NASS panel:", nrow(layers_panel), "state-months,", n_distinct(layers_panel$state), "states\n")
cat("BLS prices:", nrow(bls_prices), "region-months\n")

# Quick check: show CA layers
ca_layers <- layers_panel %>%
  filter(state == "CA", year >= 2021) %>%
  select(date, avg_layers_k, production_eggs) %>%
  arrange(date)
cat("\nCA recent data:\n")
print(ca_layers, n = 20)
