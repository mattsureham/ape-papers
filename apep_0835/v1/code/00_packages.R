# 00_packages.R — Install and load required packages
# apep_0835: Greece POS Terminal Mandates

required_pkgs <- c(
  "eurostat",      # Eurostat API access
  "data.table",    # Fast data manipulation
  "fixest",        # Fast fixed-effects estimation (feols, sunab)
  "did",           # Callaway-Sant'Anna estimator
  "ggplot2",       # Plotting (not used in V1 but needed for event study diagnostics)
  "modelsummary",  # Regression tables
  "kableExtra",    # LaTeX table formatting
  "jsonlite",      # Write diagnostics.json
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient testing
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
