## 00_packages.R — Install and load required packages
## apep_1338: Brexit Rules of Origin and Trade Disintegration

required <- c(
  "tidyverse",     # data wrangling + ggplot2 (includes dplyr)
  "fixest",        # fast fixed-effects estimation (feols)
  "data.table",    # efficient data manipulation
  "httr2",         # HTTP requests for Comtrade API
  "jsonlite",      # JSON parsing
  "countrycode",   # ISO code conversions
  "xtable",        # LaTeX table generation
  "sandwich",      # robust standard errors
  "lmtest",        # coefficient tests
  "modelsummary"   # regression tables
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
