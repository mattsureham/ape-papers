## 00_packages.R — Install and load required packages

pkgs <- c(
  "duckdb", "DBI", "dplyr", "tidyr", "readr", "stringr",
  "fixest", "modelsummary", "kableExtra",
  "sandwich", "lmtest", "ggplot2"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
