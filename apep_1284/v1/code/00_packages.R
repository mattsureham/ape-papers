# 00_packages.R — Load required libraries
# APEP-1284: BLM Lottery Leases and Western County Economies

required_pkgs <- c(
  "data.table", "httr", "jsonlite",     # Data fetching + manipulation
  "fixest", "ivreg", "sandwich",         # Estimation
  "modelsummary", "kableExtra",          # Tables
  "ggplot2", "scales",                   # Plotting (for diagnostics only)
  "dplyr", "tidyr", "stringr", "purrr"  # Data wrangling
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
