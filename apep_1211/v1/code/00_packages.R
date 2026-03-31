# ==============================================================================
# 00_packages.R — Load and install required packages
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",       # Azure / Parquet data access
  "tidyverse", "data.table",       # Data manipulation
  "fixest",                         # Fixed effects regressions
  "did",                            # Callaway-Sant'Anna DiD
  "modelsummary",                   # Table generation
  "kableExtra",                     # Table formatting
  "jsonlite",                       # JSON I/O
  "httr"                            # API calls
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
