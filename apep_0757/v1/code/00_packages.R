# ============================================================
# 00_packages.R — Install and load required packages
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

required_packages <- c(
  "tidyverse", "fixest", "did", "data.table", "duckdb",
  "httr", "jsonlite", "lubridate", "xtable", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
