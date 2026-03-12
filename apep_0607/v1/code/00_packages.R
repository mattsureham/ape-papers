# 00_packages.R — Install and load required packages
# APEP Working Paper apep_0607

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "httr",         # HTTP requests for SIDRA API
  "jsonlite",     # JSON parsing
  "readxl",       # Excel file reading (MapBiomas)
  "data.table",   # Fast data manipulation
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "HonestDiD",    # Sensitivity analysis for parallel trends
  "sf"            # Spatial data (for biome crosswalks)
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
