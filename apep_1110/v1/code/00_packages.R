# 00_packages.R — Install and load required packages
# APEP paper apep_1110: UK Sugar Tax and Childhood Dental Extractions

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols)
  "ggplot2",       # Plotting (not used in V1 but needed for diagnostics)
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "readr",         # CSV reading
  "dplyr",         # Data manipulation
  "tidyr",         # Reshaping
  "stringr",       # String operations
  "sandwich",      # Robust SEs
  "lmtest",        # Coefficient testing
  "modelsummary",  # Table generation
  "kableExtra"     # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
