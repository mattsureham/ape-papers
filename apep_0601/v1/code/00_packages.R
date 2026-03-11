## 00_packages.R — Install and load required packages
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

required <- c(
  "tidyverse",    # data wrangling + ggplot2

"httr2",        # API calls
  "jsonlite",     # JSON parsing
  "readxl",       # Excel files
  "fixest",       # fast fixed effects
  "rdrobust",     # RDD estimation
  "rddensity",    # McCrary density test
  "sandwich",     # robust SEs
  "MASS",         # negative binomial
  "xtable",       # LaTeX tables
  "scales",       # number formatting
  "broom"         # tidy model output
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
