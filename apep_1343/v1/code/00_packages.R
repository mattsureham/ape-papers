# 00_packages.R — Load required libraries
# apep_1343: Accord vs Alliance factory safety in Bangladesh RMG

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols)
  "rvest",         # Web scraping
  "httr",          # HTTP requests
  "jsonlite",      # JSON parsing
  "readr",         # CSV reading
  "stringr",       # String manipulation
  "lubridate",     # Date handling
  "survival",      # Cox proportional hazard
  "sandwich",      # Robust standard errors
  "xtable",        # LaTeX table output
  "modelsummary",  # Regression tables
  "kableExtra"     # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
