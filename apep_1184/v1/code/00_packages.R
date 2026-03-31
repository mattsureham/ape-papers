# 00_packages.R — Package installation and loading for apep_1184
# EU Airport Slot Waivers and Competition

required_packages <- c(
  "eurostat",      # Eurostat data access
  "fixest",        # Fixed effects estimation
  "data.table",    # Data manipulation
  "modelsummary",  # Regression tables
  "xtable",        # LaTeX table output
  "jsonlite",      # JSON output for diagnostics
  "stringr"        # String manipulation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(data.table)

cat("All packages loaded successfully.\n")
