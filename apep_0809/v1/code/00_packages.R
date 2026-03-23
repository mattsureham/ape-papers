## 00_packages.R — Install and load required packages
## apep_0809: Trading Non-Tradable Votes

pkgs <- c(
  "tidyverse", "fixest", "readxl", "httr2", "jsonlite",
  "haven", "data.table", "arrow", "modelsummary", "kableExtra",
  "sandwich", "lmtest", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
