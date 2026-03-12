# =============================================================================
# 00_packages.R — Install and load required packages
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data manipulation + visualization
  "data.table",   # Memory-efficient data ops
  "fixest",       # Fast fixed effects (feols, sunab)
  "did",          # Callaway-Sant'Anna
  "DBI",          # Database interface
  "duckdb",       # DuckDB for Azure queries
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "HonestDiD",    # Sensitivity analysis for parallel trends
  "xtable",       # LaTeX table generation
  "modelsummary", # Regression tables
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
