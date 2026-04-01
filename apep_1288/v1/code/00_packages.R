## 00_packages.R — Load required packages for apep_1288
## Child Labor Law Relaxations and Teen Employment

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "data.table",   # Memory-efficient data operations
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "fwildclusterboot", # Wild cluster bootstrap
  "xtable",       # LaTeX table generation
  "modelsummary"  # Regression tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
