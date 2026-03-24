# 00_packages.R — Load required packages
# APEP-0889: Slower Mail, Fewer Voters

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "fixest",       # Fast fixed effects (feols, sunab)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Fast CSV reading
  "httr",         # HTTP requests for API data
  "jsonlite",     # JSON parsing
  "readxl",       # Excel reading (for EAVS)
  "HonestDiD",    # Rambachan-Roth sensitivity
  "kableExtra",   # Table formatting
  "modelsummary", # Regression tables
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
