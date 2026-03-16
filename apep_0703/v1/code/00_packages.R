# =============================================================================
# 00_packages.R — Package loading for apep_0703
# Marijuana legalization and labor market firm dynamics
# =============================================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast FE estimation
  "did",          # Callaway-Sant'Anna
  "data.table",   # fast aggregation
  "duckdb",       # Azure Parquet access
  "DBI",          # database interface
  "arrow",        # Parquet read/write
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite"      # diagnostics.json
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
