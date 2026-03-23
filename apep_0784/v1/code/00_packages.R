# 00_packages.R — Install and load required packages
# APEP paper apep_0784: OSHA Heat NEP

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols, sunab)
  "ggplot2",       # Plotting (not used in V1, but for diagnostics)
  "dplyr",         # Data wrangling
  "tidyr",         # Data reshaping
  "readr",         # CSV reading
  "stringr",       # String operations
  "jsonlite",      # JSON output for diagnostics
  "httr",          # HTTP requests for API
  "modelsummary",  # Table generation
  "kableExtra"     # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
