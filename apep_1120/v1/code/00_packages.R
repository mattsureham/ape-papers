# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 00_packages.R - Load required packages

required_packages <- c(
  "fixest",      # High-performance fixed effects estimation
  "did",         # Callaway-Sant'Anna staggered DiD
  "dplyr",       # Data manipulation
  "tidyr",       # Reshaping
  "readr",       # CSV reading
  "jsonlite",    # JSON for API calls and diagnostics
  "httr",        # HTTP requests for INSSE API
  "arrow",       # Parquet support
  "xtable",      # LaTeX table generation
  "sandwich",    # Robust SEs
  "lmtest",      # Coefficient tests
  "boot"         # Bootstrap inference
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
