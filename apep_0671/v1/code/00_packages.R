# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

required_packages <- c(
  "data.table", "fixest", "duckdb", "DBI", "arrow",
  "ggplot2", "modelsummary", "kableExtra", "jsonlite",
  "broom", "sandwich"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(data.table)
library(fixest)
library(duckdb)
library(DBI)
library(arrow)
library(ggplot2)
library(modelsummary)
library(kableExtra)
library(jsonlite)
library(broom)
library(sandwich)

cat("All packages loaded successfully.\n")
