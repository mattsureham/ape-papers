## 00_packages.R — Install and load required packages
## APEP-0745: The Stigma Tax

required_pkgs <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation (feols, sunab)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Fast data operations
  "jsonlite",     # Write diagnostics.json
  "xtable",       # LaTeX table generation
  "sandwich"      # Robust standard errors
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
