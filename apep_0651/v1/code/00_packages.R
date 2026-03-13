# ==============================================================================
# 00_packages.R — Install and load required packages
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2

"data.table",   # fast data operations
  "fixest",       # fast fixed effects + IV (feols, ivreg)
  "modelsummary", # regression tables
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "jsonlite",     # diagnostics.json output
  "kableExtra",   # table formatting
  "lubridate"     # date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
