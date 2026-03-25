# 00_packages.R — Install and load required packages
# apep_0946: EECC transposition and consumer telecom prices

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "eurostat",     # Eurostat API
  "data.table",   # Fast data manipulation
  "jsonlite",     # JSON I/O
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "WDI"           # World Bank data
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")
