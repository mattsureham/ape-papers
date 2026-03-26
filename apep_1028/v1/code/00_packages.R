## 00_packages.R — Install and load required packages
## apep_1028: Right-to-Counsel and Community-Level Homelessness

required <- c(
  "tidyverse", "fixest", "did", "data.table", "httr2", "jsonlite",
  "readxl", "xtable", "modelsummary", "kableExtra", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
