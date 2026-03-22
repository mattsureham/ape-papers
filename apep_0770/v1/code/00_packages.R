# 00_packages.R — Load required packages for apep_0770
# French maternity ward closures and populist voting

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # DiD/TWFE with clustered SEs
  "did",           # Callaway-Sant'Anna estimator
  "ggplot2",       # Figures (for internal QA)
  "httr",          # API calls
  "jsonlite",      # JSON parsing
  "readxl",        # Excel files (DREES historical)
  "sf",            # Spatial operations (distance)
  "geosphere",     # Geodesic distance calculations
  "arrow",         # Parquet files (election data)
  "stringr",       # String operations
  "modelsummary",  # Table formatting
  "kableExtra"     # LaTeX table output
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")
