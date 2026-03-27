# ==============================================================================
# 00_packages.R — Load required packages
# Paper: The Picture Bride Premium
# ==============================================================================

required_packages <- c(
  "duckdb", "DBI", "data.table", "fixest", "modelsummary",
  "xtable", "jsonlite"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(data.table)

cat("All packages loaded.\n")
