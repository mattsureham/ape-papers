## 00_packages.R — Load required packages
## apep_0686: UK Housing Delivery Test RDD

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "readODS",      # Read ODS files (HDT data)
  "readxl",       # Read Excel files (2018-2019 HDT data)
  "rdrobust",     # RDD estimation (Cattaneo et al.)
  "rddensity",    # McCrary density test
  "fixest",       # Fixed effects regression
  "modelsummary", # Table formatting
  "kableExtra",   # Table formatting
  "xtable",       # LaTeX table output
  "jsonlite",     # JSON output for diagnostics
  "httr"          # HTTP downloads
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
