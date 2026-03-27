# 00_packages.R — Load required libraries
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

required_packages <- c(
  "tidyverse",
  "fixest",
  "eurostat",
  "jsonlite",
  "xtable",
  "sandwich",
  "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
