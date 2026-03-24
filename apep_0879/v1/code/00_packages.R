# =============================================================================
# 00_packages.R — Load and install required packages
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

required <- c(
  "tidyverse", "fixest", "did", "data.table", "arrow", "duckdb",
  "jsonlite", "broom", "HonestDiD", "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
