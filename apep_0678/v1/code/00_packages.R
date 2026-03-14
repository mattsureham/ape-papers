# 00_packages.R — Install and load required packages
# APEP-0678: MUP and Alcohol-Specific Mortality

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "readxl",       # Read Excel files
  "httr2",        # HTTP requests
  "jsonlite",     # JSON parsing
  "HonestDiD"     # Rambachan-Roth sensitivity analysis
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing:", pkg, "\n")
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
