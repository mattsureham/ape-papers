## ── 00_packages.R ────────────────────────────────────────────────
## Install and load required packages for apep_0912
## India Rice Export Ban: Price Pass-Through Across 88 Countries
## ──────────────────────────────────────────────────────────────────

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "httr",          # HTTP requests for WFP/COMTRADE APIs
  "jsonlite",      # JSON parsing
  "countrycode",   # Country code conversion
  "readr",         # CSV reading
  "xtable",        # LaTeX table generation
  "sandwich",      # Robust standard errors
  "lmtest"         # Coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
