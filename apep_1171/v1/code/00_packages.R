## 00_packages.R — Install and load required packages
## apep_1164: The Formalization Dividend

pkgs <- c(
  "data.table", "fixest", "ggplot2", "haven", "readr", "dplyr", "tidyr",
  "stringr", "lubridate", "jsonlite", "curl", "httr", "purrr",
  "fwildclusterboot", "did", "kableExtra", "modelsummary", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
