# =============================================================================
# 00_packages.R — Film Tax Credits and Racial Employment
# =============================================================================

required_packages <- c(
  "tidyverse",    # Data wrangling
  "fixest",       # Fast fixed effects (TWFE, Sun-Abraham)
  "did",          # Callaway-Sant'Anna
  "duckdb",       # Azure Parquet queries
  "DBI",          # Database interface
  "data.table",   # Fast data manipulation
  "xtable",       # LaTeX table generation
  "jsonlite"      # diagnostics.json
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
