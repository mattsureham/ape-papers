# 00_packages.R — Load required libraries
# APEP-0869: The Litigation Tax on Biometrics

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast fixed-effects estimation
  "data.table",   # Fast data manipulation
  "httr",         # HTTP requests for BLS API
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient tests
  "fwildclusterboot",  # Wild cluster bootstrap
  "modelsummary", # Table formatting
  "kableExtra"    # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
