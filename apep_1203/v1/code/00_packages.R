## 00_packages.R — Load and install required packages
## apep_1203: Argentina SAS Firm Registration Ban

required <- c(
  "tidyverse", "fixest", "did", "data.table",
  "jsonlite", "httr", "lubridate", "kableExtra",
  "xtable", "sandwich", "lmtest", "modelsummary"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
