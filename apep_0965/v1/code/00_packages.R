# =============================================================================
# 00_packages.R — Load required packages
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

pkgs <- c(
  "data.table", "duckdb", "DBI", "fixest", "ggplot2",
  "modelsummary", "kableExtra", "jsonlite", "HonestDiD"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

message("All packages loaded.")
