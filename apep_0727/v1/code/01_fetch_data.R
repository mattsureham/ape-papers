## 01_fetch_data.R — Load and validate OPSD solar data
## Data already fetched via Python from OPSD (Open Power System Data)
## Source: https://data.open-power-system-data.org/renewable_power_plants/2020-08-25/

source("00_packages.R")

cat("Loading solar installation data...\n")
dt <- fread("../data/solar_installations.csv")

# Validate data integrity
stopifnot("capacity_kwp" %in% names(dt))
stopifnot("year" %in% names(dt))
stopifnot(nrow(dt) > 100000)  # Must have substantial data
stopifnot(all(dt$capacity_kwp > 0, na.rm = TRUE))

cat(sprintf("Loaded %s records, years %d-%d\n",
            format(nrow(dt), big.mark = ","),
            min(dt$year, na.rm = TRUE),
            max(dt$year, na.rm = TRUE)))

# Save raw data summary
summary_stats <- list(
  n_total = nrow(dt),
  n_solar = nrow(dt),
  year_min = min(dt$year, na.rm = TRUE),
  year_max = max(dt$year, na.rm = TRUE),
  capacity_mean = mean(dt$capacity_kwp, na.rm = TRUE),
  capacity_median = median(dt$capacity_kwp, na.rm = TRUE),
  data_source = "OPSD Renewable Power Plants Germany (2020-08-25)"
)
write_json(summary_stats, "../data/raw_summary.json", auto_unbox = TRUE)
cat("Raw data summary saved.\n")
