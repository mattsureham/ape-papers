## 00_packages.R — Install and load required packages
## apep_0803: The Pill Pipeline

required_pkgs <- c(
  "data.table", "fixest", "modelsummary", "kableExtra",
  "ggplot2", "readr", "readxl", "httr", "jsonlite",
  "stringr", "dplyr", "tidyr", "haven", "rvest",
  "sandwich", "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
