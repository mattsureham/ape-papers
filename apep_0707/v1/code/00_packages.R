# 00_packages.R — MEES Bunching at EPC Threshold
# Required packages for bunching estimation

required <- c(
  "data.table",    # Fast data manipulation
  "httr",          # HTTP requests for EPC API
  "jsonlite",      # JSON parsing
  "readODS",       # Read GOV.UK ODS files
  "fixest",        # Regression with FE
  "ggplot2",       # Plotting (for diagnostics only)
  "boot",          # Bootstrap inference
  "xtable",        # LaTeX tables
  "stringr"        # String manipulation
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
