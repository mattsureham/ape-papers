# 00_packages.R — Ecuador Pension RDD
# Required packages for RDD analysis of ENEMDU microdata

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
 "data.table",   # fast data operations
  "rdrobust",     # CCT bandwidth, local polynomial RDD
  "rddensity",    # McCrary manipulation test
  "fixest",       # fixed effects (for robustness)
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics output
  "httr",         # HTTP requests for data download
  "haven",        # read Stata/SPSS files
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
