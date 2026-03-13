# =============================================================================
# 00_packages.R — Load required packages
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE, event studies, clustered SEs
  "duckdb",       # Azure parquet access
  "DBI",          # database interface
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite"      # diagnostics output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
