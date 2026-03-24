# =============================================================================
# 00_packages.R — Package dependencies for apep_0848
# =============================================================================

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "duckdb", "DBI",
  "jsonlite", "modelsummary", "kableExtra", "HonestDiD"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

message("All packages loaded successfully.")
