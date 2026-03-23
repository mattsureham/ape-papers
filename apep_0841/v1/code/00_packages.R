## 00_packages.R — Install and load required packages
## apep_0841: Poland 500+ and Female Labor Supply

required_pkgs <- c(
  "eurostat",      # Eurostat data API
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, sunab)
  "modelsummary",  # Table formatting
  "ggplot2",       # Plotting (for diagnostics only)
  "jsonlite",      # Write diagnostics.json
  "dplyr",         # Data manipulation
  "tidyr",         # Reshaping
  "stringr",       # String operations
  "kableExtra",    # LaTeX table formatting
  "sandwich"         # Robust covariance estimators
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
