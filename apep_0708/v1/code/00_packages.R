# ==============================================================================
# 00_packages.R — Install and load required packages
# ==============================================================================

required <- c(
  "duckdb", "DBI", "data.table", "fixest", "modelsummary",
  "xtable", "jsonlite", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
