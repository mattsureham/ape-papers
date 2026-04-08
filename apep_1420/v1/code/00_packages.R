# 00_packages.R — Load required packages
# APEP-1420: The Coding Dividend

required <- c(
  "tidyverse", "fixest", "data.table", "httr", "jsonlite",
  "xtable", "modelsummary", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
