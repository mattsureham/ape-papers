# =============================================================================
# 00_packages.R — Load required packages
# =============================================================================

required_pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "DBI", "duckdb",
  "jsonlite", "xtable", "modelsummary"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
