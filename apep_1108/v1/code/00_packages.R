## 00_packages.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Install and load required packages

required_pkgs <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "data.table",   # Fast data operations
  "jsonlite",     # JSON output for diagnostics
  "xtable",       # LaTeX table generation
  "kableExtra",   # Table formatting
  "httr",         # HTTP requests
  "lubridate",    # Date handling
  "modelsummary", # Regression tables
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
