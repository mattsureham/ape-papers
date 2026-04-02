## ============================================================
## 00_packages.R — Load and install required packages
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
## ============================================================

required_packages <- c(
  "tidyverse",    # Data manipulation + ggplot2
  "fixest",       # Fast fixed-effects estimation
  "data.table",   # Fast data operations
  "httr",         # HTTP requests for API calls
  "jsonlite",     # JSON parsing
  "readr",        # Fast CSV reading
  "lubridate",    # Date manipulation
  "sandwich",     # Robust SEs
  "lmtest",       # Coefficient tests
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "AER"           # IV estimation diagnostics
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
