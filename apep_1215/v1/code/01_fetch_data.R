# 01_fetch_data.R — Fetch Eurostat data for apep_1215
# Data sources:
#   1. lfst_r_lfu3rt — Regional unemployment rates (NUTS2), quarterly
#   2. lfst_r_lfe2emprt — Regional employment rates (NUTS2), annual
#   3. rail_pa_quartal — Rail passenger-km, quarterly (national)

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# --- 1. Regional unemployment rates (quarterly, NUTS2) ---
cat("Fetching lfst_r_lfu3rt (regional unemployment rates)...\n")
unemp_raw <- get_eurostat("lfst_r_lfu3rt", time_format = "date")

if (is.null(unemp_raw) || nrow(unemp_raw) == 0) {
  stop("FATAL: Failed to fetch lfst_r_lfu3rt from Eurostat. Cannot proceed.")
}

# Filter to Germany, total sex, ages 15-74 (broad labor force)
unemp_de <- unemp_raw %>%
  filter(
    str_starts(geo, "DE"),
    sex == "T",
    age == "Y15-74",
    isced11 == "TOTAL" | isced11 == "TOTAL" # total education level
  ) %>%
  select(geo, time = TIME_PERIOD, unemp_rate = values)

# Keep only NUTS2 (4-character codes like DE11, DE12, etc.)
unemp_de <- unemp_de %>%
  filter(nchar(geo) == 4)

cat(sprintf("  Unemployment: %d obs, %d regions, %s to %s\n",
            nrow(unemp_de),
            n_distinct(unemp_de$geo),
            min(unemp_de$time),
            max(unemp_de$time)))

stopifnot("No German NUTS2 unemployment data" = nrow(unemp_de) > 100)

# --- 2. Regional employment rates (annual, NUTS2) ---
cat("Fetching lfst_r_lfe2emprt (regional employment rates)...\n")
emp_raw <- get_eurostat("lfst_r_lfe2emprt", time_format = "date")

if (is.null(emp_raw) || nrow(emp_raw) == 0) {
  stop("FATAL: Failed to fetch lfst_r_lfe2emprt from Eurostat. Cannot proceed.")
}

emp_de <- emp_raw %>%
  filter(
    str_starts(geo, "DE"),
    sex == "T",
    age == "Y15-64"
  ) %>%
  select(geo, time = TIME_PERIOD, emp_rate = values)

emp_de <- emp_de %>%
  filter(nchar(geo) == 4)

cat(sprintf("  Employment: %d obs, %d regions, %s to %s\n",
            nrow(emp_de),
            n_distinct(emp_de$geo),
            min(emp_de$time),
            max(emp_de$time)))

stopifnot("No German NUTS2 employment data" = nrow(emp_de) > 50)

# --- 3. Rail passenger statistics (quarterly, national) ---
cat("Fetching rail_pa_quartal (rail passengers)...\n")
rail_raw <- get_eurostat("rail_pa_quartal", time_format = "date")

if (is.null(rail_raw) || nrow(rail_raw) == 0) {
  warning("Could not fetch rail_pa_quartal — will proceed without ridership data.")
  rail_de <- data.frame()
} else {
  rail_de <- rail_raw %>%
    filter(
      geo == "DE",
      unit == "MIO_PKM"  # million passenger-km
    ) %>%
    select(geo, time = TIME_PERIOD, rail_pkm = values)

  cat(sprintf("  Rail: %d obs, %s to %s\n",
              nrow(rail_de),
              min(rail_de$time),
              max(rail_de$time)))
}

# --- Save raw data ---
cat("Saving data to data/ ...\n")
saveRDS(unemp_de, "../data/unemp_nuts2.rds")
saveRDS(emp_de, "../data/emp_nuts2.rds")
saveRDS(rail_de, "../data/rail_national.rds")

cat("=== Data fetch complete ===\n")
cat(sprintf("Unemployment: %d obs across %d NUTS2 regions\n",
            nrow(unemp_de), n_distinct(unemp_de$geo)))
cat(sprintf("Employment: %d obs across %d NUTS2 regions\n",
            nrow(emp_de), n_distinct(emp_de$geo)))
cat(sprintf("Rail: %d obs\n", nrow(rail_de)))
