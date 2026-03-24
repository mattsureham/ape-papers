# 00_packages.R — Install and load required packages
# apep_0870: Upload Filter Tax

required_pkgs <- c(
  "data.table", "dplyr", "tidyr", "ggplot2",
  "fixest",        # TWFE and event studies
  "did",           # Callaway & Sant'Anna (2021)
  "eurostat",      # Eurostat data
  "httr2",         # HTTP requests (CELLAR SPARQL)
  "jsonlite",      # JSON parsing
  "kableExtra",    # Table formatting
  "xtable",        # LaTeX tables
  "HonestDiD",     # Rambachan-Roth sensitivity
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

message("All packages loaded successfully.")
