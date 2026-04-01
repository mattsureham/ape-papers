# =============================================================================
# 00_packages.R — Load required packages for apep_1237
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "data.table", "DBI", "duckdb",
  "modelsummary", "kableExtra", "jsonlite", "broom"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Source Azure data library
source("../../../../scripts/lib/azure_data.R")

message("All packages loaded successfully.")
