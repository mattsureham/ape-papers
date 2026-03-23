# ==============================================================================
# 00_packages.R — Load required libraries for apep_0816
# ==============================================================================

required_packages <- c(
  "duckdb", "arrow", "data.table", "fixest", "modelsummary",
  "kableExtra", "jsonlite", "ggplot2"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
