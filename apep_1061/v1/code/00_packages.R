# 00_packages.R — Install and load required packages
# apep_1061: Polish abortion ruling border-distance DiD

required_packages <- c(
  "eurostat",     # Eurostat data API
  "data.table",   # Fast data manipulation
  "fixest",       # Fast fixed effects estimation
  "ggplot2",      # Plotting (not used in V1 but needed for diagnostics)
  "sf",           # Spatial operations
  "geodist",      # Geodesic distances
  "jsonlite",     # JSON output
  "dplyr",        # Data wrangling
  "tidyr",        # Reshaping
  "stringr",      # String operations
  "httr",         # HTTP requests for API calls
  "fwildclusterboot", # Wild cluster bootstrap
  "HonestDiD",    # Sensitivity to pre-trends violations
  "did",          # Callaway-Sant'Anna (for robustness)
  "modelsummary", # Table output
  "kableExtra"    # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
