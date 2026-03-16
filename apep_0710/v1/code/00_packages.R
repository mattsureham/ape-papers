# 00_packages.R — Load and install required packages
# apep_0710: Ukraine ProZorro Procurement Thresholds

required_packages <- c(
  "tidyverse",    # Data manipulation + ggplot2
  "fixest",       # Fast fixed effects
  "rdrobust",     # RD robust estimation
  "rddensity",    # McCrary density test
  "sandwich",     # Robust standard errors
  "lmtest",       # Hypothesis tests
  "jsonlite",     # JSON output for diagnostics
  "xtable",       # LaTeX table generation
  "modelsummary"  # Regression table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
