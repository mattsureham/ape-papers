# 00_packages.R — Package installation and loading for SEC Chair Transitions paper
# apep_0760

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "rdrobust",     # RD estimation
  "rvest",        # Web scraping
  "httr2",        # HTTP requests
  "jsonlite",     # JSON parsing
  "sandwich",     # HAC standard errors
  "lmtest",       # Coefficient testing
  "xtable",       # LaTeX table output
  "modelsummary", # Publication-quality tables
  "lubridate"     # Date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
