# =============================================================================
# 00_packages.R — One Fair Wage and the Racial Earnings Gap
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "did", "data.table", "arrow",
  "duckdb", "DBI", "jsonlite", "sandwich", "lmtest",
  "fwildclusterboot", "xtable", "modelsummary", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
