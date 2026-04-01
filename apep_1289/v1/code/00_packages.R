## 00_packages.R — Load and install required packages
## APEP paper apep_1289: Differential Response and Child Maltreatment Measurement

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "readxl",       # Read Excel files
  "httr",         # HTTP requests for data downloads
  "jsonlite",     # JSON parsing
  "rvest",        # Web scraping
  "modelsummary", # Publication-quality tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust standard errors
  "clubSandwich", # Small-sample clustered SEs
  "HonestDiD"     # Sensitivity analysis for PT violations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
