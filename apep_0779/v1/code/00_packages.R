# =============================================================================
# 00_packages.R — Load required packages for apep_0779
# =============================================================================

required_packages <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna estimator
  "duckdb",       # Azure/Parquet access
  "DBI",          # database interface
  "jsonlite",     # JSON I/O for diagnostics
  "arrow",        # Parquet read/write
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
