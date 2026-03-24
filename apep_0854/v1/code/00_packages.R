# 00_packages.R — Install and load required packages

required <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "readr", "stringr",
  "fixest", "rdrobust", "rddensity", "ggplot2",
  "modelsummary", "kableExtra", "scales"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
