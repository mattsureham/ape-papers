## 00_packages.R — Install and load required packages
## Paper: The Rehabilitation Dividend (apep_1103)

required <- c(
  "tidyverse", "fixest", "data.table", "readxl", "httr", "jsonlite",
  "xtable", "modelsummary", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
