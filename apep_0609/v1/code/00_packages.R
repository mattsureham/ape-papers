# ==============================================================================
# 00_packages.R — Load and install required packages
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

required_pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "arrow", "duckdb",
  "bacondecomp", "HonestDiD", "jsonlite", "xtable", "knitr"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
