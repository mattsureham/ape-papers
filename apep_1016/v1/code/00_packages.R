## 00_packages.R — Install and load required packages
## apep_1016: Fresh Start Dividend

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects IV/2SLS estimation
  "httr",         # API requests
  "jsonlite",     # JSON parsing
  "data.table",   # Fast data operations
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "lmtest"        # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
