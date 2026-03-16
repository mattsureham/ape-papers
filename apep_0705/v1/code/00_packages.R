## 00_packages.R — Install and load required packages
## APEP-0705: Sweden's RUT Household Services Deduction

required <- c(
  "tidyverse",    # Data manipulation and plotting
  "fixest",       # TWFE and clustered standard errors
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SEs
  "lmtest"        # Coefficient tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
