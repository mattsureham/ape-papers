# 01_fetch_data.R — Data already fetched via Python (00_fetch_data.py)
# This script validates the fetched data and performs initial checks.

source("00_packages.R")

# Read the panel data fetched by Python
df <- read.csv("../data/nbs_housing_panel.csv", stringsAsFactors = FALSE)

cat("Panel dimensions:", nrow(df), "x", ncol(df), "\n")
cat("Unique cities:", length(unique(df$city_en)), "\n")
cat("Date range:", min(df$date), "to", max(df$date), "\n")
cat("Treated cities:", sum(df$treated == 1) / length(unique(df$date)), "\n")
cat("Control cities:", sum(df$treated == 0) / length(unique(df$date)), "\n")

# Validate: no missing cities
stopifnot(length(unique(df$city_en)) >= 70)

# Validate: no missing treatment indicator
stopifnot(all(df$treated %in% c(0, 1)))

# Validate: data spans pre and post reform
stopifnot(any(df$date < "2021-03-01"))
stopifnot(any(df$date >= "2021-03-01"))

cat("Data validation PASSED.\n")

# Save validated data
saveRDS(df, "../data/nbs_panel_validated.rds")
cat("Saved validated panel to data/nbs_panel_validated.rds\n")
