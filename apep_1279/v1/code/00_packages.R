# =============================================================================
# 00_packages.R — Load and install required packages
# Paper: The Inertia Break (apep_1279)
# =============================================================================

required_packages <- c(
  "duckdb",      # Azure Parquet access
  "DBI",         # Database interface
  "data.table",  # Memory-efficient data manipulation
  "fixest",      # Fast fixed effects + RD
  "rdrobust",    # Cattaneo RDD
  "rddensity",   # McCrary density test
  "ggplot2",     # Figures
  "modelsummary",# Regression tables
  "kableExtra",  # Table formatting
  "jsonlite",    # Write diagnostics
  "sandwich",    # Robust SEs
  "lmtest"       # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
