# 00_packages.R — Load and install required packages
# apep_1336: EPA Enforcement Federalism Production Function

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # High-dimensional fixed effects estimation
  "httr",         # HTTP requests for API calls
  "jsonlite",     # JSON parsing
  "data.table",   # Fast data manipulation
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "rvest"         # Web scraping for FedScope
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
