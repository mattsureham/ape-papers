## 00_packages.R — Load required packages
## apep_0810: Florida Liquor License Lottery and Business Formation

required_packages <- c(
  "tidyverse",    # Data manipulation + visualization
  "fixest",       # Fast fixed effects estimation
  "httr",         # HTTP requests for Census API
  "jsonlite",     # JSON parsing
  "pdftools",     # PDF text extraction for DBPR lottery data
  "kableExtra",   # Table formatting
  "modelsummary", # Regression tables
  "sandwich",     # Robust standard errors
  "lmtest"        # Hypothesis testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
