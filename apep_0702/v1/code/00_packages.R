### 00_packages.R
### Kenya Interest Rate Cap and FinTech Substitution
### apep_0702

# Core packages
required_packages <- c(
  "tidyverse",
  "fixest",
  "did",
  "haven",
  "jsonlite",
  "xtable",
  "kableExtra",
  "scales",
  "lubridate",
  "purrr",
  "httr",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "modelsummary",
  "sandwich",
  "lmtest",
  "boot",
  "broom"
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

cat("All packages loaded successfully.\n")
