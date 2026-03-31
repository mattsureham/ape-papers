## 00_packages.R — Install and load required packages
## apep_1220: Ecuador Disability Quota RDD

required_pkgs <- c(
  "tidyverse",     # Data manipulation and visualization
  "fixest",        # Fixed effects estimation
  "rdrobust",      # RDD estimation (CCT bandwidth, robust CIs)
  "rddensity",     # McCrary density test
  "haven",         # Read SPSS/Stata files
  "httr",          # HTTP requests for data download
  "jsonlite",      # JSON parsing
  "rvest",         # Web scraping for INEC catalog
  "data.table",    # Memory-efficient data manipulation
  "kableExtra",    # Table formatting
  "modelsummary",  # Regression tables
  "sandwich",      # Heteroskedasticity-robust SEs
  "xtable"         # LaTeX table export
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
