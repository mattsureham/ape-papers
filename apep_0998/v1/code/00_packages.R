# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "data.table", "duckdb", "arrow",
  "jsonlite", "httr", "xtable", "kableExtra", "sandwich",
  "lmtest", "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
