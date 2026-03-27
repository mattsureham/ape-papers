# =============================================================================
# 00_packages.R — Load required packages
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2

  "fixest",       # fast fixed effects (feols)
  "data.table",   # efficient data manipulation
  "duckdb",       # Azure parquet access
  "DBI",          # database interface
  "readxl",       # read DOL Excel files
  "jsonlite",     # write diagnostics.json
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
