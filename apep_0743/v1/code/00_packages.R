# 00_packages.R — Load required packages
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

required_packages <- c(
  "tidyverse",
  "fixest",
  "httr",
  "jsonlite",
  "readr",
  "modelsummary",
  "kableExtra",
  "sandwich",
  "lmtest"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
