# =============================================================================
# 00_packages.R — Load required packages
# apep_0643: PFL Border County Pairs
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "data.table", "DBI", "duckdb",
  "modelsummary", "kableExtra", "jsonlite", "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
