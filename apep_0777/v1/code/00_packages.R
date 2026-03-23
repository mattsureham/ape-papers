# 00_packages.R — Package loading for SNAP-Medicaid paper
# apep_0777

required_packages <- c(
  "tidyverse",
  "fixest",
  "did",
  "httr2",
  "jsonlite",
  "lubridate",
  "modelsummary",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
