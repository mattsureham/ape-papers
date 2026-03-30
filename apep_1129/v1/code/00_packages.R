# ==============================================================================
# 00_packages.R — Package dependencies for apep_1129
# Middlemen and the Opioid Flood
# ==============================================================================

required_packages <- c(
  "duckdb",        # Azure data access via DuckDB
  "DBI",           # Database interface
  "data.table",    # Fast data manipulation
  "fixest",        # IV estimation with high-dimensional FE
  "sandwich",      # Robust variance estimation
  "lmtest",        # Coefficient testing
  "xtable",        # LaTeX table generation
  "jsonlite",      # Write diagnostics.json
  "httr",          # CDC WONDER API access
  "tidycensus",    # ACS data
  "ShiftShareSE",  # AKM-corrected SEs for shift-share
  "binsreg"        # Binscatter plots (not used in V1 but needed for diagnostics)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
