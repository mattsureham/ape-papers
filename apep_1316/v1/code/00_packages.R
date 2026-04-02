# 00_packages.R — Load and install required packages
# apep_1316: BVA Judge Leniency IV

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast IV/2SLS with clustered SEs
  "curl",         # Parallel HTTP downloads
  "stringr",      # String parsing
  "jsonlite",     # Write diagnostics.json
  "xtable",       # LaTeX table generation
  "modelsummary", # Regression tables
  "data.table"    # Fast file reading
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
