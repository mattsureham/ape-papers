# 00_packages.R — Install and load required packages
# apep_1207: Thailand Rice Pledging Scheme Collapse

required_packages <- c(
  "tidyverse",    # data manipulation
  "fixest",       # fixed effects for DiD specifications
  "WDI",          # World Bank Development Indicators API
  "augsynth",     # augmented synthetic control
  "httr",         # HTTP requests
  "jsonlite",     # JSON parsing
  "kableExtra",   # table formatting
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient testing
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
