# ==============================================================================
# 00_packages.R — Install and load required packages
# ==============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",          # Azure/data access
  "data.table", "dplyr", "tidyr",    # Data manipulation
  "fixest", "did",                    # DiD estimation
  "ggplot2",                          # Plotting (for diagnostics only)
  "readxl", "httr",                   # Data fetching
  "jsonlite",                         # Diagnostics output
  "HonestDiD",                        # Sensitivity analysis
  "modelsummary",                     # Table formatting
  "kableExtra",                       # LaTeX table output
  "stringr"                           # String manipulation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
