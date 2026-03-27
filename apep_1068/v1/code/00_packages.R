# =============================================================================
# 00_packages.R — Load required libraries
# apep_1068: Last Hired, Not First Fired
# =============================================================================

required_packages <- c(
  "duckdb", "DBI", "data.table", "fixest", "modelsummary",
  "ggplot2", "jsonlite", "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Source Azure data library
source("../../../../scripts/lib/azure_data.R")

cat("All packages loaded.\n")
