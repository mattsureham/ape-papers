## 00_packages.R — Install/load required packages for apep_0832
## WIC EBT, vendor exits, and infant health

required_pkgs <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects estimation
  "did",            # Callaway-Sant'Anna staggered DiD
  "ggplot2",        # Plotting (for diagnostics only)
  "httr",           # API calls
  "jsonlite",       # JSON parsing
  "readr",          # CSV reading
  "stringr",        # String manipulation
  "xtable",         # LaTeX table generation
  "sandwich",       # Robust SEs
  "lmtest",         # Coefficient tests
  "HonestDiD",      # Sensitivity analysis for parallel trends
  "modelsummary"    # Regression tables
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
