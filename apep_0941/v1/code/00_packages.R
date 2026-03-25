# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data manipulation + ggplot2
  "fixest",       # Fast fixed effects estimation
  "duckdb",       # DuckDB for Azure IPEDS data
  "DBI",          # Database interface
  "jsonlite",     # Write diagnostics.json
  "modelsummary", # Table formatting
  "kableExtra",   # LaTeX table output
  "sandwich",     # Robust SEs
  "lmtest"        # Hypothesis tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
