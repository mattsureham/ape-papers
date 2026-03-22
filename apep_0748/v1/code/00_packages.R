## 00_packages.R — Install and load required packages
## apep_0748: GP Practice Closures and A&E Utilization

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation (feols, sunab)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Efficient data operations
  "httr2",        # HTTP requests for NHS APIs
  "jsonlite",     # JSON parsing
  "readxl",       # Read Excel files
  "geosphere",    # Distance calculations (Haversine)
  "HonestDiD",    # Rambachan-Roth sensitivity analysis
  "xtable",       # LaTeX table generation
  "modelsummary"  # Regression tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
