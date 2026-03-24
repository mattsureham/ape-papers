# 00_packages.R — Load required libraries
# apep_0860: Catalytic Converter Anti-Theft Laws and Scrap Metal Dealers

required_packages <- c(
  "tidyverse",   # Data manipulation and visualization
  "fixest",      # Fixed effects estimation
  "did",         # Callaway-Sant'Anna DiD
  "modelsummary",# Regression tables
  "kableExtra",  # Table formatting
  "jsonlite",    # JSON output for diagnostics
  "xtable"       # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
