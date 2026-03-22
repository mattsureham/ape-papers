## =============================================================================
## 00_packages.R — Install and load required packages
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

required_packages <- c(
  "tidyverse",     # Data manipulation and visualization

"fixest",        # Fixed effects regressions with clustered SEs
  "rdrobust",      # Regression discontinuity estimation
  "rddensity",     # McCrary-style density tests
  "httr",          # HTTP requests for API
  "jsonlite",      # JSON parsing
  "data.table",    # Fast data manipulation
  "xtable",        # LaTeX table generation
  "modelsummary",  # Regression tables
  "kableExtra",    # Table formatting
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
