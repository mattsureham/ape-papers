# 00_packages.R — Load required packages for Medicare Advantage Star Rating RDD
# apep_1448

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fixed effects regressions
  "rdrobust",     # RDD estimation (Cattaneo et al.)
  "rddensity",    # McCrary density test
  "readxl",       # Read Excel files
  "httr",         # HTTP requests
  "jsonlite",     # JSON handling
  "haven",        # Read Stata/SAS files
  "xtable",       # LaTeX tables
  "kableExtra"    # Better tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
