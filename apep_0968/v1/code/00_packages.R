# ==============================================================================
# 00_packages.R — Load required libraries
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

required_packages <- c(
  "tidyverse",      # Data wrangling + ggplot2
  "fixest",         # Fast fixed effects (feols)
  "readxl",         # Read USDA ERS Excel files
  "httr",           # API calls
  "jsonlite",       # JSON parsing
  "data.table",     # Fast data operations
  "sandwich",       # Robust standard errors
  "lmtest",         # Coefficient tests
  # "fwildclusterboot", # Wild cluster bootstrap (use fixest::boottest instead)
  "modelsummary",   # Regression tables
  "kableExtra",     # LaTeX table formatting
  "zoo"             # Rolling window functions
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
