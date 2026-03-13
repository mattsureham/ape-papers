## 00_packages.R — Install and load required packages
## APEP-0636: PBM Spread Pricing Bans and Community Pharmacy Survival

required_packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fast TWFE, Sun-Abraham event studies
  "did",          # Callaway-Sant'Anna staggered DiD
  "HonestDiD",    # Rambachan-Roth sensitivity analysis
  "bacondecomp",  # Goodman-Bacon decomposition
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
