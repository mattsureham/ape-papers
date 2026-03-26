# =============================================================================
# 00_packages.R — Load required libraries
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",      # Azure/Parquet data access
  "data.table", "jsonlite",       # Data manipulation
  "fixest",                        # Fast FE estimation (TWFE, Sun-Abraham)
  "did",                           # Callaway-Sant'Anna
  "HonestDiD",                     # Rambachan-Roth sensitivity
  "xtable",                        # LaTeX table generation
  "httr", "curl"                   # API data fetching
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
