## 00_packages.R — Load and install required packages
## APEP Paper apep_1035: Premarital Education Promotion and Divorce

required <- c(
  "tidyverse", "fixest", "did", "readxl", "httr", "jsonlite",
  "fwildclusterboot", "HonestDiD", "modelsummary", "kableExtra",
  "data.table"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
