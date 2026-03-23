## 00_packages.R — Install and load required packages
## APEP Working Paper apep_0817

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects regression / IV
  "httr2",        # API requests
  "jsonlite",     # JSON parsing
  "data.table",   # Efficient data ops
  "sandwich",     # Robust SE
  "lmtest",       # Coefficient tests
  "boot",              # Bootstrap inference
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
