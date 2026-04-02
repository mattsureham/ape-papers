## 00_packages.R — Install and load required packages
## APEP Working Paper apep_1323

required_pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "httr", "readxl", "writexl", "haven", "zoo",
  "sandwich", "lmtest", "modelsummary",
  "kableExtra", "xtable"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
