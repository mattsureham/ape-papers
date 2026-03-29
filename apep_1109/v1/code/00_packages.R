## 00_packages.R — Install and load required packages
## apep_1109: Crop Insurance and Deaths of Despair

pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite", "httr2",
  "modelsummary", "kableExtra", "sandwich", "lmtest",
  "xtable", "scales"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
