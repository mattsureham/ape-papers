# 00_packages.R — Load required packages
# apep_0896: Does the Right to Repair Create Repairers?

required_packages <- c(
  "tidyverse",
  "fixest",
  "did",
  "httr",
  "jsonlite",
  "data.table",
  "modelsummary",
  "HonestDiD",
  "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
