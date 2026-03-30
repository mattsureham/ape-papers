# 00_packages.R — Load required packages for hospital bed bunching analysis
# APEP-1150

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "ggplot2",       # Plotting (for internal QA only — V1 has no figures)
  "stringr",       # String manipulation
  "jsonlite",      # JSON output for diagnostics
  "xtable",        # LaTeX table generation
  "curl",          # HTTP downloads
  "readr"          # CSV parsing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
