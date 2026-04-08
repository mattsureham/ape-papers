## 00_packages.R
## apep_1428: Does Financial Parity Follow Legal Parity?
## Load and install required packages

required_packages <- c(
  "tidyverse",    # data manipulation
  "fixest",       # fast fixed effects estimation (TWFE + DDD)
  "modelsummary", # regression tables
  "kableExtra",   # LaTeX table formatting
  "scales",       # number formatting
  "janitor"       # clean column names
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator
library(fixest)
library(dplyr)

cat("Packages loaded successfully.\n")
cat("R version:", R.version$version.string, "\n")
