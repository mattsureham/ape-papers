# =============================================================================
# 00_packages.R — Load required packages
# =============================================================================

required_packages <- c(
  "tidyverse",   # Data wrangling + ggplot2
  "fixest",      # High-dimensional FE regressions
  "did",         # Callaway-Sant'Anna staggered DiD
  "data.table",  # Fast data manipulation
  "duckdb",      # Azure/Parquet access
  "DBI",         # Database interface
  "modelsummary",# Regression tables
  "kableExtra",  # Table formatting
  "jsonlite",    # JSON output for diagnostics
  "fwildclusterboot" # Wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
