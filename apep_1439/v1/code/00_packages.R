## 00_packages.R — Install and load required packages
## apep_1439: The Switching Paradox

pkgs <- c(
  "tidyverse", "fixest", "gtrendsR", "readxl", "httr", "jsonlite",
  "lubridate", "modelsummary", "kableExtra", "sandwich", "lmtest",
  "dplyr", "data.table"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
