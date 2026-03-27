# ==============================================================================
# 00_packages.R — Install and load required packages
# apep_1058: The Networked Bank Run
# ==============================================================================

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fixed effects OLS with clustered SEs
  "data.table",   # fast data operations
  "jsonlite",     # JSON output for diagnostics
  "duckdb",       # Azure/Parquet data access
  "DBI",          # database interface
  "httr",         # HTTP API calls
  "xtable",       # LaTeX table generation
  "knitr",        # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
