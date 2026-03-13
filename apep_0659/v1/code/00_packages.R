# ==============================================================================
# 00_packages.R — Package dependencies for apep_0659
# The Enclave as Insurance and Trap
# ==============================================================================

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "duckdb",       # Azure/DuckDB data access
  "DBI",          # Database interface
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "jsonlite",     # JSON output for diagnostics
  "data.table"    # Memory-efficient operations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
