## 00_packages.R — Install and load required packages
## APEP paper apep_0627: Wales 20mph Speed Limit

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects estimation
  "data.table",   # fast data reading
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite"      # JSON output for diagnostics
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
