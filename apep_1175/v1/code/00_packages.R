# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

packages <- c(
  "duckdb", "DBI", "data.table", "fixest", "modelsummary",
  "ggplot2", "jsonlite", "tigris", "stringr", "HonestDiD"
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

message("All packages loaded.")
