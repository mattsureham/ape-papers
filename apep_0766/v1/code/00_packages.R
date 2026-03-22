## 00_packages.R — Install and load required packages
## apep_0766: Council size thresholds and infant mortality in Brazil

required_packages <- c(
  "tidyverse",     # Data wrangling + visualization
  "data.table",    # Fast data processing
  "rdrobust",      # RDD estimation (Cattaneo et al.)
  "rddensity",     # McCrary manipulation test
  "rdlocrand",     # Local randomization RDD
  "fixest",        # Fixed effects estimation
  "modelsummary",  # LaTeX tables
  "kableExtra",    # Table formatting
  "jsonlite",      # JSON output for diagnostics
  "httr",          # HTTP requests for API data
  "rvest",         # Web scraping fallback
  "arrow"          # Parquet/CSV reading
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
