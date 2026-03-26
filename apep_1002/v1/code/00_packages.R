# 00_packages.R — Load and install required packages
# apep_1002: Czech EET Abolition and Formalization Hysteresis

required_packages <- c(
  "tidyverse",     # data wrangling + ggplot2

"fixest",        # fast fixed effects estimation
  "eurostat",      # Eurostat data access
  "httr",          # HTTP requests (backup API access)
  "jsonlite",      # JSON parsing
  "sandwich",      # robust SEs
  "lmtest",        # coefficient testing
  "boot",             # bootstrap methods
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  "xtable"         # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
