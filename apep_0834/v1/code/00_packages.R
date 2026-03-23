## 00_packages.R — Install and load required packages
required <- c(
  "tidyverse", "sf", "xml2", "rdrobust", "rddensity",
  "fixest", "modelsummary", "kableExtra", "jsonlite",
  "httr", "archive"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
