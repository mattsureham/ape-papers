# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

pkgs <- c(
  "duckdb", "arrow", "data.table", "fixest", "did",
  "ggplot2", "dplyr", "tidyr", "stringr", "readr",
  "jsonlite", "sandwich", "lmtest",
  "kableExtra", "xtable", "modelsummary"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")
