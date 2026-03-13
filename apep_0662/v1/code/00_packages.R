## 00_packages.R — Install and load required packages
## apep_0662: Clean Slate Laws and Statistical Discrimination

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects (Sun-Abraham, TWFE)
  "did",          # Callaway-Sant'Anna
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "HonestDiD",    # sensitivity analysis for pre-trends
  "data.table"    # memory-efficient ops
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validation
library(fixest)
library(did)
library(dplyr)
library(data.table)

cat("All packages loaded.\n")
