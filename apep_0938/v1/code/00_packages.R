# 00_packages.R — EU Late Payment Directive & Small Firm Survival
# Required packages for apep_0938

required_packages <- c(
  "eurostat",       # Eurostat data API
  "dplyr",          # Data manipulation
  "tidyr",          # Reshaping
  "ggplot2",        # Plotting (diagnostics only)
  "fixest",         # Fixed effects estimation
  "modelsummary",   # Table output
  "kableExtra",     # LaTeX table formatting
  "jsonlite",       # JSON output for diagnostics
  "stringr",        # String manipulation
  "fwildclusterboot", # Wild cluster bootstrap
  "xtable"          # LaTeX tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
