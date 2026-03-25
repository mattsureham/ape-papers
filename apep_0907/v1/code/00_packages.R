## 00_packages.R — Install and load required packages
## apep_0907: The Digital Door to Food Stamps

required <- c(
  "tidyverse", "fixest", "did", "data.table", "jsonlite",
  "httr", "readxl", "haven", "modelsummary", "kableExtra",
  "HonestDiD", "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
