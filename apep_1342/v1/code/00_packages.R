# 00_packages.R — Package installation and loading for apep_1342
# UK FCA HCSTC Price Cap: Supply-Side Destruction

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "survival",     # Survival analysis (Cox PH, Kaplan-Meier)
  "httr",         # HTTP requests for API access
  "jsonlite",     # JSON parsing
  "readxl",       # Excel file reading (PSD006)
  "lubridate",    # Date handling
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "zoo"           # Time series utilities (yearqtr)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
