## ==========================================================
## 00_packages.R — Load required packages
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast FE regressions
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "terra",        # raster operations (TP-40 GeoTIFF)
  "sf",           # spatial operations
  "data.table",   # fast data manipulation
  "sandwich",     # robust SEs
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
