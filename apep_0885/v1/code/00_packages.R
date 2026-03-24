## 00_packages.R — Install and load required packages
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

required_packages <- c(
  "tidyverse", "data.table", "fixest", "did", "httr", "jsonlite",
  "modelsummary", "kableExtra", "xtable", "sandwich", "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
