## 00_packages.R — Load required libraries for apep_1163
## The Disclosure Cliff: CMS Open Payments Bunching Analysis

required_packages <- c(
  "tidyverse",    # Data wrangling + ggplot2
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "fixest",       # Fast regression (etable for tables)
  "data.table",   # Memory-efficient large data
  "xtable",       # LaTeX table output
  "scales"        # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
