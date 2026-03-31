# 00_packages.R — Install and load required packages for apep_1180
# Korea Mandatory English Disclosure paper

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "rdrobust",      # RDD estimation
  "ggplot2",       # (not used in V1, but loaded for diagnostics)
  "sandwich",      # Robust standard errors
  "lmtest",        # Hypothesis testing
  "jsonlite",      # JSON output
  "broom",         # Tidy model output
  "modelsummary"   # Table output
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
