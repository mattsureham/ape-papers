## 00_packages.R — Install and load required packages for apep_1166
## LISA Frozen Property Cap and First-Time Buyer Markets

pkgs <- c(
  "httr2", "jsonlite", "readr", "dplyr", "tidyr", "stringr",
  "data.table", "fixest", "did", "ggplot2",
  "modelsummary", "kableExtra", "broom",
  "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")
