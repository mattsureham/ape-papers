## 00_packages.R — Load required packages for apep_0963
## TFP Revision and Food Security

required_packages <- c(
  "tidyverse",     # Data manipulation
  "fixest",        # Fixed effects estimation
  "tidycensus",    # ACS data via Census API
  "httr",          # HTTP requests for Census CPS API
  "jsonlite",      # JSON parsing
  "data.table",    # Fast data operations
  "modelsummary",  # Regression tables
  "kableExtra",    # Table formatting
  "sandwich",      # Robust standard errors
  "fwildclusterboot", # Wild cluster bootstrap
  "haven"          # Read SAS/SPSS/Stata files
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded successfully.\n")
