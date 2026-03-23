# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast FE regressions and 2SLS
  "data.table",   # Fast data processing
  "arrow",        # Parquet file reading
  "duckdb",       # Azure blob access via DuckDB
  "bigrquery",    # Google BigQuery access
  "modelsummary", # Table generation
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SEs
  "lmtest",       # Coefficient tests
  "jsonlite",     # JSON output for diagnostics
  "clubSandwich"     # Cluster-robust variance estimation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
