# 00_packages.R — Load required packages for NHTSA defect queue analysis
# apep_1192

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # IV/2SLS with clustered SEs
  "ggplot2",       # Plotting
  "lubridate",     # Date handling
  "jsonlite",      # JSON I/O
  "httr",          # HTTP requests for NHTSA API
  "readr",         # CSV reading
  "stringr",       # String manipulation
  "sandwich",      # Robust SEs
  "lmtest",        # Coefficient testing
  "modelsummary",  # Table output
  "kableExtra"     # LaTeX tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
