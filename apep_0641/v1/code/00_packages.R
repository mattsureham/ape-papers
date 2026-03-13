## 00_packages.R — Install and load required packages
## apep_0641: Salary History Bans and Pay Compression

pkgs <- c(
  "tidyverse", "data.table", "arrow", "duckdb",
  "fixest", "did", "bacondecomp", "modelsummary",
  "kableExtra", "jsonlite", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
