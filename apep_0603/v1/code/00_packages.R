## 00_packages.R — Install and load required packages
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

required <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # TWFE estimation
  "data.table",   # fast data manipulation
  "httr",         # API calls to GUS BDL
  "jsonlite",     # JSON parsing
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "HonestDiD",    # sensitivity analysis for parallel trends
  "kableExtra",   # table formatting
  "modelsummary", # regression tables
  "xtable"        # LaTeX table output
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
