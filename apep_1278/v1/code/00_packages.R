## 00_packages.R — Install and load required packages
## apep_1278: The Compliance Lottery

required_packages <- c(
  "eurostat",      # Eurostat API access
  "dplyr",         # Data manipulation
  "tidyr",         # Reshaping
  "ggplot2",       # Plotting (for diagnostics only, V1 has no figures)
  "fixest",        # Fast fixed effects estimation
  "did",           # Callaway-Sant'Anna estimator
  "fwildclusterboot", # Wild cluster bootstrap
  "HonestDiD",     # Rambachan-Roth sensitivity
  "jsonlite",      # JSON output for diagnostics
  "stringr",       # String manipulation
  "readr",         # CSV reading
  "xtable",        # LaTeX table generation
  "httr"           # HTTP requests for Eurostat bulk
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
