## 00_packages.R — Load and install required packages
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

required_packages <- c(
  "tidyverse",    # data manipulation + visualization
  "fixest",       # fast fixed effects estimation
  "jsonlite",     # JSON parsing (SEC EDGAR API)
  "httr2",        # HTTP requests (SEC EDGAR API)
  "data.table",   # fast data operations
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust standard errors
  "lmtest"        # coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
