# ==============================================================================
# 00_packages.R — Install and load packages for National Sword analysis
# ==============================================================================

required <- c(
  "tidyverse", "fixest", "data.table", "duckdb", "arrow",
  "did", "jsonlite", "xtable", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")
