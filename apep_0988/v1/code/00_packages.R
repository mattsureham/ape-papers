# 00_packages.R — Package dependencies for apep_0988
# Poland Sunday Trading Ban and Retail Reallocation

required_packages <- c(
  "tidyverse",    # Data manipulation + visualization
  "fixest",       # Fixed effects estimation
  "httr",         # API calls to GUS BDL
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX table generation
  "sandwich",     # Robust SEs
  "fwildclusterboot",  # Wild cluster bootstrap
  "modelsummary", # Regression tables
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
