## 00_packages.R — Load and install required packages
## apep_1317: Colombia draft lottery and wartime conscription

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # High-dimensional fixed effects
  "data.table",   # Fast data manipulation
  "httr",         # HTTP requests for DANE API
  "jsonlite",     # JSON parsing
  "haven",        # Read Stata/SPSS files
  "readxl",       # Read Excel files
  "xtable",       # LaTeX table output
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient testing
  "boot",             # Bootstrap methods
  "modelsummary"  # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
