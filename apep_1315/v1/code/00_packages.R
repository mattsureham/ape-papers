## 00_packages.R — Load and install required packages
## apep_1315: The Forever Chemical Discount

required <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "readr", "httr", "MatchIt", "modelsummary",
  "kableExtra", "did", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
