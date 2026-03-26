# 00_packages.R — Load required libraries
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast fixed-effects estimation
  "data.table",   # Fast data manipulation
  "httr",         # HTTP requests for BLS/Census API
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient tests
  # "fwildclusterboot",  # Wild cluster bootstrap — not available for R 4.5; using RI instead
  "modelsummary", # Table formatting
  "kableExtra",   # LaTeX table output
  "readxl",       # Excel reading (for OES data)
  "sf",           # Spatial features (for map figure)
  "tigris"        # Census TIGER/Line shapefiles
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Set data.table threads
setDTthreads(0)

cat("All packages loaded successfully.\n")
