# 00_packages.R — Load and install required packages
# APEP Paper apep_1086: CAA Attainment Redesignation

required_packages <- c(
  "tidyverse",    # Data manipulation and plotting
  "fixest",       # Fast fixed effects (TWFE, Sun-Abraham)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # Memory-efficient data ops (8GB RAM constraint)
  "readxl",       # Read EPA Green Book XLS
  "httr",         # HTTP requests for APIs
  "jsonlite",     # Parse JSON from Census/QWI API
  "modelsummary", # Regression tables
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest:", as.character(packageVersion("fixest")), "\n")
cat("did:", as.character(packageVersion("did")), "\n")
