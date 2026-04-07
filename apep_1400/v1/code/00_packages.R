# =============================================================================
# 00_packages.R — Load required libraries
# =============================================================================

required_packages <- c(
  "tidyverse", "fixest", "did", "duckdb", "arrow",
  "ggplot2", "patchwork", "latex2exp", "kableExtra",
  "jsonlite", "scales", "viridis"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
