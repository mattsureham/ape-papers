## 01_fetch_data.R — Fetch Eurostat crop production data
## apep_0668: The Pollinator Penalty

source("code/00_packages.R")

cat("=== Fetching Eurostat crop production data ===\n")

# ------------------------------------------------------------------
# 1. Fetch apro_cpsh1: Crop production in EU standard humidity
#    Columns: freq, crops, strucpro, geo, TIME_PERIOD, values
#    strucpro: AR (area), YI_HU_EU (yield), PR_HU_EU (production)
# ------------------------------------------------------------------

raw <- get_eurostat("apro_cpsh1", time_format = "num")

if (is.null(raw) || nrow(raw) == 0) {
  stop("FATAL: Eurostat apro_cpsh1 returned no data. Cannot proceed without real data.")
}

cat(sprintf("Raw data: %d rows, %d columns\n", nrow(raw), ncol(raw)))
cat(sprintf("Years: %s to %s\n",
            min(raw$TIME_PERIOD, na.rm = TRUE),
            max(raw$TIME_PERIOD, na.rm = TRUE)))
cat(sprintf("Countries: %d unique geo codes\n", n_distinct(raw$geo)))
cat(sprintf("Crops: %d unique crop codes\n", n_distinct(raw$crops)))

# ------------------------------------------------------------------
# 2. Extract yield and area
# ------------------------------------------------------------------

yield_raw <- raw |>
  filter(strucpro == "YI_HU_EU") |>
  select(geo, crops, TIME_PERIOD, values) |>
  rename(
    country = geo,
    crop_code = crops,
    year = TIME_PERIOD,
    yield = values
  )

area_raw <- raw |>
  filter(strucpro == "AR") |>
  select(geo, crops, TIME_PERIOD, values) |>
  rename(
    country = geo,
    crop_code = crops,
    year = TIME_PERIOD,
    area_ha = values
  )

cat(sprintf("\nYield observations: %d\n", nrow(yield_raw)))
cat(sprintf("Area observations: %d\n", nrow(area_raw)))

# ------------------------------------------------------------------
# 3. Merge yield and area
# ------------------------------------------------------------------

crop_data <- yield_raw |>
  left_join(area_raw, by = c("country", "crop_code", "year"))

cat(sprintf("Merged dataset: %d rows\n", nrow(crop_data)))

# ------------------------------------------------------------------
# 4. Save raw fetched data
# ------------------------------------------------------------------

saveRDS(crop_data, "data/crop_data_raw.rds")
cat("Saved data/crop_data_raw.rds\n")

# Quick summary
cat("\n=== Coverage summary ===\n")
cat(sprintf("Countries: %d\n", n_distinct(crop_data$country)))
cat(sprintf("Crops: %d\n", n_distinct(crop_data$crop_code)))
cat(sprintf("Years: %s - %s\n",
            min(crop_data$year, na.rm = TRUE),
            max(crop_data$year, na.rm = TRUE)))
