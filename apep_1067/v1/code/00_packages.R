## 00_packages.R — Load required libraries
## APEP Working Paper apep_1067

required_packages <- c(
  "tidyverse",   # Data manipulation and plotting
  "data.table",  # Fast data reading
  "fixest",      # Fixed effects regressions
  "modelsummary", # Table generation
  "kableExtra",  # Table formatting
  "jsonlite",    # JSON output for diagnostics
  "xtable"       # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
