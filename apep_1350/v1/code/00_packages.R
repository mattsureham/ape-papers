## 00_packages.R — Load required libraries
## apep_1350: The Segregation Dividend

pkgs <- c(
  "tidyverse", "data.table", "fixest", "did", "DBI", "duckdb",
  "arrow", "jsonlite", "xtable", "modelsummary", "kableExtra"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
