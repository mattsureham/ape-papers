# =============================================================================
# 00_packages.R — Package installation and loading
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "did", "duckdb", "arrow",
  "modelsummary", "kableExtra", "jsonlite", "fwildclusterboot",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
