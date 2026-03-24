## 00_packages.R — Load required packages
## apep_0868: Grid Isolation and the Economic Costs of Infrastructure Failure

pkgs <- c(
  "data.table", "fixest", "jsonlite", "httr", "ggplot2",
  "sandwich", "lmtest", "did", "HonestDiD", "fwildclusterboot",
  "readr", "tidyr", "dplyr", "stringr", "purrr", "modelsummary",
  "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
