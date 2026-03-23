# =============================================================================
# 00_packages.R — Load required packages
# APEP Paper apep_0794: Testing Without Tests
# =============================================================================

required <- c(
  "duckdb", "DBI", "arrow",
  "data.table", "fixest", "modelsummary",
  "ggplot2", "kableExtra", "jsonlite",
  "dplyr", "tidyr", "stringr"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
