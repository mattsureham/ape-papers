## 00_packages.R — Load required libraries
## APEP-1204: Stretched Thin

required_packages <- c(
  "tidyverse", "fixest", "jsonlite", "httr", "lubridate",
  "sandwich", "lmtest", "modelsummary", "kableExtra", "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
