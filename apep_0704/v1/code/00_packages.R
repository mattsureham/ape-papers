## 00_packages.R — Load required packages for apep_0704
## OSHA Inspections and Worker Reallocation

required_pkgs <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "data.table",   # Efficient data operations
  "DBI",          # Database interface
  "duckdb",       # Azure parquet queries
  "httr",         # HTTP requests for OSHA API
  "jsonlite",     # JSON parsing
  "modelsummary", # Publication-quality tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "boot"             # Bootstrap methods
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
