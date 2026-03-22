# 00_packages.R — Load and install required packages
# apep_0756: Fair Workweek, Unfair Turnover?

required <- c(
  "tidyverse", "fixest", "did", "duckdb", "DBI",
  "modelsummary", "kableExtra", "jsonlite", "arrow"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
