# =============================================================================
# 00_packages.R — Load required packages for FPM-RDD analysis
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

required_packages <- c(
  "tidyverse",     # Data wrangling and visualization
  "fixest",        # Fixed effects estimation
  "rdrobust",      # RDD estimation (Cattaneo et al.)
  "rddensity",     # McCrary-style density test
  "httr",          # HTTP requests for APIs
  "jsonlite",      # JSON parsing
  "haven",         # Read .dta files
  "readxl",        # Read Excel files
  "xtable",        # LaTeX table generation
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient testing
  "MASS"           # Negative binomial regression
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Check for microdatasus (DATASUS data)
if (!requireNamespace("microdatasus", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes", repos = "https://cran.r-project.org")
  }
  remotes::install_github("rfsaldanha/microdatasus")
}
library(microdatasus)

cat("All packages loaded successfully.\n")
