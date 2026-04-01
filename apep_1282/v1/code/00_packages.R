# 00_packages.R — Load required libraries
# apep_1282: The Double Squeeze

pkgs <- c(
  "eurostat",     # Eurostat API
  "dplyr",        # Data manipulation
  "tidyr",        # Reshaping
  "readxl",       # INPS XLSX files
  "httr",         # HTTP requests for INPS
  "fixest",       # Fast fixed effects (feols)
  "fwildclusterboot",  # Wild cluster bootstrap
  "modelsummary", # Regression tables
  "xtable",       # LaTeX table output
  "jsonlite",     # Write diagnostics.json
  "stringr"       # String manipulation
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
