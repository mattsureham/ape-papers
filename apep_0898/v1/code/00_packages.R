## 00_packages.R — Load required packages for apep_0898
## Grocery exit cascades: anchor store hypothesis

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects and IV estimation
  "did",          # Callaway-Sant'Anna DiD estimator
  "data.table",   # Efficient data operations
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient testing
  "modelsummary", # Table generation
  "kableExtra"    # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
