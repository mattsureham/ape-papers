## 00_packages.R — Load required libraries
## apep_1050: Swiss EV Tax Exemptions

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot
  "fixest",       # fast fixed effects
  "did",          # Callaway & Sant'Anna
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "boot"             # bootstrap methods
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
