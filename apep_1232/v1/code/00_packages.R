## 00_packages.R — Install and load required packages
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes

required <- c(
  "tidyverse", "fixest", "did", "data.table", "readr",
  "xtable", "jsonlite", "HonestDiD", "knitr", "haven"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
