## 00_packages.R — Install and load required packages
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth

required_packages <- c(
  "tidyverse",     # data wrangling + ggplot2

"fixest",        # two-way fixed effects
  "data.table",    # fast I/O
  "jsonlite",      # JSON parsing (IRS index, ProPublica API)
  "httr",          # HTTP requests
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  "sandwich",      # robust SEs
  "lmtest"         # coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
