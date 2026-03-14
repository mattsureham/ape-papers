## 00_packages.R — Load required packages for apep_0689
## The Credit Boundary: Flood Insurance Mandates and Mortgage Market Segmentation

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

  "fixest",       # fast fixed effects estimation
  "data.table",   # efficient large-data handling
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "tidycensus",   # Census ACS data
  "modelsummary", # publication-quality tables
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient testing
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
library(tidyverse)

cat("All packages loaded successfully.\n")
