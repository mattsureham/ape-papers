# ==============================================================================
# 00_packages.R — Load required packages
# ==============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow", "data.table", "tidyverse",
  "fixest", "modelsummary", "ggplot2", "sf", "patchwork",
  "jsonlite", "scales", "viridis", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")
