# =============================================================================
# 00_packages.R — Load all required packages
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna estimator
  "duckdb",       # DuckDB for Azure Parquet access
  "DBI",          # Database interface
  "arrow",        # Parquet reading
  "modelsummary", # Regression tables
  "kableExtra",   # LaTeX table formatting
  "HonestDiD",    # Rambachan-Roth sensitivity analysis
  "bacondecomp",  # Goodman-Bacon decomposition
  "sandwich",     # Clustered standard errors
  "lmtest",       # Hypothesis testing
  "jsonlite"      # Write diagnostics.json
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
