## 00_packages.R — Load required packages for Swiss debt brake analysis
## Paper: apep_1121

required_packages <- c(
  "tidyverse",    # Data wrangling
  "fixest",       # Fixed effects estimation
  "did",          # Callaway-Sant'Anna
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient tests
  "fwildclusterboot",  # Wild cluster bootstrap
  "xtable",       # LaTeX tables
  "kableExtra"    # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
