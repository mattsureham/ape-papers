## 00_packages.R — Install and load required packages
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

required_packages <- c(
  "tidyverse",
  "fixest",
  "did",
  "data.table",
  "readxl",
  "jsonlite",
  "xtable",
  "HonestDiD",
  "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
