# 00_packages.R — Required packages for Alien Land Laws analysis
# apep_0719

required_packages <- c(
  "tidyverse",    # Data manipulation and plotting
  "data.table",   # Fast operations
  "fixest",       # Fixed effects estimation
  "duckdb",       # Azure parquet access
  "jsonlite",     # Diagnostics output
  "xtable",       # LaTeX table generation
  "scales"        # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
