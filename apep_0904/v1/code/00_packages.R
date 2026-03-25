# 00_packages.R — Load required packages for apep_0904
# Federal Procurement SAT Bunching Analysis

required_packages <- c(
  "httr",          # API calls to USAspending.gov
  "jsonlite",      # JSON parsing
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects regression (robustness)
  "ggplot2",       # Plots (not used in V1, but for diagnostics)
  "kableExtra",    # Table formatting
  "scales",        # Number formatting
  "boot",          # Bootstrap confidence intervals
  "stats"          # Polynomial fitting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
