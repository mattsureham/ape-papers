# 00_packages.R — Load required libraries
# APEP 1456: DPA Enforcement Intensity and Startup Survival

required_packages <- c(
  "tidyverse",    # Data manipulation + ggplot2
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "eurostat",     # Eurostat data access
  "jsonlite",     # Parse enforcement tracker JSON
  "httr",         # HTTP requests
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
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
