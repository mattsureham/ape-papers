## 00_packages.R — Install and load required packages
## apep_0793: The Innovation Supply Chain

pkgs <- c(
  "tidyverse", "fixest", "DBI", "duckdb", "arrow",
  "modelsummary", "kableExtra", "jsonlite", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
