# 00_packages.R — Install and load required packages
# apep_1161: The Compliance Upgrade

required_packages <- c(
  "tidyverse",    # Data wrangling and visualization
  "fixest",       # Fast FE estimation
  "did",          # Callaway-Sant'Anna DiD
  "data.table",   # Memory-efficient data processing
  "xtable",       # LaTeX table generation
  "jsonlite",     # JSON diagnostics output
  "sandwich"      # Robust standard errors
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
