# ==============================================================================
# 00_packages.R — Load required packages
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",       # Azure/parquet data access
  "data.table", "tidyverse",      # Data manipulation
  "fixest",                        # IV estimation (feols with | x ~ z syntax)
  "modelsummary",                  # Regression tables
  "kableExtra",                    # Table formatting
  "jsonlite"                       # diagnostics.json output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
