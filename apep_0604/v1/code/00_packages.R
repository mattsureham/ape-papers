# 00_packages.R — Load and install required packages
# APEP-0604: Colombia FARC Peace and Education

required_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast FE estimation
  "did",          # Callaway-Sant'Anna
  "HonestDiD",    # sensitivity analysis for pre-trends
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readr",        # fast CSV reading
  "sf",           # spatial data (optional)
  "kableExtra",   # nice tables
  "modelsummary", # regression tables
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
