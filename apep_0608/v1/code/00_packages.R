## 00_packages.R — Install and load required packages
## apep_0608: Japan Women's Participation Disclosure RDD

required_pkgs <- c(
  "tidyverse", "fixest", "rdrobust", "rddensity",
  "modelsummary", "kableExtra", "jsonlite", "httr2",
  "readr", "haven", "broom", "sandwich", "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
