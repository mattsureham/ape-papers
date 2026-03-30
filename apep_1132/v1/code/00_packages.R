# 00_packages.R — Load required packages for apep_1132
# FCA price-walking ban: cross-product DiD on insurance complaints

required_packages <- c(
  "readxl",       # Read FCA Excel files
  "httr",         # HTTP requests for downloads
  "dplyr",        # Data manipulation
  "tidyr",        # Reshape
  "stringr",      # String operations
  "fixest",       # feols for DiD
  "ggplot2",      # Plotting (for diagnostics only)
  "jsonlite",     # Write diagnostics.json
  "xtable",       # LaTeX tables
  "fwildclusterboot", # Wild cluster bootstrap
  "sandwich",     # Robust standard errors
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
