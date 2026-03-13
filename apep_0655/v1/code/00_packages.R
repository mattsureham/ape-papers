## 00_packages.R — Load required libraries
## apep_0655: The Employer Side of Deportation

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "duckdb",
  "lubridate", "jsonlite", "modelsummary", "kableExtra",
  "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
