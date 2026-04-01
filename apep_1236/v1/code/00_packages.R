# 00_packages.R — Load required packages for PFAS housing supply analysis

required_pkgs <- c(
  "tidyverse", "fixest", "httr", "jsonlite", "geosphere",
  "data.table", "modelsummary", "kableExtra", "HonestDiD"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
