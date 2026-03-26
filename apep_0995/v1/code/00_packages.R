## 00_packages.R — Install and load required packages
## apep_0986: Forced EPCI Mergers and RN Voting

required <- c(
  "data.table", "tidyverse", "fixest", "did",
  "httr", "jsonlite", "readxl", "haven",
  "modelsummary", "kableExtra", "sandwich"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
