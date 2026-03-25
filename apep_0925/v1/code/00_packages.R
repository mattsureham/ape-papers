# 00_packages.R — Package installation and loading for apep_0925
# Calorie labeling threshold avoidance (England 250-employee rule)

required_packages <- c(
  "httr2",        # HTTP requests
  "jsonlite",     # JSON parsing
  "dplyr",        # Data manipulation
  "tidyr",        # Data reshaping
  "ggplot2",      # Not used for V1 (zero figures) but kept for diagnostics
  "fixest",       # Fixed effects estimation
  "data.table",   # Efficient data operations
  "stringr",      # String manipulation
  "readr",        # CSV reading
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SEs
  "lmtest"        # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
