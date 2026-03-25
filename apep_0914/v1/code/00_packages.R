# =============================================================================
# 00_packages.R — Load required packages
# Paper: AAA Cotton Displacement and Black Occupational Scarring
# =============================================================================

required <- c("data.table", "fixest", "duckdb", "DBI", "jsonlite", "sandwich", "lmtest")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Source Azure helper
source("../../../../scripts/lib/azure_data.R")

cat("All packages loaded.\n")
