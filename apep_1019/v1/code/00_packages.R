# =============================================================================
# 00_packages.R — Load required packages
# =============================================================================

required_packages <- c(
  "arrow",       # Read Parquet files
  "data.table",  # Fast data manipulation
  "fixest",      # Fast fixed effects (sunab, feols)
  "did",         # Callaway-Sant'Anna estimator
  "dplyr",       # Data wrangling
  "tidyr",       # Reshaping
  "jsonlite",    # Write diagnostics
  "xtable"       # LaTeX tables (backup)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
