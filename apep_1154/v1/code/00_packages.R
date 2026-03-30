## 00_packages.R — Install and load required packages
## apep_1154: EU Transposition Delay and Firm Entry

required_pkgs <- c(
  "tidyverse",    # Data manipulation and visualization
  "fixest",       # Fixed effects estimation (TWFE, Sun-Abraham)
  "did",          # Callaway-Sant'Anna estimator
  "eurostat",     # Eurostat data API
  "eurlex",       # EUR-Lex / CELLAR SPARQL
  "httr",         # HTTP requests for SPARQL fallback
  "jsonlite",     # JSON parsing
  "data.table",   # Memory-efficient operations
  "xtable",       # LaTeX table generation
  "sandwich",     # Robust standard errors
  "lmtest",       # Coefficient testing
  "fwildclusterboot" # Wild cluster bootstrap
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
