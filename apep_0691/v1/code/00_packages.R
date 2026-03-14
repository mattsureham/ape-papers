## 00_packages.R — Install and load required packages
## APEP-0691: Sugar Tax Without Sticker Shock

required_packages <- c(
  "httr2",        # API calls to Fingertips
  "jsonlite",     # JSON parsing
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects estimation (feols)
  "ggplot2",      # Plotting (not used in V1 but needed for diagnostics)
  "modelsummary", # Publication-quality tables
  "kableExtra",   # LaTeX table formatting
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
