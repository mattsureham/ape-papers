# =============================================================================
# 00_packages.R — Load required packages
# APEP Working Paper apep_0800
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Memory-efficient data ops
  "duckdb",       # Azure Parquet access
  "DBI",          # Database interface
  "arrow",        # Parquet I/O
  "jsonlite",     # JSON output for diagnostics
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "fwildclusterboot", # Wild cluster bootstrap
  "HonestDiD"     # Sensitivity analysis
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
