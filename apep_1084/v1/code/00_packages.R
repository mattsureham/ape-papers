# =============================================================================
# 00_packages.R — Load required libraries
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

required_packages <- c(
  "tidyverse",
  "fixest",
  "duckdb",
  "arrow",
  "data.table",
  "modelsummary",
  "kableExtra",
  "jsonlite",
  "httr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
