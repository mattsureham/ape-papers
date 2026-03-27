# 00_packages.R — Install and load required packages
# apep_1077: Child Labor Law Rollbacks DDD

required <- c(
  "duckdb", "DBI", "data.table", "fixest", "did",
  "modelsummary", "kableExtra", "sandwich", "lmtest",
  "jsonlite"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
