## 00_packages.R — Load and install required packages
## apep_1165: Swiss Municipal Mergers and Functional Spending

required_pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "readxl",
  "httr", "jsonlite", "haven", "xtable", "kableExtra",
  "HonestDiD", "sandwich", "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
