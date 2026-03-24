## 00_packages.R — Install and load required packages
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

"fixest",       # high-dimensional fixed effects
  "httr",         # HTTP requests for BFS PXWeb API
  "jsonlite",     # JSON parsing
  "sandwich",     # robust standard errors
  "lmtest",       # coefficient testing
  "boot",              # bootstrap inference
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

cat("All packages loaded successfully.\n")
