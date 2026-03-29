# 00_packages.R — Load and install required packages
# APEP Working Paper apep_1111: FEMA Risk Rating 2.0 and Residential Construction

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "data.table",   # Fast data processing
  "readxl",       # Read Excel files
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "HonestDiD",    # Sensitivity analysis for parallel trends
  "modelsummary", # Table formatting
  "kableExtra",   # LaTeX table formatting
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
