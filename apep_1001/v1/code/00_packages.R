## 00_packages.R — Install and load required packages
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

required_packages <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects Poisson regression
  "sandwich",       # Robust standard errors
  "lmtest",         # Coefficient testing
  "MASS",           # Negative binomial
  "jsonlite",       # Write diagnostics.json
  "lubridate"       # Date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
