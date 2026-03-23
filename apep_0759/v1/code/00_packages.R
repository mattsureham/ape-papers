## 00_packages.R — Load required packages
## apep_0759: Simplified to Compete

pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite", "httr2",
  "modelsummary", "kableExtra", "lubridate"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
