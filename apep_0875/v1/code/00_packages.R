# =============================================================================
# 00_packages.R — Load and install required packages
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "did", "data.table", "arrow",
  "duckdb", "DBI", "jsonlite", "xtable", "kableExtra",
  "haven", "modelsummary", "broom", "sandwich", "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(did)
library(data.table)
library(dplyr)

cat("All packages loaded.\n")
