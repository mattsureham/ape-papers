## 00_packages.R — Install and load required packages
## APEP paper apep_0631: SALT Cap and Reversal

required <- c(
  "tidyverse",     # data manipulation + ggplot2

"fixest",        # fast fixed effects estimation
  "data.table",    # fast data wrangling for large files
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  "jsonlite",      # write diagnostics.json
  "sandwich",      # robust SEs
  "lmtest"         # hypothesis tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
