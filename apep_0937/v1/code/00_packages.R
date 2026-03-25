# 00_packages.R — Install and load required packages
# apep_0937: Grenfell fire and fire safety industry formation

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fast fixed effects estimation
  "ggplot2",       # Figures (not used in V1, but for diagnostics)
  "jsonlite",      # JSON output for diagnostics
  "httr",          # HTTP requests
  "readr",         # CSV parsing
  "stringr",       # String manipulation
  "lubridate",     # Date handling
  "sandwich",      # Robust standard errors
  "modelsummary",  # Table output
  "kableExtra",    # LaTeX table formatting
  "haven"          # Data import
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
