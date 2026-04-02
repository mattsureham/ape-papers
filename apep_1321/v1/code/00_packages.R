# 00_packages.R — Install and load required packages
# Ghana Microfinance Purge: VIIRS nighttime lights + dose-response DiD

required_packages <- c(
  "tidyverse",    # Data manipulation
  "fixest",       # Fast fixed effects estimation
  "data.table",   # Efficient data handling
  "sf",           # Spatial data
  "terra",        # Raster processing
  "geodata",      # GADM boundaries
  "exactextractr",# Zonal statistics
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "lubridate",    # Date handling
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "lmtest",       # Hypothesis testing
  "rvest"         # Web scraping for BoG data
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
