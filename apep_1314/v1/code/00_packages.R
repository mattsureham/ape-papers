## 00_packages.R — Load and install required packages
## apep_1314: The Prudential Backlash

pkgs <- c(
  "tidyverse", "data.table", "fixest", "eurostat",
  "httr", "jsonlite", "countrycode", "haven",
  "modelsummary", "kableExtra", "sandwich", "lmtest"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
