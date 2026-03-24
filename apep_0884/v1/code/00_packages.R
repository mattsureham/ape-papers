## 00_packages.R — Install and load required packages
## APEP-0884: The World's Highest Minimum Wage

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation (feols, sunab)
  "data.table",   # Fast data wrangling
  "httr",         # HTTP requests for BFS PXWeb API
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX table output
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient testing
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
