# =============================================================================
# 00_packages.R — Install and load required packages
# =============================================================================

required <- c(
  "duckdb", "arrow", "data.table", "fixest", "did",
  "ggplot2", "modelsummary", "kableExtra", "jsonlite",
  "sf", "tigris", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
