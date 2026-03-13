# 00_packages.R — Load required packages for RDD analysis
# apep_0613: Female mayors and fiscal composition in Mexico

required_packages <- c(
  "tidyverse",     # Data manipulation and visualization
  "rdrobust",      # Local polynomial RDD estimation (Cattaneo et al.)
  "rddensity",     # McCrary density test for manipulation
  "modelsummary",  # Regression tables
  "jsonlite",      # JSON for diagnostics
  "kableExtra"     # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
