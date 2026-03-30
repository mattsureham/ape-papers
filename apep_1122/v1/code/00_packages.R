# =============================================================================
# 00_packages.R — Load and verify required packages
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data manipulation + visualization
  "fixest",       # High-dimensional fixed effects
  "data.table",   # Memory-efficient operations
  "duckdb",       # Azure Parquet access
  "DBI",          # Database interface
  "jsonlite",     # JSON output
  "fredr"         # FRED API access
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
