## 00_packages.R — Load and verify required packages
## Paper: Does the Clock Kill? (apep_0732)

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects
  "data.table",   # efficient data manipulation
  "rdrobust",     # RDD estimation
  "rddensity",   # McCrary manipulation test
  "sf",           # spatial operations
  "tigris",       # Census TIGER shapefiles
  "tidycensus",   # ACS data
  "jsonlite",     # diagnostics output
  "httr2",        # API calls
  "sandwich",     # robust standard errors
  "lmtest",       # hypothesis testing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
