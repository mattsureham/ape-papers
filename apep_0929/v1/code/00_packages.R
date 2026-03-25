# 00_packages.R — Install and load required packages

required_packages <- c(
  "readxl", "httr", "dplyr", "tidyr", "stringr", "ggplot2",
  "fixest", "did", "modelsummary", "kableExtra", "jsonlite",
  "purrr", "readr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
