# 00_packages.R — Load required packages for ASAN corruption analysis
# Paper: apep_1413

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "haven",        # Read Stata/SPSS files
  "httr",         # HTTP requests for World Bank API
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient tests
  "boot",             # Bootstrap methods
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
