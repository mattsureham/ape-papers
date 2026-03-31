# 00_packages.R — Required packages for apep_1176
# The Inspection Lottery: State Survey Agency Stringency and Nursing Home Quality

required <- c(
  "tidyverse",    # data manipulation + ggplot2
  "data.table",   # fast data wrangling
  "fixest",       # IV/2SLS with fixed effects
  "httr2",        # HTTP requests for CMS API
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
