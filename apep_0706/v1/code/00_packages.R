## 00_packages.R — Load required libraries
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates

required_packages <- c(
  "tidyverse",     # data wrangling + ggplot2
  "data.table",    # fast data ops
  "rdrobust",      # RDD estimation (Cattaneo et al.)
  "rddensity",     # McCrary-style density test
  "fixest",        # fixed-effects regressions
  "modelsummary",  # regression tables
  "jsonlite",      # diagnostics output
  "httr",          # API calls
  "kableExtra",    # table formatting
  "scales"         # number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
