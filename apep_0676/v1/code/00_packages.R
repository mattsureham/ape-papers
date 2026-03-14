## 00_packages.R — Install and load required packages
## apep_0676: UK Charity Bunching at Audit Thresholds

required_packages <- c(

  "tidyverse",    # Data wrangling + ggplot2
  "data.table",   # Fast data processing
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "fixest",       # Fixed effects / clustering
  "boot",         # Bootstrap inference
  "knitr",        # Table output
  "kableExtra",   # LaTeX tables
  "xtable",       # Alternative LaTeX tables
  "scales"        # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
