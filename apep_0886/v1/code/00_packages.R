# =============================================================================
# 00_packages.R — Package Installation and Loading
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast fixed effects (feols, sunab)
  "did",          # Callaway-Sant'Anna
  "data.table",   # Memory-efficient operations
  "arrow",        # Parquet I/O
  "duckdb",       # Azure data access
  "DBI",          # Database interface
  "jsonlite",     # JSON output for diagnostics
  "kableExtra",   # Table formatting
  "modelsummary", # Regression tables
  "HonestDiD"     # Rambachan-Roth sensitivity
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded successfully.\n")
