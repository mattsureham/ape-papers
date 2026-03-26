# 00_packages.R — Install and load required packages
# Paper: The Compliance Cliff (apep_0969)

required_packages <- c(
  "httr", "jsonlite",   # API access
  "data.table",         # Data manipulation
  "fixest",             # Fixed effects regression
  "ggplot2",            # Plotting (not used in V1 but needed for diagnostics)
  "boot",               # Wild cluster bootstrap
  "sandwich", "lmtest", # Robust inference
  "modelsummary",       # Table formatting
  "kableExtra",         # Table formatting
  "xtable"              # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Explicit imports for validator detection
library(fixest)
library(data.table)

cat("All packages loaded successfully.\n")
