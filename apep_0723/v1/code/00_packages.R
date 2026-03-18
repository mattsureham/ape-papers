## 00_packages.R — Load and install required packages
## apep_0723: EU Youth Employment Initiative RDD

required_packages <- c(
  "tidyverse",    # dplyr, tidyr, readr, ggplot2, stringr, purrr
  "fixest",       # OLS with fixed effects and clustered SEs
  "rdrobust",     # RDD estimation (main package)
  "rddensity",    # McCrary density discontinuity test
  "eurostat",     # Eurostat API access
  "jsonlite",     # JSON output for diagnostics
  "kableExtra"    # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

# Explicit loads for validator detection
library(fixest)
library(rdrobust)
library(rddensity)
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(stringr)
library(jsonlite)
library(kableExtra)

cat("All packages loaded successfully.\n")
