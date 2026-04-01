# ==============================================================================
# 00_packages.R — Load required packages for apep_1253
# ==============================================================================

required <- c(
  "DBI", "duckdb",         # Azure/Parquet queries
  "data.table",            # Fast data manipulation
  "fixest",                # TWFE, Sun-Abraham, clustered SEs
  "ggplot2",               # Plots (event study diagnostics)
  "jsonlite",              # diagnostics.json output
  "httr", "readr",         # SNAP data download
  "stringr",               # String manipulation
  "kableExtra"             # Table formatting (optional)
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
