# =============================================================================
# 00_packages.R — Load required packages
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",       # Azure / Parquet data access
  "data.table", "dplyr", "tidyr", # Data manipulation
  "fixest",                        # Fixed effects / IV estimation
  "modelsummary",                  # Regression tables
  "ggplot2",                       # Figures (not used in V1, but for diagnostics)
  "jsonlite",                      # diagnostics.json
  "knitr", "kableExtra"           # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
