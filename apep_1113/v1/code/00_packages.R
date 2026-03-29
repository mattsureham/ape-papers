# ==============================================================================
# 00_packages.R — Load required packages
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

required_packages <- c(
  "tidyverse",   # Data manipulation and visualization
  "fixest",      # Fixed effects estimation (feols, sunab)
  "duckdb",      # DuckDB interface for IPEDS data
  "DBI",         # Database interface
  "modelsummary",# Regression tables
  "kableExtra",  # Table formatting
  "jsonlite",    # JSON output for diagnostics
  "xtable"       # LaTeX table generation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
