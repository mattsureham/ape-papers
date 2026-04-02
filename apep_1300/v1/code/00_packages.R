# ==============================================================================
# 00_packages.R — Load required packages
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "data.table",   # efficient data operations
  "DBI",          # database interface for DuckDB
  "duckdb",       # Azure Parquet access
  "rvest",        # web scraping (MWPVL)
  "httr",         # HTTP requests
  "jsonlite",     # JSON I/O
  "tidygeocoder", # geocoding FC addresses
  "tigris",       # FIPS county lookup
  "modelsummary", # regression tables
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

options(tigris_use_cache = TRUE)
cat("All packages loaded.\n")
