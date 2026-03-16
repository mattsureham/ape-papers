# 00_packages.R — Install and load required packages
# apep_0709: Markets Under Fire

required_pkgs <- c(
  "tidyverse", "data.table", "fixest", "did", "jsonlite",
  "httr", "sf", "geosphere", "sandwich", "lmtest",
  "modelsummary", "kableExtra"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
