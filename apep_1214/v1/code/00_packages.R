## 00_packages.R — Load and install required packages
## apep_1214: MCMV Housing and School Quality

required_packages <- c(
  "bigrquery",    # BigQuery access
  "data.table",   # Fast data manipulation
  "fixest",       # Two-way FE, event studies
  "did",          # Callaway-Sant'Anna estimator
  "ggplot2",      # Plotting (for diagnostics only, no figures in V1)
  "modelsummary", # Table generation
  "kableExtra",   # LaTeX table formatting
  "jsonlite",     # Write diagnostics.json
  "httr",         # HTTP requests for MCMV API
  "readr",        # CSV reading
  "stringr",      # String manipulation
  "dplyr",        # Data wrangling
  "tidyr"         # Reshaping
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
