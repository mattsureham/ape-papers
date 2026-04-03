# 00_packages.R — Install and load required packages
# apep_1344: The Potency Arms Race

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "arrow",        # Read Parquet files from Azure
  "AzureStor",    # Azure Blob Storage access
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "jsonlite",     # Write diagnostics.json
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient tests
  "broom",        # Tidy model outputs
  "scales"        # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
