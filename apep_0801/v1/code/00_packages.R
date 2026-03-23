# 00_packages.R — Load and install required packages
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

required <- c(
  "tidyverse", "fixest", "data.table", "httr", "jsonlite",
  "readr", "haven", "purrr", "broom", "kableExtra",
  "synthdid", "modelsummary"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
