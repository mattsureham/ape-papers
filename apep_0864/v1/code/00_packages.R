## 00_packages.R — Install and load required packages
## apep_0864: Revealed Hostility — MEI Referendum and Foreign Sorting

required <- c(
  "tidyverse", "fixest", "data.table", "jsonlite", "httr2",
  "rdrobust", "rddensity", "modelsummary", "kableExtra",
  "sandwich", "lmtest", "HonestDiD", "xtable"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
