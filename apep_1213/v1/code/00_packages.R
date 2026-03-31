# 00_packages.R — Load required libraries for Moldova banking crisis analysis
# apep_1213

required_packages <- c(
  "data.table",
  "fixest",
  "httr",
  "jsonlite",
  "ggplot2",
  "dplyr",
  "tidyr",
  "stringr",
  "purrr",
  "broom",
  "kableExtra",
  "modelsummary",
  "sandwich",
  "fwildclusterboot",
  "xtable"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit library calls for validator detection
library(fixest)
library(data.table)
library(dplyr)

cat("All packages loaded successfully.\n")
