## 00_packages.R — Install and load required packages
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "fixest",       # Fixed effects regression
  "rdrobust",     # RDD estimation (CCT bandwidth, local polynomial)
  "rddensity",    # Density discontinuity test (Cattaneo-Jansson-Ma)
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
