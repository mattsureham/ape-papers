# 00_packages.R — Load required packages
# apep_0637: Patent Examiner Leniency & Defensive Patenting

required_packages <- c(
  "tidyverse",   # Data wrangling
  "fixest",      # Fast fixed effects + IV estimation
  "sandwich",    # Robust SEs
  "lmtest",      # Coefficient testing
  "jsonlite",    # JSON output for diagnostics
  "scales"       # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
